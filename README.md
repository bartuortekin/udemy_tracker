# Udemy Course Tracker

Flutter ile geliştirilen, çevrim içi kurslar için kişisel öğrenme ve çalışma takip uygulaması.

**2026–2027 Güz Dönemi — Mobile Programming Dersi Projesi**  
**Geliştirici ve proje yürütücüsü:** Bartu Örtekin

## Amaç

Kullanıcının takip ettiği kursları, çalışma sürelerini ve öğrenme hedeflerini tek bir uygulamada yönetmesini sağlamak.

Uygulama; günlük çalışma yükünü planlamayı, kurs ilerlemesini takip etmeyi ve çalışma geçmişini değerlendirmeyi amaçlar.

## Özellikler

- Kurs ekleme ve kursları listeleme
- Kurs ilerlemesini takip etme
- Günlük çalışma planı oluşturma
- Çalışma oturumlarını ve sürelerini kaydetme
- Çalışma geçmişini görüntüleme
- Günlük çalışma kapasitesini değerlendirme
- Hedef bitiş tarihi belirleme
- İstatistikler ve Bugün ekranı
- Hive ile yerel veri saklama

## Ekranlar

| Ekran           | Açıklama                                                     |
| --------------- | ------------------------------------------------------------ |
| Add Course      | Yeni kurs bilgilerinin girilmesi                             |
| Course List     | Kursların ve ilerleme durumlarının listelenmesi              |
| Planner         | Çalışma hedeflerinin ve günlük kapasitenin değerlendirilmesi |
| Study Session   | Çalışma oturumunun yürütülmesi ve kaydedilmesi               |
| Stats           | Çalışma ve ilerleme istatistiklerinin görüntülenmesi         |
| Today Dashboard | Günlük çalışma durumunun özetlenmesi                         |

## Kullanılan Teknolojiler

- Flutter
- Dart
- Hive
- Git ve GitHub

Öncelikli hedef platform Android'dir.

## Kurulum ve Çalıştırma

Bilgisayarınızda Flutter SDK ve Android geliştirme ortamının kurulu olması gerekir.

1. Bu depoyu bilgisayarınıza klonlayın.
2. Proje klasörünü terminalde açın.
3. Bağımlılıkları yükleyin:

```bash
flutter pub get
```

4. Bir Android emülatörü başlatın veya USB hata ayıklaması açık bir Android cihaz bağlayın.
5. Uygulamayı çalıştırın:

```bash
flutter run
```

Geliştirme ortamını kontrol etmek için:

```bash
flutter doctor
```

## Kod Analizi ve Testler

Statik kod analizini çalıştırmak için:

```bash
flutter analyze
```

Otomatik testleri çalıştırmak için:

```bash
flutter test
```

Bu komutlar mevcut sürümün doğrulanması için kullanılmalıdır.

## Android APK Oluşturma

```bash
flutter build apk --release
```

Oluşturulan APK dosyası:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Veri Saklama

Mevcut prototip, kurs ve çalışma verilerini cihaz üzerinde Hive ile saklar.

Ders yönergesindeki SQLite veya uzak sunucu depolama şartını karşılamak amacıyla SQLite'a geçiş planlanmaktadır. SQLite geçişi henüz tamamlanmamıştır.

Temel kullanım için Udemy hesabına giriş yapılması gerekmez. Kurs bilgileri kullanıcı tarafından elle girilir.

## Geliştirme Planı

- [ ] Mevcut kullanıcı akışlarının teslim sürümünde doğrulanması
- [ ] SQLite veri katmanının oluşturulması
- [ ] Mevcut Hive verilerinin SQLite'a taşınması
- [ ] Veri kalıcılığı ve süre hesaplamalarının test edilmesi
- [ ] Android cihaz üzerinde kullanılabilirlik kontrolleri
- [ ] Haftalık ilerleme raporlarının hazırlanması
- [ ] Tanıtım videosu veya blog yazısının hazırlanması
- [ ] Nihai rapor ve final sunum videosunun hazırlanması

## Proje Organizasyonu

Proje tek kişilik ekip tarafından yürütülmektedir.

| Rol                               | Sorumlu       |
| --------------------------------- | ------------- |
| Proje yönetimi                    | Bartu Örtekin |
| Mobil uygulama geliştirme         | Bartu Örtekin |
| Veri yönetimi                     | Bartu Örtekin |
| Test ve kalite kontrol            | Bartu Örtekin |
| Dokümantasyon ve halkla ilişkiler | Bartu Örtekin |

İlerleme; GitHub commit geçmişi, görev kayıtları ve haftalık raporlar üzerinden takip edilecektir.

## Kapsam

Bu uygulama bağımsız bir kişisel takip aracıdır. Udemy ile resmi bir bağlantısı bulunmamaktadır.

Udemy API entegrasyonu, otomatik video izleme takibi, ödeme sistemi ve bulut senkronizasyonu mevcut proje kapsamına dahil değildir.
