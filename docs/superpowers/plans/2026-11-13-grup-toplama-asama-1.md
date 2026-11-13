# Grup Toplama — Aşama 1 (veri, ücret, toplama noktası) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Paylaşımlı grupta her üye kendi toplama noktasını seçer; kişi başı ücreti uygulama hesaplar ve
Firestore kuralları doğrular. (Şoför tarafı Aşama 2–4'te, ayrı planlarda.)

**Architecture:** Mevcut `sharedRides` belgesi genişler (koordinatlar, `baseMeters`, `detours`,
`extraMeters`, `status`), özel toplama noktası `sharedRides/{id}/pickups/{uid}` altında durur. Ücret tek
bir saf tamsayı fonksiyonudur; aynı hesap `firestore.rules` içinde tekrarlanır. Üyelik değişimleri saf
geçiş fonksiyonlarından geçer; mock ve Firebase depoları aynı fonksiyonları kullanır.

**Tech Stack:** Flutter/Dart, cloud_firestore, MapLibre (`LatLng`), OSRM (`RoutingService`), Firestore
kuralları + `@firebase/rules-unit-testing`.

**Spec:** `docs/superpowers/specs/2026-11-13-grup-toplama-design.md` (bu plan 6.1–6.4, 6.7, 6.8 ve
Aşama 1'i uygular)

## Global Constraints

- Flutter komutları **PowerShell'de `C:\src\kktc`** içinden: `C:\src\flutter\bin\flutter.bat analyze`,
  `... test`, `... gen-l10n`. Kural testleri: `cd firestore-tests; npm test`.
- Her görevin sonunda `flutter analyze` temiz, `flutter test` yeşil.
- Ekrandaki her metin `app_tr.arb` + `app_en.arb`; renk/boşluk `app_tokens`/tema; ekranlar veriye yalnızca
  `Backend.instance` üzerinden erişir; testler `Backend.mock()` ve sahte servis (`MockClient`) kullanır.
- Dal: `feature/grup-toplama-1`. Commit'ler yalnızca bu dalda, yerelde. **Push, `main`'e birleştirme ve
  `firebase deploy` sahibinin açık onayı olmadan yapılmaz.**
- Sabitler (spec'ten): sapma sınırı **10 000 m**, sapma **100 m**'ye yukarı yuvarlanır, tarife
  `Tariff` (açılış 100, km 40, asgari 150), kapasite **5–8 → ×1,8**, kişi başı **10 TL'ye yukarı**.
- Özel konum (`pickups`) hiçbir zaman grup belgesine yazılmaz.
- `rides` koleksiyonuna ve kurallarına dokunulmaz.

## Review Focus

1. Rota servisi yanıt vermezken katılma: tahmini mesafeyle (kuş uçuşu × 1,3) katılma yine başarılı olmalı,
   kurallar reddetmemeli. → Görev 6 testi.
2. Toplama noktası 10 km'den uzak: "izin yok" hatası değil, anlaşılır bir uyarı görünmeli ve katılma
   düğmesi kapalı kalmalı. → Görev 6 testi.
3. Eski biçimli grup (koordinatsız) listede: uygulama çökmemeli, "Katıl" kapalı olmalı, üyesi
   ayrılabilmeli. → Görev 2 ve 8 testleri, Görev 4 kural testi.
4. İki kişi aynı anda katılırsa: ikinci yazım eski ücretle gitmemeli; kurallar tutarsız ücreti reddetmeli,
   depo transaction ile yeniden hesaplamalı. → Görev 4 kural testi.
5. Son üye ayrılınca: grup, sohbet ve toplama kaydı birlikte silinmeli; geride özel konum kalmamalı.
   → Görev 3 ve 4 testleri.

---

## Dosya haritası

| Dosya | Sorumluluk |
|---|---|
| `lib/core/group_fare.dart` (yeni) | Grup ücreti ve sapma yuvarlama: saf, tamsayı |
| `lib/models/pickup.dart` (yeni) | `Pickup` (yer + sapma) |
| `lib/models/shared_ride.dart` | Yeni alanlar, `isLegacy`, JSON |
| `lib/data/repositories/shared_ride_repository.dart` | Arayüz + saf geçişler (`rideAfterJoin` vb.) |
| `lib/data/mock/mock_shared_ride_repository.dart`, `lib/data/mock_data.dart` | Mock uygulama, koordinatlı örnekler |
| `lib/data/firebase/firebase_shared_ride_repository.dart` | Transaction'lar, belge çeviriciler |
| `firestore.rules`, `firestore-tests/rules.test.js` | Kurallar ve testleri |
| `lib/services/pickup_detour.dart` (yeni) | Rota servisinden sapma ve ana güzergah mesafesi |
| `lib/widgets/pickup_chooser.dart` (yeni) | "Buluşma noktasından binerim" / başka yer seçimi |
| `lib/widgets/join_group_sheet.dart` (yeni) | Katılma: nokta seç, yeni ücreti gör, onayla |
| `lib/screens/shared_ride_screen.dart` | Kurma formu, kart, katılma/değiştirme akışı |

---

### Task 1: Grup ücreti (saf fonksiyonlar)

**Files:**
- Create: `lib/core/group_fare.dart`
- Test: `test/logic_test.dart` (yeni `group('Grup ücreti', ...)`)

**Interfaces:**
- Produces:
  - `const int maxPickupDetourMeters = 10000;`
  - `const int largeGroupCapacity = 5;` (bu ve üstü büyük araç tarifesi)
  - `int roundDetour(double meters)` — 100'e yukarı yuvarlar, negatif → 0
  - `int groupTotalFare({required int baseMeters, required int extraMeters, required int capacity})`
  - `int groupPricePerPerson({required int baseMeters, required int extraMeters, required int capacity, required int members})`

- [ ] **Step 1: Başarısız testleri yaz**

```dart
test('toplam: açılış + km, asgari ücret, büyük araç çarpanı', () {
  expect(groupTotalFare(baseMeters: 20000, extraMeters: 0, capacity: 4), 900);
  expect(groupTotalFare(baseMeters: 20000, extraMeters: 2500, capacity: 4), 1000);
  expect(groupTotalFare(baseMeters: 500, extraMeters: 0, capacity: 4), 150);
  expect(groupTotalFare(baseMeters: 20000, extraMeters: 0, capacity: 5), 1620);
  expect(TaxiType.xl.fareMultiplier, 1.8); // kurallardaki 18/10 ile aynı kalmalı
});
test('kişi başı: eşit bölünür, 10 TL\'ye yukarı yuvarlanır', () {
  int p(int n, {int capacity = 4}) =>
      groupPricePerPerson(baseMeters: 20000, extraMeters: 0, capacity: capacity, members: n);
  expect([p(1), p(2), p(3), p(4)], [900, 450, 300, 230]);
  expect(p(5, capacity: 8), 330);
});
test('sapma 100 metreye yukarı yuvarlanır', () {
  expect([roundDetour(0), roundDetour(1), roundDetour(100), roundDetour(2501.2), roundDetour(-5)],
      [0, 100, 100, 2600, 0]);
});
```

- [ ] **Step 2:** `flutter test test/logic_test.dart` → derleme hatasıyla FAIL.
- [ ] **Step 3: Uygula.** Yalnızca tamsayı işlemleri (kurallarla birebir aynı olmalı):

```dart
final metered = Tariff.openingFare + (Tariff.perKm * (baseMeters + extraMeters)) ~/ 1000;
final fare = math.max(metered, Tariff.minimumFare);
final total = capacity >= largeGroupCapacity ? fare * 18 ~/ 10 : fare;
// kişi başı:
((total + members * 10 - 1) ~/ (members * 10)) * 10
```

- [ ] **Step 4:** Testler PASS, `flutter analyze` temiz.
- [ ] **Step 5:** Commit: `Grup ücreti: saf hesap fonksiyonları`.

### Task 2: Model ve saf üyelik geçişleri

**Files:**
- Create: `lib/models/pickup.dart`
- Modify: `lib/models/shared_ride.dart`, `lib/data/repositories/shared_ride_repository.dart`
- Test: `test/logic_test.dart`, `test/backend_test.dart` (JSON gidiş-dönüş)

**Interfaces:**
- Consumes: Task 1 fonksiyonları.
- Produces:
  - `class Pickup { final GeoPlace place; final int detourMeters; const Pickup({required this.place, required this.detourMeters}); }`
  - `enum SharedRideStatus { open, claimed, enRoute, inTrip, completed, cancelled }` (Aşama 1'de yalnızca `open` yazılır)
  - `SharedRide` yeni alanları: `LatLng? fromPoint`, `LatLng? toPoint`, `int baseMeters` (varsayılan 0),
    `Map<String,int> detours` (varsayılan `{}`), `SharedRideStatus status` (varsayılan `open`).
    Getter'lar: `bool get isLegacy => fromPoint == null`, `int get extraMeters` (detours toplamı),
    `GeoPlace? get meetingPlace` (`from` + `fromPoint`), `bool get joinable => !isLegacy && status == SharedRideStatus.open && !isFull`.
    `pricePerPerson` alanı kalır (belgede yazan değer). `copyWith` `detours` ve `pricePerPerson` da alır.
  - JSON: `fromPoint`/`toPoint` `{'lat','lng'}`; `baseMeters`, `detours`, `extraMeters`, `status` (ad).
    `fromJson` eksik alanları varsayılanla okur (eski belgeler).
  - `SharedRideError`'a `closed` eklenir (eski biçim ya da `open` değil).
  - Saf geçişler (eski `membersAfterJoin`/`membersAfterLeave` yerine):
    - `SharedRide rideAfterJoin(SharedRide ride, String userId, int detourMeters)` — zaten üyeyse aynı
      nesne; `!joinable` ise `full` ya da `closed` fırlatır; üye + sapma eklenir, `pricePerPerson` yeniden hesaplanır.
    - `SharedRide? rideAfterLeave(SharedRide ride, String userId)` — son üyeyse `null`; yeni biçimde sapma
      çıkar ve ücret yeniden hesaplanır; eski biçimde yalnızca üye çıkar.
    - `SharedRide rideAfterRepick(SharedRide ride, String userId, int detourMeters)` — üye değilse
      `notMember`, `!open`/eski ise `closed`.
    - `SharedRide newGroup(SharedRide draft, String userId, int detourMeters)` — tek üye, sapma, ücret.

- [ ] **Step 1: Testleri yaz** (`ride()` yardımcı: `fromPoint: LatLng(35.34, 33.32)`, `toPoint: LatLng(35.15, 33.50)`, `baseMeters: 20000`, `capacity: 4`)

```dart
test('katılınca sapma ve ücret güncellenir', () {
  final g = newGroup(ride(), 'a', 0);
  expect((g.memberIds, g.detours, g.pricePerPerson), (['a'], {'a': 0}, 900));
  final j = rideAfterJoin(g, 'b', 2500);
  expect((j.memberIds, j.extraMeters, j.pricePerPerson), (['a', 'b'], 2500, 500));
  expect(identical(rideAfterJoin(j, 'b', 900), j), isTrue);
});
test('ayrılınca sapma düşer; son üye null', () {
  final j = rideAfterJoin(newGroup(ride(), 'a', 0), 'b', 2500);
  final l = rideAfterLeave(j, 'b')!;
  expect((l.memberIds, l.detours, l.pricePerPerson), (['a'], {'a': 0}, 900));
  expect(rideAfterLeave(l, 'a'), isNull);
});
test('nokta değişince yalnızca kendi sapması değişir', () {
  final j = rideAfterJoin(newGroup(ride(), 'a', 0), 'b', 2500);
  final r = rideAfterRepick(j, 'b', 0);
  expect((r.detours, r.pricePerPerson), ({'a': 0, 'b': 0}, 450));
  expect(() => rideAfterRepick(j, 'x', 0), throwsA(isA<SharedRideException>()));
});
test('eski biçimli gruba katılınamaz ama ayrılınabilir', () {
  final legacy = SharedRide.fromJson({'id': 'g', 'from': 'A', 'to': 'B', 'departure': 1, 'capacity': 4,
      'memberIds': ['a', 'b'], 'pricePerPerson': 200});
  expect(legacy.isLegacy, isTrue);
  expect(() => rideAfterJoin(legacy, 'c', 0),
      throwsA(isA<SharedRideException>().having((e) => e.error, 'error', SharedRideError.closed)));
  expect(rideAfterLeave(legacy, 'b')!.pricePerPerson, 200);
});
test('dolu gruba katılma full fırlatır', () { /* capacity: 1, ikinci katılma → SharedRideError.full */ });
```
Ayrıca `backend_test.dart`'taki JSON gidiş-dönüş testi yeni alanlarla genişletilir.

- [ ] **Step 2:** FAIL gör. **Step 3:** Uygula; `membersAfterJoin/Leave` çağrıları yeni fonksiyonlara
  çevrilir (mock ve firebase depo geçici olarak sapma `0` verir; Task 3 ve 5 tamamlar).
- [ ] **Step 4:** Tüm testler PASS, analyze temiz. **Step 5:** Commit: `Grup modeli: koordinat, sapma, saf geçişler`.

### Task 3: Depo arayüzü, mock depo, örnek veriler

**Files:**
- Modify: `lib/data/repositories/shared_ride_repository.dart`, `lib/data/mock/mock_shared_ride_repository.dart`,
  `lib/data/mock_data.dart`, `lib/data/firebase/firebase_shared_ride_repository.dart` (yalnızca derlenecek
  kadar; asıl iş Task 5), `lib/screens/shared_ride_screen.dart` (çağrılar geçici olarak buluşma noktasını verir)
- Test: `test/backend_test.dart`

**Interfaces:**
- Produces (arayüzde değişenler):
  - `Future<void> create(SharedRide draft, Pickup pickup);`
  - `Future<void> join(String rideId, Pickup pickup);`
  - `Future<void> changePickup(String rideId, Pickup pickup);`
  - `Future<Pickup?> myPickup(String rideId);` — üye değilse ya da eski grupta `null`
  - `leave`, `removeMe` imzaları aynı; ikisi de toplama kaydını siler.
- `MockData.sharedRides()` iki örneğe gerçek koordinat ve `baseMeters` verir (Lefkoşa 35.1856,33.3823;
  Ercan 35.1547,33.4961; Girne 35.3417,33.3192), `detours` üye başına 0, ücret `newGroup`/`rideAfterJoin` ile.

- [ ] **Step 1: Testleri yaz** (`backend_test.dart`, `SharedRideRepository` grubu)

```dart
test('oluşturan kendi toplama noktasıyla ilk üye olur', () async {
  await rides.create(draft, Pickup(place: home, detourMeters: 1200));
  final g = (await rides.watchActive().first).firstWhere((r) => r.memberIds.contains(me));
  expect((g.detours[me], g.pricePerPerson), (1200, groupPricePerPerson(baseMeters: g.baseMeters, extraMeters: 1200, capacity: g.capacity, members: 1)));
  expect((await rides.myPickup(g.id))!.place.name, home.name);
});
test('katılma, nokta değiştirme ve ayrılma toplama kaydını yönetir', () async {
  // demo-group-1'e katıl (sapma 500) → myPickup dolu; changePickup(sapma 0) → detours[me]==0;
  // leave → myPickup null, detours'ta me yok
});
test('son üye ayrılınca grup ve toplama kaydı silinir', () async { /* create → leave → listede yok, myPickup null */ });
```
Mevcut grup testleri yeni imzalara uyarlanır.

- [ ] **Step 2:** FAIL. **Step 3:** Uygula (mock: `Map<String, Map<String, Pickup>> _pickups`).
- [ ] **Step 4:** PASS + analyze. **Step 5:** Commit: `Grup deposu: toplama noktasıyla kurma, katılma, değiştirme`.

### Task 4: Firestore kuralları

**Files:**
- Modify: `firestore.rules` (`match /sharedRides/{rideId}` bloğu), `firestore-tests/rules.test.js`

**Interfaces:**
- Produces (belge sözleşmesi; Task 5 buna uyar):
  - Grup belgesi anahtarları (yeni biçim, tam olarak): `from, to, fromPoint, toPoint, departure, capacity,
    memberIds, baseMeters, detours, extraMeters, pricePerPerson, status`.
  - `pickups/{uid}` anahtarları: `place` (`{name,lat,lng}`, ad 1–200), `state` (Aşama 1'de yalnızca `'waiting'`).

Kural içeriği (uygulayıcı yazar; değerler bağlayıcı):
- `straight(a,b)`: `dy=(a.lat-b.lat)*111320.0`, `dx=(a.lng-b.lng)*90950.0`, `math.sqrt(dx*dx+dy*dy)`.
- `price(base, extra, capacity, n)`: Task 1'deki tamsayı hesabın aynısı (100, 40, 150, `capacity >= 5` → `*18/10`).
- **Oluşturma:** yukarıdaki anahtarlar; `status=='open'`; `memberIds==[uid]`; `detours=={uid:d}`,
  `extraMeters==d`; `baseMeters` tamsayı, `>= straight(from,to)*0.9`, `<= straight*4+5000`, `<= 300000`;
  `pricePerPerson==price(...,1)`; mevcut `departure`/`capacity`/ad denetimleri aynen; `geçerliSapma(uid)`.
- `geçerliSapma(uid)`: `d` tamsayı, `0..10000`, `d % 100 == 0`,
  `d + 100 >= straight(getAfter(pickups/uid).data.place, fromPoint) * 0.9`.
- **Katılma:** `status=='open'`, eski biçim değil, `departure` gelecekte, `memberIds` = önceki + `[uid]`,
  boyut ≤ `capacity`; `detours` farkı yalnızca `uid` anahtarı; `extraMeters == önceki + d`;
  `pricePerPerson == price(...)`; `geçerliSapma(uid)`; değişen anahtarlar yalnızca
  `memberIds, detours, extraMeters, pricePerPerson`.
- **Ayrılma (yeni biçim):** üye çıkar, `detours`'tan `uid` çıkar, `extraMeters == önceki − eski d`, ücret
  tutarlı, `!existsAfter(pickups/uid)`, en az bir üye kalır.
- **Ayrılma (eski biçim, `fromPoint` yok):** bugünkü `isLeave` aynen; eski biçime katılma **yok**.
- **Nokta değiştirme:** `status=='open'`, `memberIds` aynı ve `uid` içinde, `detours` farkı yalnızca `uid`,
  `extraMeters == önceki − eski + yeni`, ücret tutarlı, `geçerliSapma(uid)`.
- **Silme:** `memberIds==[uid]` (bugünkü gibi) ve yeni biçimde `!existsAfter(pickups/uid)` (geride özel
  konum kalmasın; test: toplama kaydını silmeden grubu silme reddedilir).
- **`pickups/{uid}`:** okuma yalnızca `request.auth.uid == uid` (şoför okuması Aşama 2'de);
  oluşturma/güncelleme: sahibi, geçerli `place`, `state=='waiting'`, `getAfter(grup).memberIds` içinde ve
  grup `open`; silme: sahibi.

- [ ] **Step 1: Kural testlerini yaz.** `sharedRide()` yardımcısı yeni biçime çevrilir (Girne→Lefkoşa
  noktaları, `baseMeters: 26000`, `detours: {alice: 0}`, `extraMeters: 0`, `pricePerPerson: 1140`,
  `status: 'open'`); `pickup(overrides)` ve `joinBatch(db, user, {detour, place, price})` yardımcıları
  eklenir. Testler (her biri `assertSucceeds`/`assertFails`):
  - kurma: geçerli toplu yazım geçer; toplama kaydı olmadan, yanlış ücretle (1130), `status:'claimed'`,
    `driverId` ile, `baseMeters: 1000` (kuş uçuşundan kısa), sapma 150 (100'ün katı değil), sapma 10100,
    noktası 5 km uzakken sapma 0 ile → reddedilir
  - katılma: doğru toplu yazım geçer (2 kişi, sapma 2500 → `price(26000,2500,4,2)=620`); eski ücretle
    (1140), başkasının sapmasını değiştirerek, toplama kaydı olmadan, dolu grupta, kalkışı geçmişte → reddedilir
  - **eşzamanlılık:** BOB katıldıktan sonra CAROL'ın 2 kişilik ücretle hazırlanmış yazımı reddedilir
  - ayrılma: sapma ve ücret düzeltilip toplama kaydı silinerek geçer; kaydı silmeden ya da ücreti
    düzeltmeden → reddedilir; son üye grubu ve kaydını siler
  - nokta değiştirme: kendi sapması ve ücretle geçer; üye olmayan → reddedilir
  - eski biçim: katılma reddedilir, ayrılma geçer
  - `pickups`: sahibi okur; başka üye ve dışarıdan biri **okuyamaz**; üye olmayan oluşturamaz
- [ ] **Step 2:** `cd firestore-tests; npm test` → yeni testler FAIL.
- [ ] **Step 3:** Kuralları yaz. Mevcut sohbet (`messages`) kuralları değişmez.
- [ ] **Step 4:** `npm test` → tümü PASS (diğer koleksiyonların testleri dahil).
- [ ] **Step 5:** Commit: `Kurallar: grup ücreti doğrulaması ve özel toplama kaydı`. **Yükleme yapılmaz.**

### Task 5: Firebase deposu

**Files:**
- Modify: `lib/data/firebase/firebase_shared_ride_repository.dart`
- Test: `test/backend_test.dart` (çevirici testleri)

**Interfaces:**
- Consumes: Task 2 geçişleri, Task 4 belge sözleşmesi.
- Produces: `Map<String,dynamic> pickupToDocument(Pickup p)` (`{'place': {name,lat,lng}, 'state': 'waiting'}`),
  `Pickup pickupFromDocument(Map<String,dynamic> data, int detourMeters)`; `sharedRideToDocument` yeni
  alanları ve `extraMeters`'ı yazar.

- [ ] **Step 1: Test:** `sharedRideToDocument(newGroup(draft,'a',1200))` anahtar kümesi Task 4'teki listeyle
  birebir aynı ve `id` yok; `pickupToDocument` → `fromDocument` gidiş-dönüş.
- [ ] **Step 2:** FAIL. **Step 3: Uygula:**
  - `create`: `WriteBatch` — grup (`newGroup`) + `pickups/{uid}`.
  - `join`, `changePickup`, `leave`: transaction — grubu oku, saf geçişi uygula, grubu güncelle ve aynı
    transaction'da toplama kaydını yaz/sil. `leave` son üyede önce mesajları (bugünkü gibi), sonra
    transaction'da grup + toplama kaydını siler. Hata kodları transaction dışında fırlatılır (bugünkü desen).
  - `myPickup`: `pickups/{uid}` + grubun `detours[uid]`; yoksa `null`; `permission-denied` → `null`.
- [ ] **Step 4:** PASS + analyze. **Step 5:** Commit: `Firebase grup deposu: toplama kaydı ve ücret`.

### Task 6: Sapma servisi ve toplama noktası seçici

**Files:**
- Create: `lib/services/pickup_detour.dart`, `lib/widgets/pickup_chooser.dart`
- Modify: `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb`
- Test: `test/logic_test.dart`, `test/widget_test.dart`

**Interfaces:**
- Produces:
  - `Future<int> pickupDetourMeters(RoutingService routing, LatLng pickup, LatLng meeting)` —
    `roundDetour(max(rota mesafesi, kuş uçuşu))`; nokta buluşma noktasına 30 m'den yakınsa 0.
  - `Future<int> groupBaseMeters(RoutingService routing, LatLng from, LatLng to)` — `max(rota, kuş uçuşu).round()`.
  - `class PickupChooser extends StatefulWidget` — `({required GeoPlace meeting, required GeocodingService geocoding, required RoutingService routing, Pickup? initial, required ValueChanged<Pickup?> onChanged})`.
    İki seçenek: "Buluşma noktasından binerim" (varsayılan; hemen `Pickup(meeting, 0)` bildirir) ve
    "Başka bir yerden alınmak istiyorum" (mevcut `DestinationSheet` → gerekirse `MapPickScreen(requireName: true)`).
    Sapma hesaplanırken `onChanged(null)`; 10 000 m'yi aşarsa `onChanged(null)` ve hata metni.
- l10n anahtarları (TR): `pickupTitle` "Seni nereden alalım?", `pickupAtMeeting` "Buluşma noktasından
  binerim", `pickupElsewhere` "Başka bir yerden alınmak istiyorum", `pickupTooFar` "Bu nokta buluşma
  noktasına çok uzak (en fazla {km} km).", `pickupPrivacy` "Bu noktayı yalnızca sen ve şoför görür.",
  `pickupExtra` "Ücrete eklenen mesafe: {distance}". EN karşılıkları eklenir.

- [ ] **Step 1: Testler**

```dart
test('sapma: rota mesafesi 100 m\'ye yukarı; servis yoksa kuş uçuşu × 1,3', () async {
  final offline = RoutingService(client: MockClient((_) async => http.Response('hata', 500)));
  final d = await pickupDetourMeters(offline, const LatLng(35.35, 33.32), const LatLng(35.34, 33.32));
  expect(d, roundDetour(distanceMeters(const LatLng(35.35, 33.32), const LatLng(35.34, 33.32)) * 1.3));
  expect(await pickupDetourMeters(offline, const LatLng(35.34, 33.32), const LatLng(35.34, 33.32)), 0);
});
testWidgets('varsayılan seçim buluşma noktasıdır ve sapma 0 bildirir', ...);
testWidgets('başka yer seçilince adı ve eklenen mesafe görünür', ...); // MockClient rota yanıtı 2400 m → Pickup.detourMeters == 2400
testWidgets('10 km\'den uzak nokta reddedilir', ...); // rota 12000 m → 'çok uzak' metni, son onChanged null
```
- [ ] **Step 2:** FAIL. **Step 3:** Uygula; `gen-l10n` çalıştır. **Step 4:** PASS + analyze.
- [ ] **Step 5:** Commit: `Toplama noktası seçici ve sapma hesabı`.

### Task 7: Grup kurma formu

**Files:**
- Modify: `lib/screens/shared_ride_screen.dart` (`CreateSharedRideSheet`, `_showCreateRideSheet`),
  `lib/screens/main_navigation_screen.dart` (servisleri `SharedRideScreen`'e geçir), arb dosyaları
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `PickupChooser`, `groupBaseMeters`, `groupPricePerPerson`, `repository.create(draft, pickup)`.
- Produces: `SharedRideScreen({super.key, this.geocoding, this.routing})`;
  `CreateSharedRideSheet({super.key, this.geocoding, this.routing})` artık
  `({SharedRide draft, Pickup pickup})` ile kapanır. Adımlar: nereden → nereye → tarih/saat/kapasite →
  toplama noktası (4 adım).

Davranış:
- Kişi başı ücret alanı ve `_price` kalkar; kullanılmayan `pricePerPerson*` arb anahtarları silinir.
- 3. adımda bilgi satırı: `groupFareEstimate` "Tek kişiyle {one}, grup dolarsa kişi başı yaklaşık {full}".
  `baseMeters`, varış seçildiğinde hesaplanır; hesaplanana kadar satırda ilerleme göstergesi, "Devam" kapalı.
- 4. adım `PickupChooser`; "Yolculuğu Oluştur" yalnızca `Pickup` varken açık.
- Kapasite 5+ seçilince `largeGroupNote` "5 ve üzeri kişilik gruplar büyük araç tarifesiyle hesaplanır."

- [ ] **Step 1: Testler** (mevcut grup formu testleri 4 adıma uyarlanır; `chooseRecentPlace` kalır)
  - formda ücret alanı yok (`find.text('Kişi başı ücret')` → `findsNothing`), 3. adımda tahmin metni var
  - varsayılan toplama noktasıyla oluşturulan grup: `draft.fromPoint != null`, `draft.baseMeters > 0`, `pickup.detourMeters == 0`
  - kapasite 5 yapılınca büyük araç notu görünür ve tahmin `capacity: 5` ile hesaplanır
- [ ] **Step 2:** FAIL. **Step 3:** Uygula. **Step 4:** PASS + analyze.
- [ ] **Step 5:** Commit: `Grup kurma: ücret otomatik, toplama noktası adımı`.

### Task 8: Katılma, kart ve nokta değiştirme

**Files:**
- Create: `lib/widgets/join_group_sheet.dart`
- Modify: `lib/screens/shared_ride_screen.dart` (`_RideCard`, `_join`), arb dosyaları
- Test: `test/widget_test.dart`

**Interfaces:**
- Consumes: `PickupChooser`, `rideAfterJoin`/`rideAfterRepick` (önizleme ücreti için), `repository.join/changePickup/myPickup`.
- Produces: `JoinGroupSheet({required SharedRide ride, required GeocodingService geocoding, required RoutingService routing, Pickup? current})` → `Pickup?` ile kapanır (`current` doluysa "nokta değiştir" kipidir).

Davranış:
- "Katıl" → `JoinGroupSheet`: `PickupChooser` + `joinPricePreview` "Katılırsan kişi başı {price} olur
  (şu an {current})." + onay düğmesi; onaydan sonra `repository.join`.
- Kart: ücretin önünde "≈" ve altında `priceMayChange` "Kişi sayısına göre değişir"; üye olan kullanıcıya
  "Toplama noktam: {name}" satırı ve "Değiştir" (aynı sayfa, `current` ile → `changePickup`).
- Eski biçimli grup: "Katıl" yerine kapalı düğme `legacyGroup` "Eski sürüm grubu"; "≈" ve toplama satırı yok;
  "Ayrıl" çalışır.
- `SharedRideError.closed` için mesaj: `groupClosed` "Bu gruba artık katılınamıyor."

- [ ] **Step 1: Testler**
  - katılma sayfası yeni ücreti gösterir ve onaydan sonra kullanıcı üye olur, `myPickup` doludur
  - karttan "Değiştir" ile başka nokta seçilince kartta yeni ad ve yeni ücret görünür
  - eski biçimli grup kartında "Eski sürüm grubu" kapalı düğmesi vardır, liste çökmez (mock depoya eski
    biçimli bir grup eklenerek)
- [ ] **Step 2:** FAIL. **Step 3:** Uygula. **Step 4:** PASS + analyze.
- [ ] **Step 5:** Commit: `Gruba katılma: toplama noktası ve ücret önizlemesi`.

### Task 9: Bütün doğrulama, belgeler, yayın kapısı

**Files:**
- Modify: `docs/ILERLEME.md`, `docs/UYARILAR.md`

- [ ] **Step 1:** `flutter analyze` (temiz), `flutter test` (tümü yeşil), `cd firestore-tests; npm test` (tümü yeşil). Çıktıları rapora ekle.
- [ ] **Step 2:** Web'de mock arka uçla elden deneme (grup kur → 2. hesapla katıl → nokta değiştir → ayrıl);
  ekran görüntüsü al.
- [ ] **Step 3:** `ILERLEME.md`: Aşama 1 özeti, tasarım ve plan bağlantıları, sıradaki iş (Aşama 2 planı).
  `UYARILAR.md`: yeni kurallar yüklenince eski APK'ların grup kuramayacağı/katılamayacağı; tarife
  değişince kuralların da değişmesi gerektiği; canlıdaki eski grupların 30 günde biteceği.
- [ ] **Step 4:** Commit: `Belgeler: grup toplama Aşama 1`.
- [ ] **Step 5 (sahibinin onayıyla, ayrı ayrı sorulur):** gerçek Firebase'e karşı emülatörde deneme için
  kuralların yüklenmesi (`firebase deploy --only firestore:rules --project kktctaksim-1ea24`), `main`'e
  birleştirme, push, test APK'sının yenilenmesi. **Kurallar ve yeni APK birlikte çıkmalı.**
