# Paylaşımlı yolculuk: şoför her yolcuyu kendi noktasından alır — Tasarım

Tarih: 2026-11-13. Durum: onay bekliyor. Kod yazılmadı.

## 1. Amaç ve neden

Bugün paylaşımlı yolculuk yalnızca yolcuların buluştuğu bir ilan panosu: grup kurulur, insanlar katılır,
sohbet eder. Şoför yok, taksi ayrıca bulunur. İstenen: bir şoför grubu önceden üstlensin ve her yolcuyu
**yolcunun kendi seçtiği noktadan** alıp ortak varışa götürsün.

Sahibinin en çok önem verdiği şey: **şoför zarar etmemeli.** "Geliyorum" deyip gelmeyen yolcu yüzünden
şoför boşuna yakıt yakıyor. Kalıcı çözüm kapora (uygulama içi ödeme); o ayrı bir proje ve bu işten sonra
gelecek. Bu tasarım kaporasız ilk sürümdür ama kaporanın yerini hazır bırakır.

## 2. Hedefler, hedef olmayanlar, kaçınılacaklar

**Hedefler**
- Gruba katılan her yolcu (kurucu dahil) kendi toplama noktasını seçer.
- Onaylı şoförler yaklaşan grupları listede görür ve birini önceden üstlenir.
- Ücreti uygulama hesaplar ve üyelere eşit böler; kurucu ücret yazmaz.
- Şoför üstlendiği an üye listesi ve kişi başı ücret kilitlenir.
- Kalkış günü: yolcu teyit eder, şoför durak durak toplar ("Aldım" / "Gelmedi"), varışta bitirir.
- Gelmeyen yolcu kayda geçer; tekrarlayan bir süre gruplara katılamaz.

**Hedef olmayanlar (bu sürümde yok)**
- Uygulama içi ödeme, kapora, iptal ücreti (sonraki proje).
- Yolcuları farklı yerlere bırakma; varış herkes için tektir.
- Sunucu kodu (Cloud Functions) ve anlık bildirim (push). Bkz. Kısıtlar.
- Üstlenilmeyen grubun kalkışta tekli çağrıya dönüşmesi. Yerine: kalkışa 30 dakikadan az kalan sahipsiz
  gruplar şoför listesinin başında "Acil" diye öne çıkar. *(Benim kararım: tekli çağrı sistemi tek yolcu
  üzerine kurulu, dönüştürmek çalışan sistemi riske atar.)*

**Kaçınılacaklar (çalışsa bile başarısızlık sayılır)**
- Bir yolcunun toplama noktasını (ev adresi olabilir) şoför ve kendisi dışında birinin görebilmesi.
- Yolcunun, kilitlendiğinde gördüğünden fazla ücret ödemesi.
- Çalışan tekli taksi çağrısının bozulması.
- Şoförün keyfî "Gelmedi" işaretleyebilmesi.

## 3. Kısıtlar

- **Sunucu kodu yok.** Proje ücretsiz planla çalışmalı; her şey uygulama + Firestore kurallarıyla denetlenir.
- **Anlık bildirim yok.** Projede `firebase_messaging` yok ve başka kullanıcıya bildirim göndermek sunucu
  ister. Bu sürümde olaylar (şoför üstlendi, vazgeçti, yolcu alındı) yalnızca **uygulama açıkken** görünür
  (grup kartı, sohbet ekranı, rozet). Tek istisna teyit hatırlatması: yolcunun kendi telefonunda yerel
  zamanlanmış bildirimle yapılır (sunucu gerekmez).
- **Gerçek ödeme yok.** Ücret şoföre elden ödenir.
- Mevcut desenler korunur: `Backend.instance` depo deseni (hem `mock` hem `firebase` uygulaması yazılır),
  l10n (`app_tr.arb`, `app_en.arb`), `app_tokens`, `TrustedClock` ve Kıbrıs saati, testlerde sahte servis.
- Hesap silme (`removeMe`) yeni verileri de silmelidir.
- Firestore kuralları: istek başına en fazla 10 belge okuma; kurallar belge sayamaz, toplayamaz.

## 4. Yaklaşımlar

| | Yaklaşım | Artı | Eksi |
|---|---|---|---|
| **A (seçildi)** | Mevcut `sharedRides` yapısını genişlet; her şey istemci + kurallar | Sunucu ve ücretli plan gerekmez; sohbet/katılma aynen kalır | Denetim yalnızca kuralların ifade edebildiği kadar |
| B | Üstlenilen grubu çok duraklı tekli çağrıya (`rides`) çevir | Şoför ekranları hazır | `rides`, kuralları, yolculuk kilidi ve canlı takip tek yolcu varsayar; hepsini değiştirmek tekli çağrıyı riske atar |
| C | Üstlenme, ücret, kilit sunucuda (Cloud Functions) | En güvenilir; kapora için zaten gerekecek | Bugünden ücretli plan ister |

Sahibi A'yı onayladı. Ücret hesabı ve "Gelmedi" kuralı ayrı, saf parçalar olarak yazılır; kapora gelince
yalnızca bunlar sunucuya (C) taşınır.

## 5. Sahibinin verdiği kararlar

1. Şoför grubu **önceden üstlenir** ("Planlı gruplar" listesi).
2. Ücreti **uygulama hesaplar** ve üyelere böler.
3. **Şoför üstlendiği an** üye listesi ve ücret kilitlenir. Şoför vazgeçerse kilit açılır, grup listeye döner.
4. Kilitten sonra bir yolcu ayrılırsa **kalanların kişi başı ücreti değişmez**, şoförün toplamı düşer.
   Sahibi bu kuraldan memnun değil ("şimdilik"); kapora gelince değişecek. **Tek bir yerde durmalı.**
5. Şoförün korunması için nihai hedef **kapora**; önce bu sistem, sonra ödeme projesi.
6. 4 kişiye kadar gruplar ekonomik, 5–8 kişilik gruplar büyük araç tarifesiyle hesaplanır (bkz. 6.2).
7. "Gelmedi" kaydı hesap silinince silinir (bkz. 6.6).

## 6. Tasarım (aksi yazmadıkça benim kararlarım)

### 6.1 Kavramlar

- **Buluşma noktası** (`from`): grubun herkese açık başlangıcı (örn. "Girne Yat Limanı"). Artık koordinatı
  da saklanır. `to` için de aynısı.
- **Toplama noktası**: her üyenin özel noktası. Buluşma noktasına yol mesafesi en fazla
  `maxPickupDetourMeters` (öneri: 10 km, tek sabit). Üye "buluşma noktasından binerim" de diyebilir
  (sapma 0, varsayılan seçenek).
- **Sapma** (`detourMeters`): toplama noktasından buluşma noktasına yol mesafesi (rota servisinden; servis
  yanıt vermezse kuş uçuşu × 1,3). Herkese açık olan yalnızca bu **sayıdır**, konum değil; 100 m'ye yuvarlanır.

### 6.2 Ücret (tek saf fonksiyon, `fare_calculator.dart` yanında)

```
toplamMetre  = baseMeters + extraMeters          // ana güzergah + üyelerin sapmaları toplamı
toplam       = max(asgari, açılış + kmBaşı × toplamMetre/1000) × çarpan   // mevcut Tariff
kişiBaşı     = toplam / üyeSayısı, 10 TL'ye yukarı yuvarlanır
```

- **Çarpan (sahibinin kararı):** grubun `capacity` değeri 4'e kadarsa ekonomik (1,0), 5–8 ise büyük araç
  (mevcut `TaxiType.xl`, 1,8). Çarpan kişi sayısına değil kurulan kapasiteye bağlıdır, yani biri
  katılınca tarife sıçramaz. Şoför 5+ kapasiteli grubu üstlenirken "aracım bu kadar kişi alır" onayı
  verir (uygulama denetimi; şoför kaydına koltuk alanı eklenmez).

- Girdilerin hepsi grup belgesinde durur, bu yüzden **kurallar aynı hesabı yapıp tutarı doğrular**; ne
  kurucu ne şoför ücret yazabilir.
- Gerçek sürüş rotası değil, bilinçli bir yaklaşıktır: herkes aynı sayıları görür, doğrulanabilir, biri
  katılınca nasıl değişeceği önceden gösterilebilir. *(Sahibine not: "toplam rotadan" kararının
  uygulanabilir hâli budur.)*
- Kilitlenmeden önce kartta "Şu an 3 kişi: kişi başı ≈180 TL" görünür. Katılma ekranı, katılınca yeni
  tutarı önceden gösterir. Kilitlenince "≈" kalkar.

### 6.3 Veri yapısı

**`sharedRides/{id}`** (giriş yapan herkes okur — burada özel konum YOK)

| Alan | Açıklama |
|---|---|
| `from`, `to` | ad (mevcut) |
| `fromPoint`, `toPoint` | `{lat,lng}` (yeni) |
| `departure`, `capacity`, `memberIds` | mevcut. `departure` = şoförün toplamaya başlama saati |
| `baseMeters` | buluşma → varış yol mesafesi; kurallar kuş uçuşuna göre 1×–3× aralığında sınırlar |
| `detours` | `{uid: metre}`; `extraMeters` = toplamı (katılma +, ayrılma − ile kurallarca tutarlı tutulur) |
| `pricePerPerson` | 6.2'nin sonucu; her üyelik değişiminde yeniden yazılır, kurallar doğrular. Alan adı korunur ki eski sürümler listeyi okuyabilsin |
| `status` | `open` → `claimed` → `enRoute` → `inTrip` → `completed`; `claimed`/`enRoute`/`inTrip` → `cancelled` (yalnızca şoför) |
| `driverId` | üstlenen şoför; `open` iken yok |

**`sharedRides/{id}/pickups/{uid}`** (sahibi her zaman okur; şoför yalnızca **kalkışa 60 dakika kala ve
sonrasında**, grup bitene kadar okur)
`place` (`{name,lat,lng}`), `state`: `waiting` → `confirmed` → `pickedUp` | `noShow` | `skipped`,
`arrivedAt` (şoför durağa vardığını işaretleyince, sunucu zamanı), `stopsBefore` (bu üyeden önce kalan
durak sayısı) ve `driverPosition` (şoför yalnızca **sıradaki durağın** kaydına yazar).
- Şoförün canlı konumu ve durak sırası ortak bir belgede **durmaz**: ortak dursaydı haritayı izleyen üye
  diğerlerinin toplama noktalarını görürdü. Üye, şoförü haritada yalnızca sıra kendisine gelince görür;
  öncesinde "Senden önce 2 durak var" yazısı görür. (Araca binmiş yolcuların sonraki durakları görmesi
  kaçınılmazdır.)
- Şoför "Bitir" ya da "İptal" derken toplama kayıtlarını aynı işlemde siler; kurallar da `completed` /
  `cancelled` sonrasında şoförün okumasını kapatır.

**`sharedRides/{id}/trip/state`** (yalnızca üyeler ve şoför okur; şoför yazar)
Şoförün görünen bilgisi (`rides`'taki gibi kendi kaydının birebir kopyası: ad, plaka, araç, renk, telefon),
`updatedAt`. Durak sırası (`stopOrder`) şoförün telefonunda tutulur, üyelere açılmaz.

**`reliability/{uid}`** (sahibi ve onaylı şoförler okur)
`noShows` (sayı), `blockedUntil` (zaman). Yalnızca 6.6'daki kurala uyan şoför yazımıyla artar.

### 6.4 Yolcu akışı

1. **Grup kurma** (3 adım kalır): nereden → nereye → tarih/saat/kişi sayısı. Ücret alanı kalkar; son adımda
   tahmini ücret gösterilir. Ardından kurucu kendi toplama noktasını seçer.
2. **Katılma**: "Katıl" → toplama noktası seçimi (mevcut `DestinationSheet` + `MapPickScreen`,
   `requireName: true`; ayrıca "Buluşma noktasından binerim") → yeni kişi başı ücret gösterilir → onay.
   Üyelik, sapma, ücret ve toplama kaydı **tek toplu yazımda** gider.
3. Üye, üstlenilene kadar toplama noktasını değiştirebilir ve ayrılabilir.
4. **Üstlenilince**: grup kartında ve sohbet ekranında şoför bilgisi, kilitli ücret, "Üstlenildi" etiketi.
   Yeni katılım kapanır. Ayrılmak serbest (karar 4); ücret değişmez.
5. **Teyit**: kalkıştan 60 dakika önce yerel bildirim + uygulamada "Geliyorum" düğmesi. Kalkışa kadar basılabilir.
6. **Yolculuk**: sohbet ekranının üstünde yolculuk paneli: şoförün haritadaki konumu, benim durağım,
   durum ("Şoför yolda", "Sıradaki durak sensin", "Alındın"). Şoför yola çıktıktan sonra ayrılma kapanır.

### 6.5 Şoför akışı

1. Şoför kabuğunda yeni **"Planlı gruplar"** sekmesi: `open` gruplar kalkışa göre sıralı; güzergah, saat,
   doluluk ("2/4"), toplam ve kişi başı ücret, en uzak sapma. Onaylı şoför olmak yeter, çevrimiçi olmak
   gerekmez.
2. **"Ben alırım"** (transaction; ilk yazan alır): `status=claimed`, `driverId`. Bundan sonra şoför
   üyelerin güvenilirlik kayıtlarını ("2 kez gelmedi") görür ve **grup sohbetine katılır** (okur, yazar;
   sohbet kuralları ve engelleme şoförü de kapsayacak biçimde genişler). Üyeler şoförün telefonunu görür;
   şoför yolcu telefonlarını görmez, yolcuya sohbetten ulaşır. Beğenmezse **"Bırak"** der: grup `open`
   olur, kilit açılır, şoför sohbetten çıkar.
   - Toplama **adresleri** şoföre kalkışa 60 dakika kala açılır; öncesinde yalnızca sapma mesafelerini
     görür. Böylece "üstlen, adresleri oku, bırak" yoluyla adres toplanamaz.
   - Bırakmaya sınır yok (son dakikada bırakmak, hiç gelmemekten iyidir). Bilinen sınır: sık bırakan şoför
     bu sürümde sayılmaz; üyeler şikâyet edebilir. Sunucu gelince sayılacak.
3. Şoför zaman olarak çakışan (öneri: ±2 saat) ikinci grubu üstlenemez (istemci denetimi).
4. **"Yola çıktım"**: kalkıştan en erken 15 dakika önce. O an teyit etmemiş üyeler `skipped` olur ve
   rotaya girmez (ceza yok: yakıt harcanmadı). Durak sırası hesaplanır (saf fonksiyon; en çok 8 durak
   olduğundan kuş uçuşuyla en kısa sıra denenebilir) ve `stopOrder`'a yazılır. `status=enRoute`.
   Bu sırada şoför tekli çağrı alamaz (yalnızca uygulama denetimi; `rides` kurallarına dokunulmaz).
5. Her durakta: **"Vardım"** (`arrivedAt`) → **"Aldım"** ya da, vardıktan en az 3 dakika sonra,
   **"Gelmedi"**. Harici navigasyon mevcut `driver_navigation` ile açılır.
6. Son duraktan sonra `inTrip`, varışta **"Bitir"** → `completed`. Şoföre tahsil edeceği toplam gösterilir
   (alınan kişi × kişi başı).
7. **Yarıda kalan yolculuk**: şoför her aşamada **"İptal"** diyebilir → `cancelled` (yazılmış "Gelmedi"
   kayıtları kalır). Şoför ortadan kaybolursa grup, kalkıştan 3 saat sonra kendiliğinden bitmiş sayılır
   ve üyeler serbest kalır. Grup listesi bugün kalkışı geçen grupları gizliyor; üstlenilmiş/yoldaki
   gruplar üyelerine ve şoförüne bu süre boyunca görünmeye devam etmelidir.

### 6.6 Gelmeyen yolcu (ayrı, saf kural — kapora gelince burası değişir)

- "Gelmedi" yazımı tek toplu işlemdir: `pickups/{uid}.state=noShow` + `reliability/{uid}.noShows += 1`.
  Kurallar şunları ister: yazan o grubun şoförü, grup `enRoute`, üye `confirmed`, `arrivedAt` üzerinden
  ≥3 dakika geçmiş, sayaç tam 1 artmış.
- Her 3. kayıtta `blockedUntil = şimdi + 14 gün` yazılır (kurallar zorunlu tutar). Katılma kuralı
  `blockedUntil`'e bakar; engelli kullanıcıya süre gösterilir.
- **Hesap silme (sahibinin kararı):** `reliability/{uid}` hesapla birlikte silinir. Hesabını silip yeniden
  kaydolan kişinin engelden kurtulması bilinen ve kabul edilen bir açıktır; kapora gelince önemini yitirir.
- İtiraz: yolcu mevcut şikâyet düzeniyle (`reports`) bildirir; kayıt Firebase konsolundan düzeltilir.
- Bilinen sınır: şoförün "Vardım" konumu kendi beyanıdır, doğrulanamaz. 3 dakika beklemesi ve şikâyet yolu
  kötüye kullanımı sınırlar ama engellemez. Kapora + sunucu ile çözülecek.

### 6.7 Güvenlik kuralları (özet; ayrıntı uygulayıcıda)

- Oluşturma: yeni alanlar zorunlu; `pricePerPerson` 6.2 ile eşleşmeli; kurucunun `pickups` kaydı aynı
  yazımda (`getAfter`).
- Katılma/ayrılma: yalnızca `open` iken katılma; `detours`, `extraMeters`, `pricePerPerson` tutarlı;
  sapma ≥ toplama noktasının buluşma noktasına kuş uçuşu ve ≤ sınır; `blockedUntil` geçmiş olmalı.
  `claimed` iken ayrılma: ücret alanları **değişmez**.
- Üstlenme/bırakma: yalnızca onaylı şoför; `open↔claimed`; başka alan değişmez.
- Durum geçişleri yalnızca atanmış şoför ve yalnızca ileri; `enRoute` için `departure − 15 dk` geçmiş olmalı.
- `pickups`: sahibi oluşturur/günceller (`open` iken yer, `claimed` iken yalnızca `confirmed`); şoför
  yalnızca `arrivedAt` ve `state` yazar.
- Kuş uçuşu mesafe için kurallarda `latlng.distance()` (GeoPoint) ya da sabit enlemli yaklaşık formül;
  hangisi, uygulayıcının seçimi.
- Kurallar önce `firestore-tests/rules.test.js` testleriyle doğrulanır (CLAUDE.md kuralı); canlıya yükleme
  sahibinin onayıyla.
- Tarife sabitleri artık kurallarda da durur: tarife değişince kurallar yeniden yüklenir ve eski uygulama
  sürümleri katılamaz/kuramaz olur. Kabul edilen bir bedel; `UYARILAR.md`'ye yazılır.

### 6.8 Eski veriler ve eski sürümler

- Canlıdaki eski gruplar (koordinatsız) en geç 30 günde kendiliğinden biter. Yeni sürüm bunları listede
  gösterir ama katılmaya ve üstlenmeye kapalıdır; üyeleri ayrılabilir ve sohbet edebilir.
- Eski APK'lar yeni grupları **görür** (alan adları korunuyor) ama katılamaz ve grup kuramaz (kurallar
  yeni alanları ister). Hata mesajı geneldir. `UYARILAR.md`'ye yazılır; test APK'sı yenilenir.

### 6.9 Yeni bağımlılık

Yerel bildirim için bir paket (ör. `flutter_local_notifications`) ve Android bildirim izni. Web'de
hatırlatma yok; düğme yine çalışır.

## 7. Aşamalar (her biri tek başına test edilip birleştirilebilir)

1. **Veri + ücret + toplama noktası**: model, depo (mock + firebase), kurallar, kurma/katılma ekranları.
2. **Şoför üstlenme**: "Planlı gruplar" sekmesi, üstlen/bırak, kilit, yolcu tarafında şoför bilgisi.
3. **Yolculuk günü**: teyit + yerel hatırlatma, yola çıkma, durak sırası, Vardım/Aldım, canlı konum paneli, bitirme.
4. **Güvenilirlik**: Gelmedi kaydı, engelleme, şoföre gösterim, hesap silme temizliği, belgeler.

## 8. Uygulayıcıya bırakılanlar

Dosya ve sınıf adları; ekran yerleşimi ayrıntıları (mevcut görsel dile uyarak); durak sırası algoritması;
kurallarda mesafe formülü; `trip/state` konum yazma sıklığı (mevcut `updateRidePosition` düzenine uyarak);
yerel bildirim paketi seçimi; sabitlerin (10 km, 60/15/3 dakika, 3 kayıt/14 gün, ±2 saat) tek yerde
toplanması.

## 9. Sonraki proje: kapora (bu belgenin dışında)

Ödeme sağlayıcısı + sunucu kodu + anlık bildirim. Geldiğinde: 6.2 ve 6.6 sunucuya taşınır, karar 4
yeniden ele alınır, bildirimler push'a çevrilir.
