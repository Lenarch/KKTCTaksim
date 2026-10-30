// Firestore güvenlik kurallarının testleri. Gerçek projeye değil, yerel emülatöre karşı çalışır.
// Çalıştırmak: firestore-tests klasöründe `npm test` (Java gerekir).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, updateDoc, deleteDoc, collection, getDocs } from 'firebase/firestore';

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

  test('profilde fazladan alan olamaz', async () => {
    const ref = doc(dbAs(ALICE), 'users/alice');
    await assertFails(setDoc(ref, { phone: ALICE.phone, updatedAt: serverTimestamp(), role: 'admin' }));
  });

  test('giriş yapmamış kişi hiçbir şeye erişemez', async () => {
    await seed('users/alice', { phone: ALICE.phone });
    await assertFails(getDoc(doc(anonymousDb(), 'users/alice')));
  });

  test('profil silinemez', async () => {
    await seed('users/alice', { phone: ALICE.phone });
    await assertFails(deleteDoc(doc(dbAs(ALICE), 'users/alice')));
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

  test('tamamlanmış yolculuk değiştirilemez ve silinemez', async () => {
    await seed('users/alice/trips/t1', trip({ status: 'completed' }));
    const ref = doc(dbAs(ALICE), 'users/alice/trips/t1');
    await assertFails(updateDoc(ref, { price: 1 }));
    await assertFails(updateDoc(ref, { status: 'cancelled', price: 0 }));
    await assertFails(deleteDoc(ref));
  });
});

const CAROL = { uid: 'carol', phone: '+905330000003' };
const FUTURE = Date.now() + 24 * 60 * 60 * 1000;

const sharedRide = (overrides = {}) => ({
  from: 'Girne',
  to: 'Gazimağusa',
  departure: FUTURE,
  capacity: 4,
  memberIds: ['alice'],
  pricePerPerson: 300,
  ...overrides,
});

describe('sharedRides paylaşımlı gruplar', () => {
  test('giriş yapan herkes grupları okur; giriş yapmayan okuyamaz', async () => {
    await seed('sharedRides/g1', sharedRide());
    await assertSucceeds(getDocs(collection(dbAs(BOB), 'sharedRides')));
    await assertFails(getDoc(doc(anonymousDb(), 'sharedRides/g1')));
  });

  test('oluşturan tek ve ilk üye olur', async () => {
    const db = dbAs(ALICE);
    await assertSucceeds(setDoc(doc(db, 'sharedRides/g1'), sharedRide()));
    await assertFails(setDoc(doc(db, 'sharedRides/g2'), sharedRide({ memberIds: ['bob'] })));
    await assertFails(setDoc(doc(db, 'sharedRides/g3'), sharedRide({ memberIds: ['alice', 'bob'] })));
    await assertFails(setDoc(doc(db, 'sharedRides/g4'), sharedRide({ memberIds: [] })));
  });

  test('geçersiz grup oluşturulamaz', async () => {
    const db = dbAs(ALICE);
    await assertFails(setDoc(doc(db, 'sharedRides/g1'), sharedRide({ departure: Date.now() - 60000 })));
    await assertFails(setDoc(doc(db, 'sharedRides/g2'), sharedRide({ capacity: 0 })));
    await assertFails(setDoc(doc(db, 'sharedRides/g3'), sharedRide({ capacity: 9 })));
    await assertFails(setDoc(doc(db, 'sharedRides/g4'), sharedRide({ pricePerPerson: 0 })));
    await assertFails(setDoc(doc(db, 'sharedRides/g5'), sharedRide({ from: '' })));
    await assertFails(setDoc(doc(db, 'sharedRides/g6'), sharedRide({ driverId: 'x' })));
    const { to, ...missingTo } = sharedRide();
    await assertFails(setDoc(doc(db, 'sharedRides/g7'), missingTo));
  });

  test('kullanıcı yalnızca kendini ekleyerek katılır', async () => {
    await seed('sharedRides/g1', sharedRide());
    const ref = doc(dbAs(BOB), 'sharedRides/g1');
    await assertFails(updateDoc(ref, { memberIds: ['alice', 'carol'] }));
    await assertFails(updateDoc(ref, { memberIds: ['bob', 'alice'] }));
    await assertFails(updateDoc(ref, { memberIds: ['alice', 'bob'], pricePerPerson: 1 }));
    await assertSucceeds(updateDoc(ref, { memberIds: ['alice', 'bob'] }));
    await assertFails(updateDoc(ref, { memberIds: ['alice', 'bob', 'bob'] }));
  });

  test('dolu ya da kalkışı geçmiş gruba katılınamaz', async () => {
    await seed('sharedRides/full', sharedRide({ capacity: 2, memberIds: ['alice', 'carol'] }));
    await seed('sharedRides/past', sharedRide({ departure: Date.now() - 60000 }));
    const db = dbAs(BOB);
    await assertFails(updateDoc(doc(db, 'sharedRides/full'), { memberIds: ['alice', 'carol', 'bob'] }));
    await assertFails(updateDoc(doc(db, 'sharedRides/past'), { memberIds: ['alice', 'bob'] }));
  });

  test('kullanıcı yalnızca kendini çıkararak ayrılır', async () => {
    await seed('sharedRides/g1', sharedRide({ memberIds: ['alice', 'bob', 'carol'] }));
    await assertFails(updateDoc(doc(dbAs(BOB), 'sharedRides/g1'), { memberIds: ['bob', 'carol'] }));
    await assertSucceeds(updateDoc(doc(dbAs(BOB), 'sharedRides/g1'), { memberIds: ['alice', 'carol'] }));
    // Son üye listeyi boşaltamaz; grubu silmesi gerekir.
    await seed('sharedRides/g2', sharedRide());
    await assertFails(updateDoc(doc(dbAs(ALICE), 'sharedRides/g2'), { memberIds: [] }));
  });

  test('grubu yalnızca tek kalan üye silebilir', async () => {
    await seed('sharedRides/g1', sharedRide({ memberIds: ['alice', 'bob'] }));
    await assertFails(deleteDoc(doc(dbAs(ALICE), 'sharedRides/g1')));
    await assertFails(deleteDoc(doc(dbAs(CAROL), 'sharedRides/g1')));
    await seed('sharedRides/g2', sharedRide());
    await assertFails(deleteDoc(doc(dbAs(BOB), 'sharedRides/g2')));
    await assertSucceeds(deleteDoc(doc(dbAs(ALICE), 'sharedRides/g2')));
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
  test('üye mesaj yazar ve okur', async () => {
    await seed('sharedRides/g1', sharedRide({ memberIds: ['alice', 'bob'] }));
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
    await seed('sharedRides/g1', sharedRide({ memberIds: ['alice', 'bob'] }));
    const ref = (id) => doc(dbAs(ALICE), `sharedRides/g1/messages/${id}`);
    await assertFails(setDoc(ref('m1'), message({ senderId: 'bob' })));
    await assertFails(setDoc(ref('m2'), message({ text: '' })));
    await assertFails(setDoc(ref('m3'), message({ text: 'x'.repeat(501) })));
    await assertFails(setDoc(ref('m4'), message({ phone: ALICE.phone })));
    await assertFails(setDoc(ref('m5'), message({ sentAt: 1 })));
  });

  test('mesaj değiştirilemez; silmeyi yalnızca tek kalan üye yapar', async () => {
    await seed('sharedRides/g1', sharedRide({ memberIds: ['alice', 'bob'] }));
    await seed('sharedRides/g1/messages/m1', { ...message(), sentAt: 1 });
    const ref = doc(dbAs(ALICE), 'sharedRides/g1/messages/m1');
    await assertFails(updateDoc(ref, { text: 'değişti' }));
    await assertFails(deleteDoc(ref));
    await seed('sharedRides/g1', sharedRide({ memberIds: ['alice'] }));
    await assertFails(deleteDoc(doc(dbAs(BOB), 'sharedRides/g1/messages/m1')));
    await assertSucceeds(deleteDoc(ref));
  });

  test('ayrılan üye artık okuyamaz', async () => {
    await seed('sharedRides/g1', sharedRide({ memberIds: ['alice', 'bob'] }));
    await updateDoc(doc(dbAs(BOB), 'sharedRides/g1'), { memberIds: ['alice'] });
    await assertFails(getDocs(collection(dbAs(BOB), 'sharedRides/g1/messages')));
  });
});

describe('diğer koleksiyonlar', () => {
  test('kurallarda açılmamış her yer kapalı', async () => {
    const db = dbAs(ALICE);
    await assertFails(getDoc(doc(db, 'rides/r1')));
    await assertFails(setDoc(doc(db, 'rides/r1'), { from: 'A' }));
  });
});
