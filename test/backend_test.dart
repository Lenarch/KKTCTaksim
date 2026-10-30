import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kktc_taksim/data/firebase/firebase_auth_repository.dart';
import 'package:kktc_taksim/data/firebase/firebase_trip_repository.dart';
import 'package:kktc_taksim/data/firebase/switch_map.dart';
import 'package:kktc_taksim/data/mock/mock_auth_repository.dart';
import 'package:kktc_taksim/data/mock/mock_ride_repository.dart';
import 'package:kktc_taksim/data/mock/mock_shared_ride_repository.dart';
import 'package:kktc_taksim/data/mock/mock_trip_repository.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/data/repositories/trip_repository.dart';
import 'package:kktc_taksim/models/app_user.dart';
import 'package:kktc_taksim/models/fare_estimate.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/ride_request.dart';
import 'package:kktc_taksim/models/ride_session.dart';
import 'package:kktc_taksim/models/route_info.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:kktc_taksim/models/trip.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Bu testler repository "sözleşmesini" anlatır. Firebase uygulamaları yazıldığında aynı
// testler Firebase emülatörüne karşı da çalıştırılacak.

const _phone = '+90 533 123 45 67';

Future<AppUser> _signIn(AuthRepository auth) async {
  await auth.sendCode(_phone);
  return auth.verifyCode('1' * auth.codeLength);
}

RideRequest _request() {
  const pickup = LatLng(35.1856, 33.3823);
  const destination = LatLng(35.3412, 33.3196);
  return const RideRequest(
    pickup: GeoPlace(name: 'Lefkoşa', position: pickup),
    destination: GeoPlace(name: 'Girne', position: destination),
    route: RouteInfo(points: [pickup, destination], distanceMeters: 25000, durationSeconds: 1800),
    taxiType: TaxiType.economy,
    payment: PaymentMethod.cash,
    fare: FareEstimate(low: 990, high: 1210),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthRepository', () {
    test('kod doğrulanınca oturum açılır, yeniden açılışta korunur, çıkışla kapanır', () async {
      final auth = MockAuthRepository();
      await auth.init();
      expect(auth.currentUser, isNull);

      final user = await _signIn(auth);
      await auth.updateName('Ayşe Demir');
      expect(user.phone, _phone);

      final reopened = MockAuthRepository();
      await reopened.init();
      expect(reopened.currentUser?.name, 'Ayşe Demir');

      await reopened.signOut();
      final afterSignOut = MockAuthRepository();
      await afterSignOut.init();
      expect(afterSignOut.currentUser, isNull);
    });

    test('yanlış uzunlukta kod ve geçersiz numara hata verir', () async {
      final auth = MockAuthRepository();
      await expectLater(
        auth.sendCode('123'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.invalidPhone)),
      );
      await auth.sendCode(_phone);
      await expectLater(
        auth.verifyCode('12'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', AuthErrorCode.invalidCode)),
      );
    });

    test('authState önce mevcut durumu, sonra değişiklikleri yayar', () async {
      final auth = MockAuthRepository();
      final states = <AppUser?>[];
      final subscription = auth.authState.listen(states.add);
      await _signIn(auth);
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(states.map((u) => u?.phone), [null, _phone, null]);
    });
  });

  group('TripRepository', () {
    late TripRepository trips;
    setUp(() => trips = MockTripRepository());

    test('eklenen yolculuk izleyenlere hemen ulaşır, iptal edilince taşınır', () async {
      final upcoming = <List<Trip>>[];
      final subscription = trips.watch(TripStatus.upcoming).listen(upcoming.add);
      final id = trips.newId();
      await trips.add(Trip(
        id: id,
        from: 'Lefkoşa',
        to: 'Ercan',
        dateTime: DateTime(2026, 12, 1),
        price: 1100,
        status: TripStatus.upcoming,
      ));
      await trips.cancel(id);
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(upcoming.map((l) => l.length), [0, 1, 0]);
      final cancelled = await trips.watch(TripStatus.cancelled).first;
      expect(cancelled.firstWhere((t) => t.id == id).price, 0);
    });

    test('geçmişte en yeni yolculuk başta', () async {
      await trips.add(Trip(
        id: trips.newId(),
        from: 'A',
        to: 'B',
        dateTime: DateTime(2030),
        price: 100,
        status: TripStatus.completed,
      ));
      final completed = await trips.watch(TripStatus.completed).first;
      expect(completed.first.dateTime, DateTime(2030));
    });
  });

  group('SharedRideRepository', () {
    late MockAuthRepository auth;
    late SharedRideRepository rides;
    setUp(() {
      auth = MockAuthRepository();
      rides = MockSharedRideRepository(auth);
    });

    test('oluşturan ilk üye olur; katılma ve ayrılma üyeliği değiştirir', () async {
      final user = await _signIn(auth);
      await rides.create(SharedRide(
        id: '',
        from: 'Girne',
        to: 'Gazimağusa',
        departure: DateTime.now().add(const Duration(days: 3)),
        capacity: 4,
        memberIds: const [],
        pricePerPerson: 300,
      ));
      var active = await rides.watchActive().first;
      final created = active.firstWhere((r) => r.from == 'Girne' && r.to == 'Gazimağusa');
      expect(created.id, isNotEmpty);
      expect(created.memberIds, [user.id]);

      // Son üye ayrılınca grup silinir.
      await rides.leave(created.id);
      active = await rides.watchActive().first;
      expect(active.any((r) => r.id == created.id), isFalse);

      final other = active.first;
      await rides.join(other.id);
      active = await rides.watchActive().first;
      expect(active.firstWhere((r) => r.id == other.id).hasMember(user.id), isTrue);
    });

    test('dolu gruba katılınamaz', () async {
      await _signIn(auth);
      await rides.create(SharedRide(
        id: '',
        from: 'X',
        to: 'Y',
        departure: DateTime.now().add(const Duration(days: 1)),
        capacity: 1,
        memberIds: const [],
        pricePerPerson: 100,
      ));
      final full = (await rides.watchActive().first).firstWhere((r) => r.from == 'X');

      await auth.sendCode('+90 542 000 00 00');
      await auth.verifyCode('1' * auth.codeLength);
      await expectLater(
        rides.join(full.id),
        throwsA(isA<SharedRideException>().having((e) => e.error, 'error', SharedRideError.full)),
      );
    });

    test('grup sohbeti: üyeler yazar ve okur, üye olmayan yazamaz, son üye ayrılınca silinir', () async {
      final user = await _signIn(auth);
      await auth.updateName('Ayşe');
      await rides.create(SharedRide(
        id: '',
        from: 'Güzelyurt',
        to: 'Lefkoşa',
        departure: DateTime.now().add(const Duration(days: 1)),
        capacity: 4,
        memberIds: const [],
        pricePerPerson: 150,
      ));
      final group = (await rides.watchActive().first).firstWhere((r) => r.from == 'Güzelyurt');
      expect(await rides.watchMessages(group.id).first, isEmpty);
      expect(await rides.watchLatestMessage(group.id).first, isNull);

      await rides.sendMessage(group.id, '   ');
      await rides.sendMessage(group.id, '  Saat 9 uygun mu?  ');
      await rides.sendMessage(group.id, 'x' * 600);
      final messages = await rides.watchMessages(group.id).first;
      expect(messages.map((m) => m.text.length), [16, 500]);
      expect(messages.first.text, 'Saat 9 uygun mu?');
      expect(messages.first.senderId, user.id);
      expect(messages.first.senderName, 'Ayşe');
      expect((await rides.watchLatestMessage(group.id).first)?.text, 'x' * 500);

      // Başka bir kullanıcı üye olmadan yazamaz ve okuyamaz; katılınca okur.
      await auth.sendCode('+90 542 000 00 00');
      await auth.verifyCode('1' * auth.codeLength);
      final notMember = isA<SharedRideException>().having((e) => e.error, 'error', SharedRideError.notMember);
      await expectLater(rides.sendMessage(group.id, 'Merhaba'), throwsA(notMember));
      await expectLater(rides.watchMessages(group.id).first, throwsA(notMember));
      await rides.join(group.id);
      expect(await rides.watchMessages(group.id).first, hasLength(2));
      await rides.leave(group.id);

      // Son üye ayrılınca grup ve sohbeti silinir.
      await _signIn(auth);
      await rides.leave(group.id);
      expect((await rides.watchActive().first).any((r) => r.id == group.id), isFalse);
    });
  });

  group('RideRepository (demo)', () {
    late MockTripRepository trips;
    late MockRideRepository rides;
    setUp(() {
      trips = MockTripRepository();
      rides = MockRideRepository(
        trips: trips,
        // Rota servisi çalışmasın: kuş uçuşu tahmini kullanılır.
        routing: RoutingService(client: MockClient((_) async => http.Response('', 500))),
        searchDelay: const Duration(milliseconds: 10),
        approachDuration: const Duration(milliseconds: 30),
        tripDuration: const Duration(milliseconds: 30),
        tick: const Duration(milliseconds: 5),
      );
    });

    test('arama → sürücü → geldi → yolculuk → varış → tamamlandı; geçmişe yazılır', () async {
      final statuses = <RideStatus>[];
      final done = rides.request(_request()).listen((session) async {
        if (statuses.isEmpty || statuses.last != session.status) statuses.add(session.status);
        if (session.status == RideStatus.driverArrived) await rides.startTripDemo(session.id);
        if (session.status == RideStatus.arrived) await rides.completeDemo(session.id);
      }).asFuture<void>();
      await done.timeout(const Duration(seconds: 5));

      expect(statuses, [
        RideStatus.searching,
        RideStatus.driverAssigned,
        RideStatus.driverArrived,
        RideStatus.inProgress,
        RideStatus.arrived,
        RideStatus.completed,
      ]);
      final completed = await trips.watch(TripStatus.completed).first;
      expect(completed.first.to, 'Girne');
      expect(completed.first.price, 1100);
    });

    test('aramada iptal geçmişe yazılmaz, sürücü atandıktan sonra iptal yazılır', () async {
      final cancelledBefore = (await trips.watch(TripStatus.cancelled).first).length;

      final first = await rides.request(_request()).first;
      await rides.cancel(first.id);
      expect((await trips.watch(TripStatus.cancelled).first).length, cancelledBefore);

      final statuses = <RideStatus>[];
      await rides.request(_request()).listen((session) async {
        statuses.add(session.status);
        if (session.status == RideStatus.driverAssigned) await rides.cancel(session.id);
      }).asFuture<void>().timeout(const Duration(seconds: 5));

      expect(statuses.last, RideStatus.cancelled);
      expect((await trips.watch(TripStatus.cancelled).first).length, cancelledBefore + 1);
    });
  });

  group('FirebaseAuthRepository yardımcıları', () {
    test('telefon numarası uluslararası biçime çevrilir', () {
      expect(normalizePhone('+90 533 123 45 67'), '+905331234567');
      expect(normalizePhone('0533 123 45 67'), '+905331234567');
      expect(normalizePhone('533 123 45 67'), '+905331234567');
      expect(normalizePhone('90 533 123 45 67'), '+905331234567');
      expect(normalizePhone('123'), isNull);
      expect(normalizePhone('0533 12'), isNull);
    });

    test('Firebase hata kodları anlaşılır hatalara çevrilir', () {
      expect(mapAuthError('invalid-verification-code'), AuthErrorCode.invalidCode);
      expect(mapAuthError('session-expired'), AuthErrorCode.invalidCode);
      expect(mapAuthError('too-many-requests'), AuthErrorCode.tooManyRequests);
      expect(mapAuthError('network-request-failed'), AuthErrorCode.network);
      expect(mapAuthError('invalid-phone-number'), AuthErrorCode.invalidPhone);
      expect(mapAuthError('bilinmeyen'), AuthErrorCode.unknown);
    });
  });

  test('switchMap yeni değer gelince önceki iç akışı bırakır', () async {
    final users = StreamController<String>();
    final inner = <String, StreamController<int>>{
      'a': StreamController<int>(),
      'b': StreamController<int>(),
    };
    final received = <int>[];
    final subscription = switchMap(users.stream, (String user) => inner[user]!.stream).listen(received.add);

    users.add('a');
    await Future<void>.delayed(Duration.zero);
    inner['a']!.add(1);
    await Future<void>.delayed(Duration.zero);
    users.add('b');
    await Future<void>.delayed(Duration.zero);
    inner['b']!.add(2);
    await Future<void>.delayed(Duration.zero);

    expect(received, [1, 2]);
    expect(inner['a']!.hasListener, isFalse, reason: 'Eski kullanıcının akışı kapatılmalı');
    await subscription.cancel();
  });

  test('Trip belgeye çevrilirken kimlik ayrı tutulur', () {
    final trip = Trip(
      id: 'abc',
      from: 'Lefkoşa',
      to: 'Girne',
      dateTime: DateTime(2026, 11, 1),
      price: 900,
      status: TripStatus.completed,
    );
    final document = tripToDocument(trip);
    expect(document.containsKey('id'), isFalse);
    expect(Trip.fromJson({...document, 'id': 'abc'}).toJson(), trip.toJson());
  });

  group('JSON', () {
    test('Trip gidiş-dönüş', () {
      final trip = Trip(
        id: 't1',
        from: 'Lefkoşa',
        to: 'Ercan',
        dateTime: DateTime(2026, 10, 29, 14, 30),
        price: 1100,
        status: TripStatus.upcoming,
        taxiType: TaxiType.xl,
        payment: PaymentMethod.card,
      );
      final copy = Trip.fromJson(trip.toJson());
      expect(copy.toJson(), trip.toJson());
      expect(copy.dateTime, trip.dateTime);
      expect(Trip.fromJson({...trip.toJson(), 'taxiType': null, 'payment': null}).payment, isNull);
    });

    test('SharedRide ve AppUser gidiş-dönüş', () {
      final ride = SharedRide(
        id: 'g1',
        from: 'Girne',
        to: 'Lefkoşa',
        departure: DateTime(2026, 11, 2, 10),
        capacity: 8,
        memberIds: const ['a', 'b'],
        pricePerPerson: 200,
      );
      expect(SharedRide.fromJson(ride.toJson()).toJson(), ride.toJson());

      const user = AppUser(id: 'u1', phone: _phone, name: 'Ayşe');
      expect(AppUser.fromJson(user.toJson()).toJson(), user.toJson());
    });
  });
}
