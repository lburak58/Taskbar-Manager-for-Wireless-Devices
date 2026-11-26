# Changelog · Değişiklik Günlüğü

Bu projedeki önemli değişiklikler bu dosyada tutulur.
## [Unreleased]

## [1.1.2] - 2026-11-26

### Düzeltilen · Fixed

- macOS uygulamasının sürüm numarası artık CHANGELOG'dan alınır (önceden hep 1.0.0 görünüyordu) · The macOS app version is now taken from the CHANGELOG (it previously always showed 1.0.0)

## [1.1.1] - 2026-11-26

### Eklenen · Added

- README'lere macOS menü çubuğu ekran görüntüsü · macOS menu bar screenshot in the READMEs
- macOS: `TMWD_DEBUG=1` ayarlıyken menü çubuğu öğesinin ekrandaki konumu hata ayıklama çıktısına yazılır · macOS: with `TMWD_DEBUG=1` set, the menu bar item's on-screen position is written to the debug output

## [1.1.0] - 2026-11-26

### Eklenen · Added

- macOS sürümü (macOS 13+, Apple Silicon ve Intel): pil yüzdeleri menü çubuğunda, cihaz türü simgesinin yanında · macOS version (macOS 13+, Apple Silicon and Intel): battery percentages in the menu bar, next to a device-type icon
- macOS'ta AirPods için sol, sağ ve kutu pil düzeyleri (menü çubuğunda en düşüğü, ipucunda ayrıntı) · AirPods left, right and case battery levels on macOS (lowest in the menu bar, details in the tooltip)
- Sürüm sayfasında ayrı Windows ve macOS zip'leri · Separate Windows and macOS zips on the release page
- README'lere son sürümü indirme bağlantısı · Download link to the latest release in the READMEs
- Bu değişiklik günlüğü · This changelog

## [1.0.0] - 2026-11-26

İlk sürüm · First release

### Eklenen · Added

- Bluetooth cihazlarının pil yüzdesini Windows 11 görev çubuğunda gösteren şerit · Strip on the Windows 11 taskbar showing the battery percentage of Bluetooth devices
- Cihaz türüne göre simgeler: kulaklık/hoparlör, mouse, klavye, oyun kumandası, telefon, kalem ve genel Bluetooth simgesi · Device-type icons: headphones/speaker, mouse, keyboard, game controller, phone, pen and a generic Bluetooth icon
- %20'nin altında uyarı işareti ve Windows bildirimi · Warning mark and Windows notification below 20%
- Çok ekran desteği; tam ekran uygulama açıkken şerit yalnızca o ekranda gizlenir · Multi-monitor support; the strip hides only on the screen running a full-screen app
- Simgenin üzerine gelince cihaz adı ve pil yüzdesi · Device name and battery percentage on hover
- Sağ tık menüsü: Yenile, cihaz listesi, Başlangıçta çalıştır, Çıkış · Right-click menu: Refresh, device list, Run at startup, Exit
- 60 saniyede bir otomatik yenileme · Automatic refresh every 60 seconds
- Sahte cihazlarla deneme için `-Demo` modu · `-Demo` mode with sample devices
