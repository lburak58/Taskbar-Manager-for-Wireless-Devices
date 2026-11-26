# Taskbar Manager for Wireless Devices

Bluetooth cihazlarınızın pil yüzdesini Windows görev çubuğunda, cihaz türü simgesinin yanında gösteren küçük bir araç.

## Özellikler

- Cihaz türüne göre simge: kulaklık/hoparlör, mouse, klavye, oyun kumandası, telefon, kalem ve bilinmeyen cihazlar için genel Bluetooth simgesi.
- Simgenin yanında pil yüzdesi; tek renk (beyaz) ve sade görünüm.
- Pil %20'nin altına düşünce uyarı işareti ve Windows bildirimi (cihaz başına bir kez).
- Çok ekran desteği: her görev çubuğunda ayrı bir şerit gösterilir.
- Bir ekranda tam ekran uygulama açıksa şerit yalnızca o ekranda gizlenir.
- Simgenin üzerine gelince cihaz adı ve pil yüzdesi görünür.
- Sağ tık menüsü: Yenile, cihaz listesi, Başlangıçta çalıştır, Çıkış.
- Bilgiler 60 saniyede bir yenilenir.
- Kurulum gerektirmez; yalnızca iki dosyadan oluşur.

## Gereksinimler

- Windows 11
- Windows PowerShell 5.1 (Windows ile birlikte gelir)
- Segoe Fluent Icons veya Segoe MDL2 Assets yazı tipi (Windows ile birlikte gelir)

## Kurulum ve çalıştırma

1. Depoyu indirin (Code > Download ZIP) veya klonlayın. `TaskbarManagerForWirelessDevices` klasörünü istediğiniz yere koyun.
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
- Açık tema desteği yoktur; yazı ve simgeler her zaman beyazdır.
- Hiç uygun cihaz yoksa şeritte soluk bir Bluetooth simgesi kalır (menüye erişmek için).

## Sorun giderme

- **Şerit görünmüyor:** Görev çubuğunun altta ve her zaman görünür olduğundan, ekranda tam ekran bir uygulama açık olmadığından emin olun. Uygulamayı kapatıp `Start.vbs` ile yeniden başlatın.
- **Cihazım görünmüyor:** Windows Ayarlar > Bluetooth ve cihazlar bölümünde cihazın pil yüzdesi görünüyor mu bakın. Orada yoksa bu araç da gösteremez. Görünüyorsa sağ tık menüsünden **Yenile**'yi deneyin.
- **Uygulama açılmıyor:** Aynı anda yalnızca bir kopya çalışır. Zaten çalışıyorsa görev çubuğunda şeridi arayın veya Görev Yöneticisi'nden `powershell.exe` işlemini kapatıp tekrar deneyin.
- **Simgeler kare görünüyor:** Segoe Fluent Icons veya Segoe MDL2 Assets yazı tipinin yüklü olduğunu denetleyin.
