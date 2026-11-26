# Taskbar Manager for Wireless Devices

[🇹🇷 Türkçe](README.md) | 🇬🇧 English

![Taskbar Manager for Wireless Devices](docs/screenshot.png)

*Demo mode: keyboard, headphones, mouse (low battery) and game controller*

**[⬇️ Download the latest release](https://github.com/lburak58/Taskbar-Manager-for-Wireless-Devices/releases/latest)**

A small tool that shows the battery percentage of your Bluetooth devices on the Windows taskbar, next to an icon for the device type.

## Features

- Icon by device type: headphones/speaker, mouse, keyboard, game controller, phone, pen, and a generic Bluetooth icon for unknown devices.
- Battery percentage next to the icon; single color (white) and a clean look.
- When the battery drops below 20%, a warning mark and a Windows notification appear (once per drop; if the battery rises above 20% and falls again, it warns again).
- Multi-monitor support: a separate strip is shown on each taskbar.
- If a full-screen app is open on a monitor, the strip is hidden only on that monitor.
- Hovering over the icon shows the device name and battery percentage.
- Right-click menu: Yenile (Refresh), device list, Başlangıçta çalıştır (Run at startup), Çıkış (Exit).
- Information is refreshed every 60 seconds.
- No installation required; it consists of just two files.
- 
## Installation and usage

1. Download the `.zip` file from the [latest release page](https://github.com/lburak58/Taskbar-Manager-for-Wireless-Devices/releases/latest) and extract it (or clone the repository). Put the `TaskbarManagerForWirelessDevices` folder wherever you like.
2. Double-click the `Start.vbs` file in the folder. No console window opens; the strip appears on the taskbar.

From the command line:

```
wscript "...\TaskbarManagerForWirelessDevices\Start.vbs"
```

Demo mode with fake devices:

```
wscript "...\TaskbarManagerForWirelessDevices\Start.vbs" -Demo
```

Use `Start.vbs` instead of running the `.ps1` file directly. Windows' default execution policy may prevent downloaded scripts from running; `Start.vbs` starts PowerShell with `-ExecutionPolicy Bypass` and a hidden window for this purpose.

Alternatively, you can start it manually from PowerShell:

```
powershell -ExecutionPolicy Bypass -STA -File "...\TaskbarManagerForWirelessDevices\TaskbarManagerForWirelessDevices.ps1"
```

## Run automatically at startup

Right-click the strip and check **Başlangıçta çalıştır** (Run at startup). This adds an entry to the `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` key in your user account's registry; administrator permission is not required.

If you move the folder elsewhere, turn the option off and on again. If the startup entry exists, the app updates the path automatically each time it starts.

## Uninstall

1. Turn off **Başlangıçta çalıştır** (Run at startup) in the right-click menu.
2. Close the app with **Çıkış** (Exit).
3. Delete the folder.

## Limitations

- Only Bluetooth devices that report their battery level to Windows are shown (`DEVPKEY_Bluetooth_Battery`). Some devices do not provide this information; they do not appear in the list.
- If the taskbar is vertical or set to auto-hide, the strip is hidden.
- If there is no suitable device, a faded Bluetooth icon remains on the strip (to give access to the menu).

## Troubleshooting

- **The strip is not visible:** Make sure the taskbar is at the bottom and always visible, and that no full-screen app is open on the screen. Close the app and restart it with `Start.vbs`.
- **My device is not shown:** Check whether the device's battery percentage is shown in Windows Settings > Bluetooth & devices. If it is not there, this tool cannot show it either. If it is, try **Yenile** (Refresh) from the right-click menu.
- **The app does not start:** Only one copy runs at a time. If it is already running, look for the strip on the taskbar, or end the `powershell.exe` process in Task Manager and try again.
- **Icons appear as squares:** Check that the Segoe Fluent Icons or Segoe MDL2 Assets font is installed.

## License

This project is licensed under the [MIT License](LICENSE).
