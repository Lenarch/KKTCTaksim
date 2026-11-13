// Firestore güvenlik kurallarının testleri. Gerçek projeye değil, yerel emülatöre karşı çalışır.
// Çalıştırmak: firestore-tests klasöründe `npm test` (Java gerekir).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  arrayRemove,
  arrayUnion,
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  increment,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

const HOUR = 60 * 60 * 1000;

const ALICE = { uid: 'alice', phone: '+905330000001' };
const BOB = { uid: 'bob', phone: '+905330000002' };

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-kktc-taksim',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});

after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

const dbAs = (user) => env.authenticatedContext(user.uid, { phone_number: user.phone }).firestore();
const anonymousDb = () => env.unauthenticatedContext().firestore();

/** Kurallara takılmadan önceden veri koyar (test hazırlığı). */
const seed = (path, data) =>
  env.withSecurityRulesDisabled((context) => setDoc(doc(context.firestore(), path), data));

const trip = (overrides = {}) => ({
  from: 'Lefkoşa',
  to: 'Girne',
  dateTime: 1798000000000,
  price: 1100,
  status: 'upcoming',
  taxiType: 'economy',
  payment: 'cash',
  ...overrides,
});

describe('users/{uid} profil', () => {
  test('kullanıcı kendi profilini yazar ve okur', async () => {
    const db = dbAs(ALICE);
    const ref = doc(db, 'users/alice');
    await assertSucceeds(setDoc(ref, { phone: ALICE.phone, name: 'Alice', updatedAt: serverTimestamp() }));
    await assertSucceeds(getDoc(ref));
  });

  test('başkasının profilini okuyamaz ve yazamaz', async () => {
    await seed('users/bob', { phone: BOB.phone, name: 'Bob' });
    const db = dbAs(ALICE);
    await assertFails(getDoc(doc(db, 'users/bob')));
    await assertFails(setDoc(doc(db, 'users/bob'), { phone: ALICE.phone, updatedAt: serverTimestamp() }));
  });

  test('profildeki telefon giriş yapılan telefonla aynı olmalı', async () => {
    const ref = doc(dbAs(ALICE), 'users/alice');
    await assertFails(setDoc(ref, { phone: BOB.phone, updatedAt: serverTimestamp() }));
  });

  test('profil adı uygulamanın kendisi ya da destek ekibi gibi görünemez', async () => {
    const ref = doc(dbAs(ALICE), 'users/alice');
    for (const name of ['KKTC Taksim Destek', 'kktctaksim', 'Destek Ekibi', 'Admin', 'Yönetici', 'Support']) {
      await assertFails(setDoc(ref, { phone: ALICE.phone, name, updatedAt: serverTimestamp() }));
    }
    await assertSucceeds(setDoc(ref, { phone: ALICE.phone, name: 'Ayşe Demir', updatedAt: serverTimestamp() }));
  });

  test('profilde fazladan alan olamaz', async () => {
    const ref = doc(dbAs(ALICE), 'users/alice');
    await assertFails(setDoc(ref, { phone: ALICE.phone, updatedAt: serverTimestamp(), role: 'admin' }));
  });

  test('giriş yapmamış kişi hiçbir şeye erişemez', async () => {
    await seed('users/alice', { phone: ALICE.phone });
    await assertFails(getDoc(doc(anonymousDb(), 'users/alice')));
  });

  test('profili yalnızca sahibi siler (hesap silme)', async () => {
    await seed('users/alice', { phone: ALICE.phone });
    await assertFails(deleteDoc(doc(dbAs(BOB), 'users/alice')));
    await assertFails(deleteDoc(doc(anonymousDb(), 'users/alice')));
    await assertSucceeds(deleteDoc(doc(dbAs(ALICE), 'users/alice')));
  });
});

describe('users/{uid}/trips yolculuk geçmişi', () => {
  test('kendi yolculuğunu ekler ve listeler', async () => {
    const db = dbAs(ALICE);
    await assertSucceeds(setDoc(doc(db, 'users/alice/trips/t1'), trip()));
    await assertSucceeds(getDocs(collection(db, 'users/alice/trips')));
  });

  test('başkasının yolculuklarını göremez ve onlara ekleyemez', async () => {
    await seed('users/bob/trips/t1', trip());
    const db = dbAs(ALICE);
    await assertFails(getDocs(collection(db, 'users/bob/trips')));
    await assertFails(setDoc(doc(db, 'users/bob/trips/t2'), trip()));
  });

  test('geçersiz yolculuk kaydedilemez', async () => {
    const db = dbAs(ALICE);
    await assertFails(setDoc(doc(db, 'users/alice/trips/t1'), trip({ status: 'paid' })));
    await assertFails(setDoc(doc(db, 'users/alice/trips/t2'), trip({ price: -5 })));
    await assertFails(setDoc(doc(db, 'users/alice/trips/t3'), trip({ payment: 'crypto' })));
    await assertFails(setDoc(doc(db, 'users/alice/trips/t4'), trip({ driverId: 'x' })));
    await assertFails(setDoc(doc(db, 'users/alice/trips/t5'), trip({ to: '' })));
  });

  test('planlanmış yolculuk iptal edilebilir (ücret sıfırlanır)', async () => {
    await seed('users/alice/trips/t1', trip());
    const ref = doc(dbAs(ALICE), 'users/alice/trips/t1');
    await assertSucceeds(updateDoc(ref, { status: 'cancelled', price: 0 }));
  });

  test('iptal ederken ücret sıfırlanmadan ya da başka alan değiştirilerek güncellenemez', async () => {
    await seed('users/alice/trips/t1', trip());
    const ref = doc(dbAs(ALICE), 'users/alice/trips/t1');
    await assertFails(updateDoc(ref, { status: 'cancelled', price: 500 }));
    await assertFails(updateDoc(ref, { status: 'cancelled', price: 0, to: 'Gazimağusa' }));
  });

  test('tamamlanmış yolculuk değiştirilemez; silmeyi yalnızca sahibi yapar (hesap silme)', async () => {
    await seed('users/alice/trips/t1', trip({ status: 'completed' }));
    const ref = doc(dbAs(ALICE), 'users/alice/trips/t1');
    await assertFails(updateDoc(ref, { price: 1 }));
    await assertFails(updateDoc(ref, { status: 'cancelled', price: 0 }));
    await assertFails(deleteDoc(doc(dbAs(BOB), 'users/alice/trips/t1')));
    await assertSucceeds(deleteDoc(ref));
  });
});

const CAROL = { uid: 'carol', phone: '+905330000003' };
const DAVE = { uid: 'dave', phone: '+905330000004' };
const FUTURE = Date.now() + 24 * 60 * 60 * 1000;

// Girne -> Lefkoşa; kuş uçuşu ~17,7 km (kurallardaki straight()).
const GIRNE = { lat: 35.3364, lng: 33.3199 };
const LEFKOSA = { lat: 35.1856, lng: 33.3823 };
// Buluşma noktasının ~2,2 km kuzeyi (2500 m sapma için geçerli) ve ~5 km kuzeyi.
const NEAR = { name: 'Karaoğlanoğlu', lat: GIRNE.lat + 0.02, lng: GIRNE.lng };
const FAR = { name: 'Alsancak', lat: GIRNE.lat + 0.045, lng: GIRNE.lng };
const MEETING = { name: 'Girne Limanı', ...GIRNE };

/** lib/core/group_fare.dart groupPricePerPerson ile aynı tamsayı hesap. */
const fare = (base, extra, capacity, n) => {
  const metered = 100 + Math.floor((40 * (base + extra)) / 1000);
  const f = Math.max(metered, 150);
  const total = capacity >= 5 ? Math.floor((f * 18) / 10) : f;
  return Math.floor((total + n * 10 - 1) / (n * 10)) * 10;
};

/** Yeni biçimli grup belgesi (SharedRide.toJson() kimliksiz). */
const sharedRide = (overrides = {}) => ({
  from: 'Girne Limanı',
  to: 'Lefkoşa',
  fromPoint: GIRNE,
  toPoint: LEFKOSA,
  departure: FUTURE,
  capacity: 4,
  memberIds: ['alice'],
  baseMeters: 26000,
  detours: { alice: 0 },
  extraMeters: 0,
  pricePerPerson: 1140,
  status: 'open',
  ...overrides,
});

/** ALICE (sapma 0) ve BOB (sapma 2500) üyeli grup. */
const twoMemberRide = (overrides = {}) => sharedRide({
  memberIds: ['alice', 'bob'],
  detours: { alice: 0, bob: 2500 },
  extraMeters: 2500,
  pricePerPerson: 620,
  ...overrides,
});

/** Koordinatsız eski biçimli grup (yalnızca ayrılınabilir). */
const legacyRide = (overrides = {}) => ({
  from: 'Girne',
  to: 'Gazimağusa',
  departure: FUTURE,
  capacity: 4,
  memberIds: ['alice'],
  pricePerPerson: 300,
  ...overrides,
});

/** Üyenin özel toplama kaydı. */
const pickup = (overrides = {}) => ({ place: MEETING, state: 'waiting', ...overrides });

const pickupPath = (group, uid) => `sharedRides/${group}/pickups/${uid}`;

/** Grubu ve kurucunun toplama kaydını tek yazımda oluşturur. place: null -> kayıt yazılmaz. */
const createBatch = (db, user, { id = 'g1', ride = {}, place = MEETING } = {}) => {
  const batch = writeBatch(db);
  batch.set(doc(db, `sharedRides/${id}`), sharedRide({ memberIds: [user.uid], detours: { [user.uid]: 0 }, ...ride }));
  if (place) batch.set(doc(db, pickupPath(id, user.uid)), pickup({ place }));
  return batch.commit();
};

/**
 * Katılma: toplama kaydı + grup güncellemesi tek yazımda. Grup alanları sunucuda hesaplanır
 * (arrayUnion/increment), böylece istemcinin bildiği tek değer ücrettir. update: fazladan alanlar.
 */
const joinBatch = (db, user, { detour = 2500, place = NEAR, price = 620, group = 'g1', update = {} } = {}) => {
  const batch = writeBatch(db);
  if (place) batch.set(doc(db, pickupPath(group, user.uid)), pickup({ place }));
  batch.update(doc(db, `sharedRides/${group}`), {
    memberIds: arrayUnion(user.uid),
    [`detours.${user.uid}`]: detour,
    extraMeters: increment(detour),
    pricePerPerson: price,
    ...update,
  });
  return batch.commit();
};

/** Ayrılma: üye, sapması ve toplama kaydı birlikte kalkar; ücret yeniden hesaplanır. */
const leaveBatch = (db, user, { oldDetour, price, group = 'g1', deletePickup = true } = {}) => {
  const batch = writeBatch(db);
  batch.update(doc(db, `sharedRides/${group}`), {
    memberIds: arrayRemove(user.uid),
    [`detours.${user.uid}`]: deleteField(),
    extraMeters: increment(-oldDetour),
    pricePerPerson: price,
  });
  if (deletePickup) batch.delete(doc(db, pickupPath(group, user.uid)));
  return batch.commit();
};

/** Toplama noktası değiştirme: kayıt ve grubun sapma/ücret alanları birlikte. */
const moveBatch = (db, user, { place, oldDetour, detour, price, group = 'g1', target = user.uid } = {}) => {
  const batch = writeBatch(db);
  batch.set(doc(db, pickupPath(group, target)), pickup({ place }));
  batch.update(doc(db, `sharedRides/${group}`), {
    [`detours.${target}`]: detour,
    extraMeters: increment(detour - oldDetour),
    pricePerPerson: price,
  });
  return batch.commit();
};

describe('sharedRides paylaşımlı gruplar', () => {
  test('giriş yapan herkes grupları okur; giriş yapmayan okuyamaz', async () => {
    await seed('sharedRides/g1', sharedRide());
    await assertSucceeds(getDocs(collection(dbAs(BOB), 'sharedRides')));
    await assertFails(getDoc(doc(anonymousDb(), 'sharedRides/g1')));
  });

  test('kurma: grup ve toplama kaydı tek yazımda; ücret ve sapma doğrulanır', async () => {
    const db = dbAs(ALICE);
    await assertFails(createBatch(db, ALICE, { id: 'a', place: null }));
    await assertFails(createBatch(db, ALICE, { id: 'b', ride: { pricePerPerson: 1130 } }));
    await assertFails(createBatch(db, ALICE, { id: 'c', ride: { status: 'claimed' } }));
    await assertFails(createBatch(db, ALICE, { id: 'd', ride: { driverId: 'x' } }));
    await assertFails(createBatch(db, ALICE, { id: 'e', ride: { baseMeters: 1000, pricePerPerson: fare(1000, 0, 4, 1) } }));
    await assertFails(createBatch(db, ALICE, {
      id: 'f', ride: { detours: { alice: 150 }, extraMeters: 150, pricePerPerson: fare(26000, 150, 4, 1) },
    }));
    await assertFails(createBatch(db, ALICE, {
      id: 'g', place: FAR, ride: { detours: { alice: 10100 }, extraMeters: 10100, pricePerPerson: fare(26000, 10100, 4, 1) },
    }));
    // Noktası 5 km uzakken sapma 0 bildirilemez.
    await assertFails(createBatch(db, ALICE, { id: 'h', place: FAR }));
    await assertFails(createBatch(db, ALICE, { id: 'i', ride: { extraMeters: 100 } }));
    await assertFails(createBatch(db, ALICE, { id: 'j', ride: { baseMeters: 400000, pricePerPerson: fare(400000, 0, 4, 1) } }));
    await assertSucceeds(createBatch(db, ALICE, { id: 'ok' }));
    // Uzak noktada yeterli sapmayla da kurulur.
    await assertSucceeds(createBatch(db, ALICE, {
      id: 'ok2', place: FAR, ride: { detours: { alice: 5000 }, extraMeters: 5000, pricePerPerson: fare(26000, 5000, 4, 1) },
    }));
  });

  test('oluşturan tek ve ilk üye olur', async () => {
    const db = dbAs(ALICE);
    await assertFails(createBatch(db, ALICE, { id: 'g2', ride: { memberIds: ['bob'] } }));
    await assertFails(createBatch(db, ALICE, { id: 'g3', ride: { memberIds: ['alice', 'bob'] } }));
    await assertFails(createBatch(db, ALICE, { id: 'g4', ride: { memberIds: [] } }));
    await assertFails(createBatch(db, ALICE, { id: 'g5', ride: { detours: { alice: 0, bob: 0 } } }));
    await assertSucceeds(createBatch(db, ALICE, { id: 'g1' }));
  });

  test('geçersiz grup oluşturulamaz', async () => {
    const db = dbAs(ALICE);
    const create = (id, ride) => createBatch(db, ALICE, { id, ride });
    await assertFails(create('g1', { departure: Date.now() - 60000 }));
    await assertFails(create('g2', { capacity: 0 }));
    await assertFails(create('g3', { capacity: 9, pricePerPerson: fare(26000, 0, 9, 1) }));
    await assertFails(create('g4', { pricePerPerson: 0 }));
    await assertFails(create('g5', { from: '' }));
    await assertFails(create('g8', { departure: Date.now() + 100 * 365 * 24 * HOUR }));
    await assertFails(create('g9', { departure: Date.now() + 32 * 24 * HOUR }));
    await assertFails(create('g11', { fromPoint: { lat: 200, lng: 33 } }));
    await assertSucceeds(create('g10', { departure: Date.now() + 30 * 24 * HOUR }));
    // Büyük araçta ×1,8 tarife uygulanır.
    await assertFails(create('g12', { capacity: 6 }));
    await assertSucceeds(create('g13', { capacity: 6, pricePerPerson: fare(26000, 0, 6, 1) }));
    const { to, ...missingTo } = sharedRide();
    await assertFails(setDoc(doc(db, 'sharedRides/g7'), missingTo));
    // Eski (noktasız) biçimde yeni grup kurulamaz.
    await assertFails(setDoc(doc(db, 'sharedRides/g6'), legacyRide()));
  });

  test('katılma: doğru ücret ve kendi sapmasıyla geçer', async () => {
    await seed('sharedRides/g1', sharedRide());
    await assertSucceeds(joinBatch(dbAs(BOB), BOB, { detour: 2500, place: NEAR, price: 620 }));
  });

  test('katılma: eski ücretle, başkasının sapmasıyla, kayıtsız, dolu ya da geçmiş gruba reddedilir', async () => {
    await seed('sharedRides/g1', sharedRide());
    const db = dbAs(BOB);
    await assertFails(joinBatch(db, BOB, { price: 1140 }));
    // Başkasının sapması değişemez (toplam ve ücret kendi sapmasıyla tutarlı olsa bile).
    await assertFails(joinBatch(db, BOB, { update: { 'detours.alice': 500 } }));
    await assertFails(joinBatch(db, BOB, { update: { 'detours.alice': 500, extraMeters: increment(3000), pricePerPerson: fare(26000, 3000, 4, 2) } }));
    await assertFails(joinBatch(db, BOB, { place: null }));
    await assertFails(joinBatch(db, BOB, { detour: 150, price: fare(26000, 150, 4, 2) }));
    // Sapma bildirilenden uzak nokta.
    await assertFails(joinBatch(db, BOB, { place: FAR }));
    // extraMeters sapmayla tutarsız.
    await assertFails(joinBatch(db, BOB, { update: { extraMeters: increment(0) }, price: fare(26000, 0, 4, 2) }));
    await assertFails(joinBatch(db, BOB, { update: { status: 'claimed' } }));
    await assertFails(joinBatch(db, BOB, { update: { baseMeters: 1000 } }));

    await seed('sharedRides/full', sharedRide({
      capacity: 2, memberIds: ['alice', 'carol'], detours: { alice: 0, carol: 0 }, pricePerPerson: 570,
    }));
    await assertFails(joinBatch(db, BOB, { group: 'full', price: fare(26000, 2500, 2, 3) }));
    await seed('sharedRides/past', sharedRide({ departure: Date.now() - 60000 }));
    await assertFails(joinBatch(db, BOB, { group: 'past' }));
    await seed('sharedRides/closed', sharedRide({ status: 'claimed' }));
    await assertFails(joinBatch(db, BOB, { group: 'closed' }));
  });

  test('kullanıcı yalnızca kendini ekleyerek katılır', async () => {
    await seed('sharedRides/g1', sharedRide());
    const db = dbAs(BOB);
    const join = (memberIds) => {
      const batch = writeBatch(db);
      batch.set(doc(db, pickupPath('g1', 'bob')), pickup({ place: NEAR }));
      batch.update(doc(db, 'sharedRides/g1'), {
        memberIds, 'detours.bob': 2500, extraMeters: 2500, pricePerPerson: fare(26000, 2500, 4, memberIds.length),
      });
      return batch.commit();
    };
    await assertFails(join(['alice', 'carol']));
    await assertFails(join(['bob', 'alice']));
    await assertFails(join(['alice', 'bob', 'bob']));
    await assertSucceeds(join(['alice', 'bob']));
    // Zaten üye olan yeniden katılamaz.
    await assertFails(joinBatch(db, BOB, { detour: 0, price: fare(26000, 2500, 4, 3) }));
  });

  test('eşzamanlılık: BOB katıldıktan sonra CAROL\'ın 2 kişilik ücretli yazımı reddedilir', async () => {
    await seed('sharedRides/g1', sharedRide());
    await assertSucceeds(joinBatch(dbAs(BOB), BOB, { detour: 2500, price: 620 }));
    const carolDb = dbAs(CAROL);
    await assertFails(joinBatch(carolDb, CAROL, { detour: 0, place: MEETING, price: fare(26000, 0, 4, 2) }));
    await assertSucceeds(joinBatch(carolDb, CAROL, { detour: 0, place: MEETING, price: fare(26000, 2500, 4, 3) }));
  });

  test('ayrılma: sapma ve ücret düzeltilip toplama kaydı silinerek geçer', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await seed(pickupPath('g1', 'alice'), pickup());
    await seed(pickupPath('g1', 'bob'), pickup({ place: NEAR }));
    const db = dbAs(BOB);
    await assertFails(leaveBatch(db, BOB, { oldDetour: 2500, price: 1140, deletePickup: false }));
    await assertFails(leaveBatch(db, BOB, { oldDetour: 2500, price: 620 }));
    await assertFails(leaveBatch(db, BOB, { oldDetour: 0, price: fare(26000, 2500, 4, 1) }));
    await assertSucceeds(leaveBatch(db, BOB, { oldDetour: 2500, price: 1140 }));
  });

  test('kullanıcı yalnızca kendini çıkararak ayrılır; son üye listeyi boşaltamaz', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await seed(pickupPath('g1', 'alice'), pickup());
    // BOB, ALICE'i çıkaramaz.
    const db = dbAs(BOB);
    const batch = writeBatch(db);
    batch.update(doc(db, 'sharedRides/g1'), {
      memberIds: ['bob'], 'detours.alice': deleteField(), pricePerPerson: fare(26000, 2500, 4, 1),
    });
    await assertFails(batch.commit());
    // Son üye listeyi boşaltamaz; grubu silmesi gerekir.
    await seed('sharedRides/g2', sharedRide());
    await assertFails(leaveBatch(dbAs(ALICE), ALICE, { group: 'g2', oldDetour: 0, price: 1140 }));
  });

  test('son üye grubu ve kaydını siler; kaydı bırakarak silemez; başkası silemez', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await assertFails(deleteDoc(doc(dbAs(ALICE), 'sharedRides/g1')));
    await assertFails(deleteDoc(doc(dbAs(CAROL), 'sharedRides/g1')));
    await seed('sharedRides/g2', sharedRide());
    await seed(pickupPath('g2', 'alice'), pickup());
    await assertFails(deleteDoc(doc(dbAs(BOB), 'sharedRides/g2')));
    await assertFails(deleteDoc(doc(dbAs(ALICE), 'sharedRides/g2')));
    const db = dbAs(ALICE);
    const batch = writeBatch(db);
    batch.delete(doc(db, pickupPath('g2', 'alice')));
    batch.delete(doc(db, 'sharedRides/g2'));
    await assertSucceeds(batch.commit());
  });

  test('nokta değiştirme: kendi sapması ve ücretiyle geçer; başkasınınki ve üye olmayan reddedilir', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await seed(pickupPath('g1', 'alice'), pickup());
    await seed(pickupPath('g1', 'bob'), pickup({ place: NEAR }));
    const alice = dbAs(ALICE);
    // Ücret düzeltilmeden ya da yetersiz sapmayla olmaz.
    await assertFails(moveBatch(alice, ALICE, { place: NEAR, oldDetour: 0, detour: 2500, price: 620 }));
    await assertFails(moveBatch(alice, ALICE, { place: FAR, oldDetour: 0, detour: 2500, price: fare(26000, 5000, 4, 2) }));
    // Başkasının noktası/sapması değiştirilemez.
    await assertFails(updateDoc(doc(dbAs(BOB), 'sharedRides/g1'), { 'detours.alice': 100 }));
    await assertFails(moveBatch(alice, ALICE, { target: 'bob', place: MEETING, oldDetour: 2500, detour: 0, price: fare(26000, 0, 4, 2) }));
    await assertFails(moveBatch(dbAs(CAROL), CAROL, { place: NEAR, oldDetour: 0, detour: 2500, price: fare(26000, 5000, 4, 2) }));
    await assertSucceeds(moveBatch(alice, ALICE, { place: NEAR, oldDetour: 0, detour: 2500, price: fare(26000, 5000, 4, 2) }));
  });

  test('toplama kaydı tek başına sapmanın izin verdiğinden uzağa taşınamaz', async () => {
    await seed('sharedRides/g1', sharedRide());
    await seed(pickupPath('g1', 'alice'), pickup());
    const ref = doc(dbAs(ALICE), pickupPath('g1', 'alice'));
    await assertFails(setDoc(ref, pickup({ place: FAR })));
    await assertSucceeds(setDoc(ref, pickup({ place: { ...MEETING, name: 'Girne Limanı, kapı' } })));
  });

  // JS SDK -0'ı ondalık (double) gönderir; kurallar 0.0 == 0 sayar. Ondalık extraMeters ile price()
  // kesirli hesaplanır (ör. 1149, 579,5) ve formülden farklı ücret geçebilirdi.
  test('tamsayı: ondalık extraMeters ile grup kurulamaz', async () => {
    const db = dbAs(ALICE);
    await assertFails(createBatch(db, ALICE, { id: 'f1', ride: { extraMeters: -0, pricePerPerson: 1149 } }));
    await assertFails(createBatch(db, ALICE, { id: 'f2', ride: { extraMeters: -0 } }));
    await assertSucceeds(createBatch(db, ALICE, { id: 'f3' }));
  });

  test('tamsayı: ondalık extraMeters ile katılınamaz', async () => {
    await seed('sharedRides/g1', sharedRide());
    const carol = dbAs(CAROL);
    const zeroJoin = { detour: 0, place: MEETING, price: fare(26000, 0, 4, 2) };
    await assertFails(joinBatch(carol, CAROL, { ...zeroJoin, price: 579.5, update: { extraMeters: -0 } }));
    await assertFails(joinBatch(carol, CAROL, { ...zeroJoin, update: { extraMeters: -0 } }));
    await assertSucceeds(joinBatch(carol, CAROL, zeroJoin));
  });

  test("tamsayı: diff() 0 ile -0.0'ı ayırt etmez; ücrete giren baseMeters ondalığa çevrilemez", async () => {
    // Buluşma = varış olan grupta baseMeters 0 olabilir.
    await seed('sharedRides/g0', sharedRide({ toPoint: GIRNE, baseMeters: 0, pricePerPerson: 150 }));
    const carol = dbAs(CAROL);
    const sameJoin = { group: 'g0', detour: 0, place: MEETING, price: fare(0, 0, 4, 2) };
    await assertFails(joinBatch(carol, CAROL, { ...sameJoin, update: { baseMeters: -0 } }));
    await assertSucceeds(joinBatch(carol, CAROL, sameJoin));
  });

  const zeroDetourRide = () => twoMemberRide({ detours: { alice: 0, bob: 0 }, extraMeters: 0, pricePerPerson: 570 });

  test('tamsayı: ondalık extraMeters ile nokta değiştirilemez', async () => {
    await seed('sharedRides/g2', zeroDetourRide());
    await seed(pickupPath('g2', 'alice'), pickup());
    const alice = dbAs(ALICE);
    const move = (extraMeters, pricePerPerson = 570) => {
      const batch = writeBatch(alice);
      batch.set(doc(alice, pickupPath('g2', 'alice')), pickup({ place: { ...MEETING, name: 'İskele' } }));
      batch.update(doc(alice, 'sharedRides/g2'), { 'detours.alice': 0, extraMeters, pricePerPerson });
      return batch.commit();
    };
    await assertFails(move(-0, 579.5));
    await assertFails(move(-0));
    await assertSucceeds(move(0));
  });

  test('tamsayı: ondalık extraMeters ile ayrılınamaz', async () => {
    await seed('sharedRides/g2', zeroDetourRide());
    await seed(pickupPath('g2', 'bob'), pickup());
    const bob = dbAs(BOB);
    const leave = (extraMeters, pricePerPerson = 1140) => {
      const batch = writeBatch(bob);
      batch.update(doc(bob, 'sharedRides/g2'), {
        memberIds: ['alice'], 'detours.bob': deleteField(), extraMeters, pricePerPerson,
      });
      batch.delete(doc(bob, pickupPath('g2', 'bob')));
      return batch.commit();
    };
    await assertFails(leave(-0, 1149));
    await assertFails(leave(-0));
    await assertSucceeds(leave(0));
  });

  test('eski biçimli gruba katılınamaz; ayrılınır', async () => {
    await seed('sharedRides/old', legacyRide({ memberIds: ['alice', 'bob'] }));
    await assertFails(joinBatch(dbAs(CAROL), CAROL, { group: 'old', price: 300 }));
    await assertFails(updateDoc(doc(dbAs(CAROL), 'sharedRides/old'), { memberIds: ['alice', 'bob', 'carol'] }));
    // Eski biçimde de yalnızca kendini çıkarır ve başka alan değiştirmez.
    await assertFails(updateDoc(doc(dbAs(BOB), 'sharedRides/old'), { memberIds: ['bob'] }));
    await assertFails(updateDoc(doc(dbAs(BOB), 'sharedRides/old'), { memberIds: ['alice'], pricePerPerson: 1 }));
    await assertSucceeds(updateDoc(doc(dbAs(BOB), 'sharedRides/old'), { memberIds: ['alice'] }));
    await assertFails(updateDoc(doc(dbAs(ALICE), 'sharedRides/old'), { memberIds: [] }));
    await assertSucceeds(deleteDoc(doc(dbAs(ALICE), 'sharedRides/old')));
  });
});

describe('sharedRides/{id}/pickups özel toplama kaydı', () => {
  test('sahibi okur; başka üye ve dışarıdan biri okuyamaz', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await seed(pickupPath('g1', 'alice'), pickup());
    await assertSucceeds(getDoc(doc(dbAs(ALICE), pickupPath('g1', 'alice'))));
    await assertFails(getDoc(doc(dbAs(BOB), pickupPath('g1', 'alice'))));
    await assertFails(getDoc(doc(dbAs(CAROL), pickupPath('g1', 'alice'))));
    await assertFails(getDoc(doc(anonymousDb(), pickupPath('g1', 'alice'))));
    await assertFails(getDocs(collection(dbAs(BOB), 'sharedRides/g1/pickups')));
  });

  test('üye olmayan oluşturamaz; başkası adına ve geçersiz kayıt yazılamaz', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await assertFails(setDoc(doc(dbAs(CAROL), pickupPath('g1', 'carol')), pickup()));
    await assertFails(setDoc(doc(dbAs(BOB), pickupPath('g1', 'alice')), pickup()));
    const ref = doc(dbAs(BOB), pickupPath('g1', 'bob'));
    await assertFails(setDoc(ref, pickup({ place: NEAR, state: 'picked' })));
    await assertFails(setDoc(ref, pickup({ place: { ...NEAR, name: '' } })));
    await assertFails(setDoc(ref, pickup({ place: { ...NEAR, name: 'x'.repeat(201) } })));
    await assertFails(setDoc(ref, pickup({ place: { ...NEAR, lat: 200 } })));
    await assertFails(setDoc(ref, pickup({ place: NEAR, phone: BOB.phone })));
    await assertSucceeds(setDoc(ref, pickup({ place: NEAR })));
  });

  test('açık olmayan grupta kayıt yazılamaz; sahibi siler, başkası silemez', async () => {
    await seed('sharedRides/g1', twoMemberRide({ status: 'claimed' }));
    await assertFails(setDoc(doc(dbAs(BOB), pickupPath('g1', 'bob')), pickup({ place: NEAR })));
    await seed(pickupPath('g1', 'bob'), pickup({ place: NEAR }));
    await assertFails(deleteDoc(doc(dbAs(ALICE), pickupPath('g1', 'bob'))));
    await assertSucceeds(deleteDoc(doc(dbAs(BOB), pickupPath('g1', 'bob'))));
  });
});

const message = (overrides = {}) => ({
  senderId: 'alice',
  senderName: 'Alice',
  text: 'Merhaba, saat 9 uygun mu?',
  sentAt: serverTimestamp(),
  ...overrides,
});

describe('sharedRides/{id}/messages grup sohbeti', () => {
  beforeEach(() => seed('users/alice', { phone: ALICE.phone, name: 'Alice' }));

  test('gönderen adı profildeki addan başka olamaz (başkası gibi görünme)', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    const ref = (id) => doc(dbAs(ALICE), `sharedRides/g1/messages/${id}`);
    await assertFails(setDoc(ref('m1'), message({ senderName: 'KKTC Taksim Destek' })));
    await assertFails(setDoc(ref('m2'), message({ senderName: null })));
    await assertSucceeds(setDoc(ref('m3'), message()));
    // Profili ya da adı olmayan kullanıcı adsız yazar.
    await seed('users/bob', { phone: BOB.phone, name: null });
    await assertFails(setDoc(doc(dbAs(BOB), 'sharedRides/g1/messages/m4'), message({ senderId: 'bob', senderName: 'Bob' })));
    await assertSucceeds(setDoc(doc(dbAs(BOB), 'sharedRides/g1/messages/m5'), message({ senderId: 'bob', senderName: null })));
  });

  test('üye mesaj yazar ve okur', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await assertSucceeds(setDoc(doc(dbAs(ALICE), 'sharedRides/g1/messages/m1'), message()));
    await assertSucceeds(getDocs(collection(dbAs(BOB), 'sharedRides/g1/messages')));
  });

  test('üye olmayan okuyamaz ve yazamaz', async () => {
    await seed('sharedRides/g1', sharedRide());
    await seed('sharedRides/g1/messages/m1', { ...message(), sentAt: 1 });
    const db = dbAs(CAROL);
    await assertFails(getDocs(collection(db, 'sharedRides/g1/messages')));
    await assertFails(getDoc(doc(db, 'sharedRides/g1/messages/m1')));
    await assertFails(setDoc(doc(db, 'sharedRides/g1/messages/m2'), message({ senderId: 'carol' })));
    await assertFails(getDocs(collection(anonymousDb(), 'sharedRides/g1/messages')));
  });

  test('başkası adına, boş, çok uzun ya da fazladan alanlı mesaj yazılamaz', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    const ref = (id) => doc(dbAs(ALICE), `sharedRides/g1/messages/${id}`);
    await assertFails(setDoc(ref('m1'), message({ senderId: 'bob' })));
    await assertFails(setDoc(ref('m2'), message({ text: '' })));
    await assertFails(setDoc(ref('m3'), message({ text: 'x'.repeat(501) })));
    await assertFails(setDoc(ref('m4'), message({ phone: ALICE.phone })));
    await assertFails(setDoc(ref('m5'), message({ sentAt: 1 })));
  });

  test('mesaj değiştirilemez; başkasının mesajını yalnızca tek kalan üye siler', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await seed('sharedRides/g1/messages/m1', { ...message(), sentAt: 1 });
    const ref = doc(dbAs(ALICE), 'sharedRides/g1/messages/m1');
    await assertFails(updateDoc(ref, { text: 'değişti' }));
    await assertFails(deleteDoc(doc(dbAs(BOB), 'sharedRides/g1/messages/m1')));
    await seed('sharedRides/g1/messages/m2', { ...message({ senderId: 'bob', senderName: 'Bob' }), sentAt: 1 });
    await seed('sharedRides/g1', sharedRide());
    await assertFails(deleteDoc(doc(dbAs(BOB), 'sharedRides/g1/messages/m1')));
    // Tek kalan üye, ayrılan üyenin mesajını da temizleyebilir (grubu silmeden önce).
    await assertSucceeds(deleteDoc(doc(dbAs(ALICE), 'sharedRides/g1/messages/m2')));
    await assertSucceeds(deleteDoc(ref));
  });

  test('üye kendi mesajını siler (hesap silme), başkasınınkini silemez', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await seed('sharedRides/g1/messages/m1', { ...message(), sentAt: 1 });
    await seed('sharedRides/g1/messages/m2', { ...message({ senderId: 'bob', senderName: 'Bob' }), sentAt: 1 });
    await assertFails(deleteDoc(doc(dbAs(ALICE), 'sharedRides/g1/messages/m2')));
    await assertSucceeds(deleteDoc(doc(dbAs(ALICE), 'sharedRides/g1/messages/m1')));
  });

  test('ayrılan üye artık okuyamaz', async () => {
    await seed('sharedRides/g1', twoMemberRide());
    await seed(pickupPath('g1', 'bob'), pickup({ place: NEAR }));
    await assertSucceeds(leaveBatch(dbAs(BOB), BOB, { oldDetour: 2500, price: 1140 }));
    await assertFails(getDocs(collection(dbAs(BOB), 'sharedRides/g1/messages')));
  });
});

const liveShare = (overrides = {}) => ({
  ownerId: 'alice',
  from: 'Lefkoşa',
  to: 'Girne',
  destination: { lat: 35.3412, lng: 33.3196 },
  driverName: 'Ahmet Yılmaz',
  plate: 'ABC 123',
  car: 'Toyota Corolla (Beyaz)',
  status: 'active',
  position: { lat: 35.1856, lng: 33.3823 },
  updatedAt: serverTimestamp(),
  expiresAt: Date.now() + 4 * HOUR,
  ...overrides,
});

/** Kurallara takılmadan hazır paylaşım koyar (sunucu zamanı yerine sabit). */
const seedShare = (id, overrides = {}) => seed(`liveShares/${id}`, { ...liveShare(overrides), updatedAt: 1 });

describe('liveShares canlı konum paylaşımı', () => {
  test('yolcu paylaşımı başlatır; bağlantıyı bilen herkes (girişsiz) okur', async () => {
    await assertSucceeds(setDoc(doc(dbAs(ALICE), 'liveShares/s1'), liveShare()));
    await assertSucceeds(getDoc(doc(anonymousDb(), 'liveShares/s1')));
    await assertSucceeds(getDoc(doc(dbAs(BOB), 'liveShares/s1')));
  });

  test('başkalarının paylaşımları listelenemez; sahibi kendininkileri listeler', async () => {
    await seedShare('s1');
    await assertFails(getDocs(collection(anonymousDb(), 'liveShares')));
    await assertFails(getDocs(collection(dbAs(BOB), 'liveShares')));
    await assertFails(getDocs(query(collection(dbAs(BOB), 'liveShares'), where('ownerId', '==', 'alice'))));
    await assertSucceeds(getDocs(query(collection(dbAs(ALICE), 'liveShares'), where('ownerId', '==', 'alice'))));
  });

  test('süresi dolan paylaşımı yalnızca sahibi okur', async () => {
    await seedShare('s1', { expiresAt: Date.now() - 1000 });
    await assertFails(getDoc(doc(anonymousDb(), 'liveShares/s1')));
    await assertSucceeds(getDoc(doc(dbAs(ALICE), 'liveShares/s1')));
  });

  test('geçersiz paylaşım başlatılamaz', async () => {
    const db = dbAs(ALICE);
    const ref = (id) => doc(db, `liveShares/${id}`);
    await assertFails(setDoc(ref('a'), liveShare({ ownerId: 'bob' })));
    await assertFails(setDoc(ref('b'), liveShare({ expiresAt: Date.now() + 7 * HOUR })));
    await assertFails(setDoc(ref('c'), liveShare({ expiresAt: Date.now() - 1000 })));
    await assertFails(setDoc(ref('d'), liveShare({ position: { lat: 200, lng: 33 } })));
    await assertFails(setDoc(ref('e'), liveShare({ status: 'ended' })));
    await assertFails(setDoc(ref('f'), liveShare({ phone: ALICE.phone })));
    await assertFails(setDoc(ref('g'), liveShare({ updatedAt: 1 })));
    await assertFails(setDoc(doc(anonymousDb(), 'liveShares/h'), liveShare()));
  });

  test('sahibi konumu yeniler ve paylaşımı bitirir (konum silinir)', async () => {
    await seedShare('s1');
    const ref = doc(dbAs(ALICE), 'liveShares/s1');
    await assertSucceeds(updateDoc(ref, { position: { lat: 35.2, lng: 33.4 }, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { status: 'ended', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(ref, { status: 'ended', position: deleteField(), updatedAt: serverTimestamp() }));
    // Bitmiş paylaşım yeniden açılamaz.
    await assertFails(updateDoc(ref, { status: 'active', position: { lat: 35.2, lng: 33.4 }, updatedAt: serverTimestamp() }));
  });

  test('başkası güncelleyemez ve silemez; sahibi başka alan değiştiremez', async () => {
    await seedShare('s1');
    const bobRef = doc(dbAs(BOB), 'liveShares/s1');
    await assertFails(updateDoc(bobRef, { position: { lat: 35.2, lng: 33.4 }, updatedAt: serverTimestamp() }));
    await assertFails(deleteDoc(bobRef));
    const ref = doc(dbAs(ALICE), 'liveShares/s1');
    await assertFails(updateDoc(ref, { expiresAt: Date.now() + 5 * HOUR, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { plate: 'XYZ 999', updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(ref));
  });
});

const report = (overrides = {}) => ({
  reporterId: 'alice',
  reportedId: 'bob',
  rideId: 'g1',
  messageId: 'm1',
  text: 'kaba bir mesaj',
  reason: 'harassment',
  createdAt: serverTimestamp(),
  ...overrides,
});

describe('reports ve users/{uid}/blocked şikâyet ve engelleme', () => {
  test('kendi adına şikâyet oluşturur; kimse okuyamaz, değiştiremez, silemez', async () => {
    const ref = doc(dbAs(ALICE), 'reports/r1');
    await assertSucceeds(setDoc(ref, report()));
    await assertFails(getDoc(ref));
    await assertFails(getDocs(collection(dbAs(BOB), 'reports')));
    await assertFails(updateDoc(ref, { reason: 'spam' }));
    await assertFails(deleteDoc(ref));
  });

  test('başkası adına, kendini, girişsiz ya da geçersiz nedenle şikâyet edilemez', async () => {
    const db = dbAs(ALICE);
    await assertFails(setDoc(doc(db, 'reports/a'), report({ reporterId: 'bob' })));
    await assertFails(setDoc(doc(db, 'reports/b'), report({ reportedId: 'alice' })));
    await assertFails(setDoc(doc(db, 'reports/c'), report({ reason: 'sevmedim' })));
    await assertFails(setDoc(doc(db, 'reports/d'), report({ phone: ALICE.phone })));
    await assertFails(setDoc(doc(anonymousDb(), 'reports/e'), report()));
  });

  test('engelleme listesini yalnızca sahibi görür ve değiştirir', async () => {
    const ref = doc(dbAs(ALICE), 'users/alice/blocked/bob');
    await assertSucceeds(setDoc(ref, { createdAt: serverTimestamp() }));
    await assertSucceeds(getDocs(collection(dbAs(ALICE), 'users/alice/blocked')));
    await assertFails(getDocs(collection(dbAs(BOB), 'users/alice/blocked')));
    await assertFails(setDoc(doc(dbAs(BOB), 'users/alice/blocked/carol'), { createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(dbAs(ALICE), 'users/alice/blocked/alice'), { createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(dbAs(ALICE), 'users/alice/blocked/carol'), { createdAt: serverTimestamp(), note: 'x' }));
    await assertFails(deleteDoc(doc(dbAs(BOB), 'users/alice/blocked/bob')));
    await assertSucceeds(deleteDoc(ref));
  });
});

const driverProfile = (user, overrides = {}) => ({
  name: 'Ahmet Yılmaz',
  plate: 'TAB 123',
  car: 'Toyota Corolla',
  carColor: 'white',
  phone: user.phone,
  online: true,
  position: { lat: 35.18, lng: 33.38 },
  updatedAt: serverTimestamp(),
  ...overrides,
});

const ride = (overrides = {}) => ({
  passengerId: 'alice',
  pickup: { name: 'Lefkoşa', lat: 35.18, lng: 33.38 },
  destination: { name: 'Girne', lat: 35.34, lng: 33.32 },
  distanceMeters: 25000,
  durationSeconds: 1800,
  taxiType: 'economy',
  payment: 'cash',
  fareLow: 990,
  fareHigh: 1210,
  status: 'searching',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const seedRide = (id, overrides = {}) => seed(`rides/${id}`, { ...ride(overrides), createdAt: 1, updatedAt: 1 });
// Yönetici (konsol) onaylı şoför; seed kurallardan geçmez.
const seedDriver = (user, overrides = {}) => seed(`drivers/${user.uid}`, { ...driverProfile(user, overrides), approved: true, updatedAt: 1 });
// BOB'un seedDriver kaydıyla birebir aynı (kurallar karşılaştırır).
const driverSnapshot = { name: 'Ahmet Yılmaz', plate: 'TAB 123', car: 'Toyota Corolla', carColor: 'white', phone: BOB.phone };

/** Uygulamanın yaptığı gibi: çağrı ve yolcunun "etkin çağrı" kilidi tek seferde yazılır. */
const requestRide = (user, id, overrides = {}) => {
  const db = dbAs(user);
  const batch = writeBatch(db);
  batch.set(doc(db, `rides/${id}`), ride({ passengerId: user.uid, ...overrides }));
  batch.set(doc(db, `rideLocks/${user.uid}`), { rideId: id, at: serverTimestamp() });
  return batch.commit();
};

describe('drivers şoför kaydı', () => {
  test('kullanıcı kendini şoför olarak kaydeder (onaysız, çevrimdışı); kaydını yalnızca kendisi okur', async () => {
    await assertSucceeds(setDoc(doc(dbAs(BOB), 'drivers/bob'), driverProfile(BOB, { online: false })));
    await assertSucceeds(getDoc(doc(dbAs(BOB), 'drivers/bob')));
    await assertFails(getDoc(doc(dbAs(ALICE), 'drivers/bob')));
    await assertFails(getDoc(doc(anonymousDb(), 'drivers/bob')));
  });

  test('kimse şoförlerin telefon ve konum listesini çekemez', async () => {
    await seedDriver(BOB);
    await seedDriver(CAROL, { online: false });
    await assertFails(getDocs(collection(dbAs(ALICE), 'drivers')));
    await assertFails(getDocs(collection(dbAs(BOB), 'drivers')));
  });

  test('başkası adına, başka telefonla ya da geçersiz alanla kayıt olmaz', async () => {
    const offline = { online: false };
    await assertFails(setDoc(doc(dbAs(ALICE), 'drivers/bob'), driverProfile(BOB, offline)));
    await assertFails(setDoc(doc(dbAs(BOB), 'drivers/bob'), driverProfile(BOB, { ...offline, phone: ALICE.phone })));
    await assertFails(setDoc(doc(dbAs(BOB), 'drivers/bob'), driverProfile(BOB, { ...offline, carColor: 'pembe' })));
    await assertFails(setDoc(doc(dbAs(BOB), 'drivers/bob'), driverProfile(BOB, { ...offline, plate: '' })));
  });

  test('şoför kendini onaylayamaz; onaysız çevrimiçi olamaz', async () => {
    const ref = doc(dbAs(BOB), 'drivers/bob');
    await assertFails(setDoc(ref, driverProfile(BOB, { online: false, approved: true })));
    await assertFails(setDoc(ref, driverProfile(BOB, { online: true })));
    await assertSucceeds(setDoc(ref, driverProfile(BOB, { online: false })));
    await assertFails(updateDoc(ref, { online: true, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { approved: true, updatedAt: serverTimestamp() }));
  });

  test('onaylı şoför çevrimiçi olur ama onayı değiştiremez; silip yeniden kaydolunca onay gider', async () => {
    await seedDriver(BOB, { online: false });
    const ref = doc(dbAs(BOB), 'drivers/bob');
    await assertSucceeds(updateDoc(ref, { online: true, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { approved: false, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(ref, { plate: 'ABC 999', updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(ref));
    await assertFails(setDoc(ref, driverProfile(BOB, { online: true })));
  });
});

describe('rides çağrılar ve eşleştirme', () => {
  test('yolcu kendi adına çağrı oluşturur; başkası adına, geçersiz ya da atanmış oluşturamaz', async () => {
    await assertFails(requestRide(ALICE, 'r2', { passengerId: 'bob' }));
    await assertFails(requestRide(ALICE, 'r3', { status: 'driverAssigned' }));
    await assertFails(requestRide(ALICE, 'r4', { driverId: 'bob' }));
    await assertFails(requestRide(ALICE, 'r5', { taxiType: 'limuzin' }));
    await assertSucceeds(requestRide(ALICE, 'r1'));
  });

  test('ücret ve koordinatlar geçerli olmalı', async () => {
    await assertFails(requestRide(ALICE, 'r1', { fareLow: -500, fareHigh: 0 }));
    await assertFails(requestRide(ALICE, 'r2', { fareLow: 1200, fareHigh: 900 }));
    await assertFails(requestRide(ALICE, 'r3', { fareLow: 1, fareHigh: 10000000 }));
    await assertFails(requestRide(ALICE, 'r4', { pickup: { name: 'X', lat: 999, lng: -999 } }));
    await assertFails(requestRide(ALICE, 'r5', { destination: { name: 'X', lat: 35, lng: 200 } }));
    await assertSucceeds(requestRide(ALICE, 'r6'));
  });

  test('yolcunun aynı anda tek etkin çağrısı olur; kilitsiz çağrı açılamaz', async () => {
    await assertFails(setDoc(doc(dbAs(ALICE), 'rides/r0'), ride()));
    await assertSucceeds(requestRide(ALICE, 'r1'));
    await assertFails(requestRide(ALICE, 'r2'));
    // İptal edince yenisi açılır.
    await updateDoc(doc(dbAs(ALICE), 'rides/r1'), { status: 'cancelled', updatedAt: serverTimestamp() });
    await assertSucceeds(requestRide(ALICE, 'r2'));
    // Kilit başkasının çağrısını ya da olmayan çağrıyı göstermez.
    await seedRide('rb', { passengerId: 'bob' });
    await assertFails(setDoc(doc(dbAs(BOB), 'rideLocks/bob'), { rideId: 'rb', at: serverTimestamp() }));
    await assertFails(setDoc(doc(dbAs(ALICE), 'rideLocks/alice'), { rideId: 'rb', at: serverTimestamp() }));
    await assertFails(setDoc(doc(dbAs(ALICE), 'rideLocks/bob'), { rideId: 'r2', at: serverTimestamp() }));
  });

  test('uygulama kapanınca takılı kalan arama 10 dakika sonra yenisini engellemez', async () => {
    await seed('rides/old', { ...ride(), createdAt: Timestamp.fromMillis(Date.now() - 20 * 60 * 1000), updatedAt: 1 });
    await seed('rideLocks/alice', { rideId: 'old', at: Timestamp.fromMillis(Date.now() - 20 * 60 * 1000) });
    await assertSucceeds(requestRide(ALICE, 'r1'));
    await seed('rides/r1', { ...ride(), createdAt: Timestamp.fromMillis(Date.now() - 60 * 1000), updatedAt: 1 });
    await assertFails(requestRide(ALICE, 'r2'));
  });

  test('uygulama kapanınca yarım kalan atanmış çağrı yenisini engeller; yolcu iptal edince açılır', async () => {
    const recent = Timestamp.fromMillis(Date.now() - 5 * 60 * 1000);
    await seed('rides/old', { ...ride(), status: 'driverAssigned', driverId: 'bob', driver: driverSnapshot, createdAt: recent, updatedAt: recent });
    await seed('rideLocks/alice', { rideId: 'old', at: recent });
    await assertFails(requestRide(ALICE, 'r1'));
    // Uygulama yeni çağrıdan önce kilidi ve eski çağrıyı okur, iptal eder.
    await assertSucceeds(getDoc(doc(dbAs(ALICE), 'rideLocks/alice')));
    await assertSucceeds(getDoc(doc(dbAs(ALICE), 'rides/old')));
    await assertSucceeds(updateDoc(doc(dbAs(ALICE), 'rides/old'), { status: 'cancelled', updatedAt: serverTimestamp() }));
    await assertSucceeds(requestRide(ALICE, 'r1'));
  });

  test('kilidi yalnızca sahibi okur ve siler (hesap silme)', async () => {
    await assertSucceeds(requestRide(ALICE, 'r1'));
    await assertFails(getDoc(doc(dbAs(BOB), 'rideLocks/alice')));
    await assertFails(deleteDoc(doc(dbAs(BOB), 'rideLocks/alice')));
    await assertSucceeds(getDoc(doc(dbAs(ALICE), 'rideLocks/alice')));
    await assertSucceeds(deleteDoc(doc(dbAs(ALICE), 'rideLocks/alice')));
  });

  test('bekleyen çağrıyı yalnızca onaylı, çevrimiçi şoförler görür', async () => {
    await seedRide('r1');
    await seedDriver(BOB);
    await seedDriver(CAROL, { online: false });
    await seed('drivers/dave', { ...driverProfile(DAVE), updatedAt: 1 }); // çevrimiçi ama onaysız
    await assertFails(getDoc(doc(dbAs(DAVE), 'rides/r1')));
    await assertFails(getDocs(query(collection(dbAs(DAVE), 'rides'), where('status', '==', 'searching'))));
    await assertSucceeds(getDocs(query(collection(dbAs(BOB), 'rides'), where('status', '==', 'searching'))));
    await assertFails(getDocs(query(collection(dbAs(CAROL), 'rides'), where('status', '==', 'searching'))));
    await assertFails(getDoc(doc(dbAs(CAROL), 'rides/r1')));
    await assertSucceeds(getDoc(doc(dbAs(ALICE), 'rides/r1')));
  });

  test('kimse almadan iptal edilen çağrıyı çevrimiçi şoför okur; atanmış iptali okuyamaz', async () => {
    await seedRide('r1', { status: 'cancelled' });
    await seedRide('r2', { status: 'cancelled', driverId: 'dave', driver: driverSnapshot });
    await seedDriver(BOB);
    await seedDriver(CAROL, { online: false });
    await assertSucceeds(getDoc(doc(dbAs(BOB), 'rides/r1')));
    await assertFails(getDoc(doc(dbAs(CAROL), 'rides/r1')));
    await assertFails(getDoc(doc(dbAs(BOB), 'rides/r2')));
  });

  test('çevrimiçi şoför çağrıyı kendine alır; ikinci şoför alamaz', async () => {
    await seedRide('r1');
    await seedDriver(BOB);
    await seedDriver(CAROL);
    const accept = (user) => updateDoc(doc(dbAs(user), 'rides/r1'), {
      status: 'driverAssigned',
      driverId: user.uid,
      driver: driverSnapshot,
      driverPosition: { lat: 35.18, lng: 33.38 },
      updatedAt: serverTimestamp(),
    });
    await assertFails(updateDoc(doc(dbAs(BOB), 'rides/r1'), {
      status: 'driverAssigned', driverId: 'carol', driver: driverSnapshot,
      driverPosition: { lat: 35.18, lng: 33.38 }, updatedAt: serverTimestamp(),
    }));
    // Yolcuya görünen şoför bilgisi şoförün kendi kaydından başka olamaz.
    for (const fake of [{ ...driverSnapshot, name: 'Polis' }, { ...driverSnapshot, phone: '+900000000000' },
      { ...driverSnapshot, plate: 'SAHTE' }, { ...driverSnapshot, extra: 'x' }]) {
      await assertFails(updateDoc(doc(dbAs(BOB), 'rides/r1'), {
        status: 'driverAssigned', driverId: 'bob', driver: fake,
        driverPosition: { lat: 35.18, lng: 33.38 }, updatedAt: serverTimestamp(),
      }));
    }
    await assertSucceeds(accept(BOB));
    await assertFails(accept(CAROL));
    // Atandıktan sonra diğer şoför okuyamaz; atanan şoför ve yolcu okur.
    await assertFails(getDoc(doc(dbAs(CAROL), 'rides/r1')));
    await assertSucceeds(getDoc(doc(dbAs(BOB), 'rides/r1')));
    await assertSucceeds(getDoc(doc(dbAs(ALICE), 'rides/r1')));
  });

  test('şoför kendi çağrısını alamaz; onaysız şoför de alamaz', async () => {
    await seedRide('r1', { passengerId: 'bob' });
    await seedRide('r2');
    await seedDriver(BOB);
    await seed('drivers/dave', { ...driverProfile(DAVE), updatedAt: 1 });
    const accept = (user, id) => updateDoc(doc(dbAs(user), `rides/${id}`), {
      status: 'driverAssigned', driverId: user.uid, driver: driverSnapshot,
      driverPosition: { lat: 35.18, lng: 33.38 }, updatedAt: serverTimestamp(),
    });
    await assertFails(accept(BOB, 'r1'));
    await assertFails(accept(DAVE, 'r2'));
    await assertSucceeds(accept(BOB, 'r2'));
  });

  test('atanan şoför konum yeniler ve sırayla vardı → başladı → bitti', async () => {
    await seedRide('r1', { status: 'driverAssigned', driverId: 'bob', driver: driverSnapshot, driverPosition: { lat: 35.18, lng: 33.38 } });
    const ref = doc(dbAs(BOB), 'rides/r1');
    const move = { driverPosition: { lat: 35.19, lng: 33.38 }, updatedAt: serverTimestamp() };
    await assertSucceeds(updateDoc(ref, move));
    await assertFails(updateDoc(ref, { status: 'completed', ...move }));
    await assertSucceeds(updateDoc(ref, { status: 'driverArrived', ...move }));
    await assertSucceeds(updateDoc(ref, { status: 'inProgress', ...move }));
    await assertFails(updateDoc(ref, { status: 'cancelled', ...move }));
    await assertSucceeds(updateDoc(ref, { status: 'completed', ...move }));
    await assertFails(updateDoc(ref, move));
    await assertFails(updateDoc(doc(dbAs(CAROL), 'rides/r1'), move));
  });

  test('yolcu yalnızca yolculuk başlamadan iptal eder ve bitince puan verir', async () => {
    await seedRide('r1', { status: 'driverAssigned', driverId: 'bob', driver: driverSnapshot });
    const ref = doc(dbAs(ALICE), 'rides/r1');
    await assertFails(updateDoc(ref, { status: 'inProgress', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { status: 'cancelled', fareLow: 1, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(ref, { status: 'cancelled', updatedAt: serverTimestamp() }));

    await seedRide('r2', { status: 'inProgress', driverId: 'bob', driver: driverSnapshot });
    await assertFails(updateDoc(doc(dbAs(ALICE), 'rides/r2'), { status: 'cancelled', updatedAt: serverTimestamp() }));

    await seedRide('r3', { status: 'completed', driverId: 'bob', driver: driverSnapshot });
    const r3 = doc(dbAs(ALICE), 'rides/r3');
    await assertFails(updateDoc(r3, { rating: 7, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(r3, { rating: 5, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(dbAs(BOB), 'rides/r3'), { rating: 1, updatedAt: serverTimestamp() }));
  });

  test('çağrılar silinemez', async () => {
    await seedRide('r1');
    await assertFails(deleteDoc(doc(dbAs(ALICE), 'rides/r1')));
  });
});

describe('diğer koleksiyonlar', () => {
  test('kurallarda açılmamış her yer kapalı', async () => {
    const db = dbAs(ALICE);
    await assertFails(getDoc(doc(db, 'rides/r1')));
    await assertFails(setDoc(doc(db, 'rides/r1'), { from: 'A' }));
  });
});
