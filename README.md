# Taskbar Manager for Wireless Devices

🇹🇷 Türkçe | [🇬🇧 English](README.en.md)

![Taskbar Manager for Wireless Devices](docs/screenshot.png)

*Demo modu: klavye, kulaklık, mouse (düşük pil) ve oyun kumandası*

**[⬇️ Son sürümü indir](https://github.com/lburak58/Taskbar-Manager-for-Wireless-Devices/releases/latest)**

Bluetooth cihazlarınızın pil yüzdesini Windows görev çubuğunda (Windows 11 ve macOS 13+; macOS'ta menü çubuğunda), cihaz türü simgesinin yanında gösteren küçük bir araç.

## Özellikler

- Cihaz türüne göre simge: kulaklık/hoparlör, mouse, klavye, oyun kumandası, telefon, kalem ve bilinmeyen cihazlar için genel Bluetooth simgesi.
- Simgenin yanında pil yüzdesi; tek renk (beyaz) ve sade görünüm.
- Pil %20'nin altına düşünce uyarı işareti ve Windows bildirimi (her düşüşte bir kez; pil %20'nin üstüne çıkıp yeniden düşerse tekrar uyarır).
- Çok ekran desteği: her görev çubuğunda ayrı bir şerit gösterilir.
- Bir ekranda tam ekran uygulama açıksa şerit yalnızca o ekranda gizlenir.
- Simgenin üzerine gelince cihaz adı ve pil yüzdesi görünür.
- Sağ tık menüsü: Yenile, cihaz listesi, Başlangıçta çalıştır, Çıkış.
- Bilgiler 60 saniyede bir yenilenir.
- Kurulum gerektirmez; yalnızca iki dosyadan oluşur.

## Kurulum ve çalıştırma

1. [Son sürüm sayfasından](https://github.com/lburak58/Taskbar-Manager-for-Wireless-Devices/releases/latest) Windows zip'ini (`TaskbarManagerForWirelessDevices-Windows-…zip`) indirip açın (ya da depoyu klonlayın). `TaskbarManagerForWirelessDevices` klasörünü istediğiniz yere koyun.
2. Klasördeki `Start.vbs` dosyasına çift tıklayın. Konsol penceresi açılmaz; şerit görev çubuğunda belirir.

Komut satırından:

```
wscript "...\TaskbarManagerForWirelessDevices\Start.vbs"
```

Sahte cihazlarla deneme (demo) modu:

```
wscript "...\TaskbarManagerForWirelessDevices\Start.vbs" -Demo
```

`.ps1` dosyasını doğrudan çalıştırmak yerine `Start.vbs` kullanın. Windows'un varsayılan yürütme ilkesi indirilen betiklerin çalışmasını engelleyebilir; `Start.vbs` PowerShell'i bu çalıştırma için `-ExecutionPolicy Bypass` ile ve gizli pencerede başlatır.

Alternatif olarak PowerShell'den elle başlatabilirsiniz:

```
powershell -ExecutionPolicy Bypass -STA -File "...\TaskbarManagerForWirelessDevices\TaskbarManagerForWirelessDevices.ps1"
```

## Başlangıçta otomatik çalıştırma

Şeridin üzerine sağ tıklayıp **Başlangıçta çalıştır** seçeneğini işaretleyin. Bu, kullanıcı hesabınızın kayıt defterindeki `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` anahtarına bir kayıt ekler; yönetici izni gerekmez.

Klasörü başka yere taşırsanız seçeneği kapatıp yeniden açın. Başlangıç kaydı varsa uygulama her açılışta yolu kendiliğinden günceller.

## Kaldırma

1. Sağ tık menüsünden **Başlangıçta çalıştır** seçeneğini kapatın.
2. **Çıkış** ile uygulamayı kapatın.
3. Klasörü silin.

## Kısıtlar

- Yalnızca pil düzeyini Windows'a bildiren Bluetooth cihazlar görünür (`DEVPKEY_Bluetooth_Battery`). Bazı cihazlar bu bilgiyi vermez; bunlar listede çıkmaz.
- Görev çubuğu dikey konumdaysa veya otomatik gizleniyorsa şerit gizlenir.
- Hiç uygun cihaz yoksa şeritte soluk bir Bluetooth simgesi kalır (menüye erişmek için).

## Sorun giderme

- **Şerit görünmüyor:** Görev çubuğunun altta ve her zaman görünür olduğundan, ekranda tam ekran bir uygulama açık olmadığından emin olun. Uygulamayı kapatıp `Start.vbs` ile yeniden başlatın.
- **Cihazım görünmüyor:** Windows Ayarlar > Bluetooth ve cihazlar bölümünde cihazın pil yüzdesi görünüyor mu bakın. Orada yoksa bu araç da gösteremez. Görünüyorsa sağ tık menüsünden **Yenile**'yi deneyin.
- **Uygulama açılmıyor:** Aynı anda yalnızca bir kopya çalışır. Zaten çalışıyorsa görev çubuğunda şeridi arayın veya Görev Yöneticisi'nden `powershell.exe` işlemini kapatıp tekrar deneyin.
- **Simgeler kare görünüyor:** Segoe Fluent Icons veya Segoe MDL2 Assets yazı tipinin yüklü olduğunu denetleyin.

## macOS

![Taskbar Manager for Wireless Devices – macOS](docs/screenshot-macos.png)

*Demo modu: macOS menü çubuğu*

Aynı uygulamanın macOS sürümü `macos/` klasöründedir; pil yüzdelerini menü çubuğunda gösterir.

- **Gereksinim:** macOS 13 veya üstü (Apple Silicon ve Intel).
- **İndirme:** [Son sürüm sayfasından](https://github.com/lburak58/Taskbar-Manager-for-Wireless-Devices/releases/latest) macOS zip'ini (`TaskbarManagerForWirelessDevices-macOS-…zip`) indirip açın. `Taskbar Manager for Wireless Devices.app` dosyasını Uygulamalar klasörüne taşıyın.
- **Gatekeeper uyarısı:** Uygulama Apple tarafından imzalanmamış/noter onaylı değildir (ad-hoc imza), bu yüzden macOS ilk açılışı engeller. Terminal'de şunu bir kez çalıştırın: `xattr -dr com.apple.quarantine "/Applications/Taskbar Manager for Wireless Devices.app"` — ya da uygulamayı bir kez açmayı deneyip **Sistem Ayarları > Gizlilik ve Güvenlik** bölümünde **Yine de Aç**'a basın.
- **Demo modu:** `--demo` argümanıyla ya da `TMWD_DEMO=1` ortam değişkeniyle çalıştırın.
- **Kısıtlar:** Yalnızca macOS'un pil düzeyini bildirdiği cihazlar görünür. Menüde Yenile, cihaz listesi, Başlangıçta çalıştır ve Çıkış bulunur.
- **Kaynaktan derleme:** `cd macos && swift build -c release` (ya da `scripts/build-app.sh`).

## Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır.
