<#
.SYNOPSIS
  Taskbar Manager for Wireless Devices: Bluetooth cihaz pil yüzdelerini görev çubuğunda, cihaz türü simgesinin yanında yazılı olarak gösterir.
.PARAMETER Demo
  Sahte 4 cihazla çalışır (test için).
.PARAMETER LibOnly
  Yalnızca fonksiyonları tanımlar, arayüzü başlatmaz (test için; dot-source ile kullanın).
.PARAMETER RefreshSeconds
  Yenileme aralığı (varsayılan 60 sn; test için küçültülebilir).
#>
param(
    [switch]$Demo,
    [switch]$LibOnly,
    [double]$RefreshSeconds = 60
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ('BataryaNative' -as [type]) -or -not ('BataryaStrip' -as [type])) {
    Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;

public static class BataryaNative {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [StructLayout(LayoutKind.Sequential)] public struct SIZE { public int CX, CY; }
    [StructLayout(LayoutKind.Sequential)] public struct BLENDFUNCTION { public byte BlendOp, BlendFlags, SourceConstantAlpha, AlphaFormat; }
    [StructLayout(LayoutKind.Sequential)] public struct MONITORINFO { public int cbSize; public RECT rcMonitor; public RECT rcWork; public int dwFlags; }

    [DllImport("user32.dll")] public static extern bool DestroyIcon(IntPtr h);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindow(string c, string t);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr FindWindowEx(IntPtr p, IntPtr a, string c, string t);
    [DllImport("user32.dll")] static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern int GetWindowLong(IntPtr h, int i);
    [DllImport("user32.dll")] static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder sb, int n);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] static extern IntPtr MonitorFromWindow(IntPtr h, uint f);
    [DllImport("user32.dll")] static extern bool GetMonitorInfo(IntPtr m, ref MONITORINFO mi);
    [DllImport("user32.dll")] public static extern IntPtr GetDC(IntPtr h);
    [DllImport("user32.dll")] public static extern int ReleaseDC(IntPtr h, IntPtr dc);
    [DllImport("user32.dll")] public static extern int GetGuiResources(IntPtr proc, int flags);
    [DllImport("gdi32.dll")] public static extern IntPtr CreateCompatibleDC(IntPtr dc);
    [DllImport("gdi32.dll")] public static extern bool DeleteDC(IntPtr dc);
    [DllImport("gdi32.dll")] public static extern IntPtr SelectObject(IntPtr dc, IntPtr o);
    [DllImport("gdi32.dll")] public static extern bool DeleteObject(IntPtr o);
    [DllImport("user32.dll")] public static extern bool UpdateLayeredWindow(IntPtr h, IntPtr dst, ref POINT pd, ref SIZE sz,
        IntPtr src, ref POINT ps, int key, ref BLENDFUNCTION bf, int flags);

    static Rectangle ToRect(RECT r) { return Rectangle.FromLTRB(r.Left, r.Top, r.Right, r.Bottom); }

    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] static extern bool SetProcessDpiAwarenessContext(IntPtr ctx);
    [DllImport("shcore.dll")] static extern int GetDpiForMonitor(IntPtr mon, int type, out uint dx, out uint dy);

    // Bir görev çubuğu: dikdörtgen, bildirim alanı (ya da saat için ayrılan pay), monitör, DPI ölçeği.
    public class TaskbarInfo {
        public IntPtr Hwnd; public bool Primary, Topmost, Fullscreen;
        public Rectangle Bounds, Notify, Monitor;
        public int LeftLimit;     // şerit bunun soluna taşmamalı (uygulama düğmeleri)
        public float Scale;
    }

    // Monitör başına DPI (PerMonitorV2 farkındalığıyla fiziksel koordinatlar).
    public static void EnableDpiAwareness() {
        try { if (SetProcessDpiAwarenessContext((IntPtr)(-4))) return; } catch (Exception) { }
        SetProcessDPIAware();
    }

    public static float MonitorScale(IntPtr hwnd) {
        try {
            uint dx, dy;
            IntPtr mon = MonitorFromWindow(hwnd, 2);
            if (mon != IntPtr.Zero && GetDpiForMonitor(mon, 0, out dx, out dy) == 0 && dx > 0) return dx / 96f;
        } catch (Exception) { }
        using (Graphics g = Graphics.FromHwnd(IntPtr.Zero)) return g.DpiX / 96f;
    }

    // Şeridin sol-üst noktası: bildirim alanının (ya da saat payının) soluna, çubuğa dikey ortalı.
    public static Point StripPoint(Rectangle tb, Rectangle nf, int w, int h, int gap) {
        return new Point(nf.Left - w - gap, tb.Top + (tb.Height - h) / 2);
    }

    static TaskbarInfo Describe(IntPtr tray, bool primary, IntPtr fsMon) {
        if (tray == IntPtr.Zero || !IsWindowVisible(tray)) return null;
        RECT r;
        if (!GetWindowRect(tray, out r)) return null;
        TaskbarInfo ti = new TaskbarInfo();
        ti.Hwnd = tray; ti.Primary = primary;
        ti.Bounds = ToRect(r);
        ti.Topmost = (GetWindowLong(tray, -20) & 0x8) != 0;
        ti.Scale = MonitorScale(tray);
        IntPtr mon = MonitorFromWindow(tray, 2);
        MONITORINFO mi = new MONITORINFO(); mi.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
        ti.Monitor = (mon != IntPtr.Zero && GetMonitorInfo(mon, ref mi)) ? ToRect(mi.rcMonitor) : ti.Bounds;
        ti.Fullscreen = fsMon != IntPtr.Zero && fsMon == mon;
        ti.LeftLimit = ti.Bounds.Left;
        RECT n;
        if (primary) {
            IntPtr nw = FindWindowEx(tray, IntPtr.Zero, "TrayNotifyWnd", null);
            if (nw != IntPtr.Zero && GetWindowRect(nw, out n) && n.Right > n.Left) ti.Notify = ToRect(n);
            else ti.Notify = new Rectangle(ti.Bounds.Right - 200, ti.Bounds.Top, 200, ti.Bounds.Height);
        } else {
            // İkincil çubukta (Win11) saat XAML ile çizilir, alt pencere yoktur: sağdan saat payı bırak.
            IntPtr nw = FindWindowEx(tray, IntPtr.Zero, "TrayNotifyWnd", null);
            if (nw == IntPtr.Zero) nw = FindWindowEx(tray, IntPtr.Zero, "ClockButton", null);
            if (nw != IntPtr.Zero && GetWindowRect(nw, out n) && n.Right > n.Left) ti.Notify = ToRect(n);
            else { int pay = (int)Math.Round(110 * ti.Scale); ti.Notify = new Rectangle(ti.Bounds.Right - pay, ti.Bounds.Top, pay, ti.Bounds.Height); }
            IntPtr tl = FindWindowEx(tray, IntPtr.Zero, "MSTaskListWClass", null);
            if (tl != IntPtr.Zero && GetWindowRect(tl, out n) && n.Right > n.Left) ti.LeftLimit = Math.Max(ti.LeftLimit, n.Right);
        }
        return ti;
    }

    // Tüm görev çubukları: ana (Shell_TrayWnd) + her ikincil (Shell_SecondaryTrayWnd).
    public static List<TaskbarInfo> GetTaskbars() {
        List<TaskbarInfo> list = new List<TaskbarInfo>();
        IntPtr fsMon = FullscreenMonitor();
        TaskbarInfo p = Describe(FindWindow("Shell_TrayWnd", null), true, fsMon);
        if (p != null) list.Add(p);
        List<IntPtr> secs = new List<IntPtr>();
        EnumWindows(delegate(IntPtr h, IntPtr l) {
            StringBuilder sb = new StringBuilder(64);
            GetClassName(h, sb, 64);
            if (sb.ToString() == "Shell_SecondaryTrayWnd") secs.Add(h);
            return true;
        }, IntPtr.Zero);
        foreach (IntPtr h in secs) { TaskbarInfo s = Describe(h, false, fsMon); if (s != null) list.Add(s); }
        return list;
    }

    // Ön plandaki pencere (masaüstü/görev çubuğu hariç) bir monitörü tamamen kaplıyorsa true.
    // Dönüş: tam ekran uygulamanın monitörü (yoksa Zero); her şerit kendi monitörüyle karşılaştırır.
    public static IntPtr FullscreenMonitor() {
        IntPtr fg = GetForegroundWindow();
        if (fg == IntPtr.Zero) return IntPtr.Zero;
        StringBuilder sb = new StringBuilder(64);
        GetClassName(fg, sb, 64);
        string c = sb.ToString();
        if (c == "Progman" || c == "WorkerW" || c == "Shell_TrayWnd" || c == "Shell_SecondaryTrayWnd") return IntPtr.Zero;
        RECT r;
        if (!GetWindowRect(fg, out r)) return IntPtr.Zero;
        MONITORINFO mi = new MONITORINFO();
        mi.cbSize = Marshal.SizeOf(typeof(MONITORINFO));
        IntPtr mon = MonitorFromWindow(fg, 2);
        if (mon == IntPtr.Zero || !GetMonitorInfo(mon, ref mi)) return IntPtr.Zero;
        bool full = r.Left <= mi.rcMonitor.Left && r.Top <= mi.rcMonitor.Top &&
                    r.Right >= mi.rcMonitor.Right && r.Bottom >= mi.rcMonitor.Bottom;
        return full ? mon : IntPtr.Zero;
    }
}

// Görev çubuğunun üstünde, bildirim alanının soluna oturan, odak almayan şerit pencere.
// Piksel başına alfa (UpdateLayeredWindow) kullanır: arka plan görünmez ama fare tıklamasını yakalar.
public class BataryaStrip : Form {
    public string IconFontName = "Segoe MDL2 Assets";
    public string TextFontName = "Segoe UI";
    public ContextMenuStrip TrayMenu;
    public bool Dim;   // cihaz yokken soluk glif

    List<string> _gl = new List<string>(), _tx = new List<string>(), _tips = new List<string>();
    List<bool> _low = new List<bool>();
    List<string> _pt = new List<string>(); List<Font> _pf = new List<Font>(); List<Point> _pp = new List<Point>();
    List<Font> _own = new List<Font>();   // glif basina olculmus yazi tipleri (bize ait)
    Dictionary<string, int[]> _inkCache = new Dictionary<string, int[]>();
    List<Rectangle> _items = new List<Rectangle>();
    Font _ft;
    ToolTip _tt = new ToolTip();
    bool _dirty = true, _relayout = true, _shown;
    int _w, _h, _laidH; float _laidScale;
    Point _pos; int _hover = -1;

    public BataryaStrip() {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        _tt.ShowAlways = true;   // odak almayan (NOACTIVATE) formda da gorunsun
    }

    protected override bool ShowWithoutActivation { get { return true; } }
    protected override CreateParams CreateParams {
        get {
            CreateParams cp = base.CreateParams;
            // TOOLWINDOW | NOACTIVATE | LAYERED | TOPMOST
            cp.ExStyle |= 0x80 | 0x08000000 | 0x80000 | 0x8;
            return cp;
        }
    }
    protected override void WndProc(ref Message m) {
        if (m.Msg == 0x21) { m.Result = (IntPtr)3; return; }   // WM_MOUSEACTIVATE -> MA_NOACTIVATE
        base.WndProc(ref m);
    }

    public int ItemCount { get { return _gl.Count; } }
    public bool IsShown { get { return _shown; } }
    public Rectangle Bounds2 { get { return new Rectangle(_pos, new Size(_w, _h)); } }

    public void SetItems(string[] glyphs, string[] texts, bool[] low, string[] tips) {
        _gl.Clear(); _tx.Clear(); _low.Clear(); _tips.Clear();
        for (int i = 0; i < glyphs.Length; i++) { _gl.Add(glyphs[i]); _tx.Add(texts[i]); _low.Add(low[i]); _tips.Add(tips[i]); }
        _relayout = true; _dirty = true; _hover = -1;
    }

    void DisposeFonts() {
        if (_ft != null) { _ft.Dispose(); _ft = null; }
        foreach (Font f in _own) f.Dispose();
        _own.Clear();
    }

    // Metnin gercek murekkep kutusu: {sol, ust, sag, alt} (sag/alt dahil degil), cizim orijinine gore.
    int[] Ink(string str, Font f) {
        string key = f.Name + "|" + f.Size.ToString("F2") + "|" + str;
        int[] r;
        if (_inkCache.TryGetValue(key, out r)) return r;
        int org = (int)f.Size + 4, n = (int)(f.Size * 3) + 8;
        int x0 = int.MaxValue, y0 = int.MaxValue, x1 = -1, y1 = -1;
        using (Bitmap bmp = new Bitmap(n, n, PixelFormat.Format32bppArgb)) {
            using (Graphics g = Graphics.FromImage(bmp))
            using (StringFormat sf = new StringFormat(StringFormat.GenericTypographic)) {
                g.Clear(Color.Transparent);
                g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
                sf.FormatFlags |= StringFormatFlags.NoWrap;
                g.DrawString(str, f, Brushes.White, (float)org, (float)org, sf);
            }
            BitmapData d = bmp.LockBits(new Rectangle(0, 0, n, n), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try {
                byte[] px = new byte[d.Stride * n];
                System.Runtime.InteropServices.Marshal.Copy(d.Scan0, px, 0, px.Length);
                for (int y = 0; y < n; y++)
                    for (int x = 0; x < n; x++)
                        if (px[y * d.Stride + x * 4 + 3] >= 140) {
                            if (x < x0) x0 = x; if (x > x1) x1 = x;
                            if (y < y0) y0 = y; if (y > y1) y1 = y;
                        }
            } finally { bmp.UnlockBits(d); }
        }
        r = (x1 < 0) ? new int[] { 0, 0, 0, 0 } : new int[] { x0 - org, y0 - org, x1 + 1 - org, y1 + 1 - org };
        _inkCache[key] = r;
        return r;
    }

    int _boxW, _boxH;   // tum glifler icin ortak kutu: oyun kumandasinin cizilmis murekkep kutusu
    float _mouseH;

    // Glif icin, murekkebi (w x h) kutusuna sigan (en-boy orani korunur) en buyuk 0.5px'lik font boyutu.
    Font FitGlyph(string g, float maxW, float maxH) {
        int[] b;
        using (Font bf = new Font(IconFontName, 40f, FontStyle.Regular, GraphicsUnit.Pixel)) b = Ink(g, bf);
        int bw = b[2] - b[0], bh = b[3] - b[1];
        float fs = 15f;
        if (bw > 0 && bh > 0) fs = (float)Math.Round(40f * Math.Min(maxW / bw, maxH / bh) * 2f) / 2f;
        while (true) {
            Font f = new Font(IconFontName, fs, FontStyle.Regular, GraphicsUnit.Pixel);
            int[] k = Ink(g, f);
            if ((k[2] - k[0] <= maxW && k[3] - k[1] <= maxH) || fs <= 6f) return f;
            f.Dispose(); fs -= 0.5f;
        }
    }

    // Glifi ortak kutuya yatayda ortalayarak yerlestirir; dikey merkezi satir ortasinda. Donus: kutunun sag kenari.
    int AddGlyph(string g, int x, int h) {
        bool big = (g == "\uE962");   // mouse: kumanda kutusundan muaf, ~16px*DPI yukseklik
        Font gf = big ? FitGlyph(g, 1000f, _mouseH) : FitGlyph(g, _boxW, _boxH);
        _own.Add(gf);
        int[] k = Ink(g, gf);
        int iw = k[2] - k[0];
        int bx = big ? iw : _boxW;
        int ox = x + (int)Math.Round((bx - iw) / 2.0) - k[0];
        int oy = (int)Math.Floor(_lineH / 2.0 - (k[1] + k[3]) / 2.0);
        _pt.Add(g); _pf.Add(gf); _pp.Add(new Point(ox, oy));
        return x + bx;
    }

    int _lineH;

    void Relayout(float s, int h) {
        DisposeFonts();
        _lineH = h;
        _ft = new Font(TextFontName, 16f * s, FontStyle.Regular, GraphicsUnit.Pixel);
        int pad = (int)Math.Round(6 * s), gIcon = (int)Math.Round(5 * s), gWarn = (int)Math.Round(3 * s), gItem = (int)Math.Round(14 * s);
        _mouseH = 16f * s;
        // Kutu: oyun kumandasi 19px*DPI genislige sigdirilinca cizilen murekkep kutusu.
        using (Font gp = FitGlyph("\uE7FC", 19f * s, 1000f)) {
            int[] kg = Ink("\uE7FC", gp);
            _boxW = kg[2] - kg[0]; _boxH = kg[3] - kg[1];
        }
        _pt.Clear(); _pf.Clear(); _pp.Clear(); _items.Clear();
        // Metin dikey konumu: rakamlarin (cap yuksekligi) murekkep merkezi satir ortasinda.
        int[] dig = Ink("0", _ft);
        int textY = (int)Math.Round(h / 2.0 - (dig[1] + dig[3]) / 2.0);
        int x = pad;
        using (Bitmap tb = new Bitmap(1, 1))
        using (Graphics mg = Graphics.FromImage(tb))
        using (StringFormat sf = new StringFormat(StringFormat.GenericTypographic)) {
            mg.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            for (int i = 0; i < _gl.Count; i++) {
                int x0 = x;
                x = AddGlyph(_gl[i], x, h);
                if (_tx[i].Length > 0) {
                    x += gIcon;
                    int wt = (int)Math.Ceiling(mg.MeasureString(_tx[i], _ft, 10000, sf).Width);
                    _pt.Add(_tx[i]); _pf.Add(_ft); _pp.Add(new Point(x, textY)); x += wt;
                }
                if (_low[i]) {
                    x += gWarn;
                    x = AddGlyph("\uE7BA", x, h);
                }
                _items.Add(new Rectangle(x0 - gItem / 2, 0, x - x0 + gItem, h));
                x += gItem;
            }
        }
        _w = Math.Max(1, x - gItem + pad);
        _h = h; _laidH = h; _laidScale = s; _relayout = false; _dirty = true;
    }

    void Render() {
        IntPtr hwnd = Handle;
        using (Bitmap bmp = new Bitmap(_w, _h, PixelFormat.Format32bppArgb))
        using (Graphics g = Graphics.FromImage(bmp)) {
            g.Clear(Color.FromArgb(1, 0, 0, 0));
            g.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
            using (Brush b = new SolidBrush(Color.FromArgb(Dim ? 110 : 255, Color.White)))
            using (StringFormat sf = new StringFormat(StringFormat.GenericTypographic)) {
                sf.FormatFlags |= StringFormatFlags.NoWrap;
                for (int i = 0; i < _pt.Count; i++)
                    g.DrawString(_pt[i], _pf[i], b, (float)_pp[i].X, (float)_pp[i].Y, sf);
            }
            IntPtr hBmp = bmp.GetHbitmap(Color.FromArgb(0));
            IntPtr sdc = BataryaNative.GetDC(IntPtr.Zero);
            IntPtr mdc = BataryaNative.CreateCompatibleDC(sdc);
            IntPtr old = BataryaNative.SelectObject(mdc, hBmp);
            try {
                BataryaNative.POINT pd = new BataryaNative.POINT(); pd.X = _pos.X; pd.Y = _pos.Y;
                BataryaNative.POINT ps = new BataryaNative.POINT();
                BataryaNative.SIZE sz = new BataryaNative.SIZE(); sz.CX = _w; sz.CY = _h;
                BataryaNative.BLENDFUNCTION bf = new BataryaNative.BLENDFUNCTION();
                bf.BlendOp = 0; bf.BlendFlags = 0; bf.SourceConstantAlpha = 255; bf.AlphaFormat = 1;
                BataryaNative.UpdateLayeredWindow(hwnd, sdc, ref pd, ref sz, mdc, ref ps, 0, ref bf, 2);
            } finally {
                BataryaNative.SelectObject(mdc, old);
                BataryaNative.DeleteObject(hBmp);
                BataryaNative.DeleteDC(mdc);
                BataryaNative.ReleaseDC(IntPtr.Zero, sdc);
            }
        }
        _dirty = false;
    }

    void HideStrip() {
        _tt.Hide(this); _hover = -1;
        if (_shown && IsHandleCreated) BataryaNative.ShowWindow(Handle, 0);
        _shown = false;
    }

    // Periyodik çağrılır: konum, TopMost sırası, tam ekran/otomatik gizleme denetimi (bu şeridin görev çubuğu için).
    public void Reposition(BataryaNative.TaskbarInfo ti) {
        if (_gl.Count == 0) { HideStrip(); return; }
        Rectangle tb = ti.Bounds, nf = ti.Notify;
        // Dikey çubuk, otomatik gizlenmiş (ince) çubuk, bu monitörde tam ekran uygulama: şerit gizlenir.
        if (!ti.Topmost || tb.Width < tb.Height || tb.Height < 24 || ti.Fullscreen) { HideStrip(); return; }
        float s = ti.Scale;
        int h = Math.Max(20, (int)(tb.Height * 0.75));
        if (_relayout || h != _laidH || Math.Abs(s - _laidScale) > 0.01f) Relayout(s, h);
        int gap = (int)Math.Round(4 * s);
        Point p = BataryaNative.StripPoint(tb, nf, _w, _h, gap);
        if (p.X < ti.LeftLimit) { HideStrip(); return; }
        if (p != _pos) { _pos = p; _dirty = true; }
        IntPtr hwnd = Handle;
        if (_dirty) Render();
        // SWP_NOMOVE|NOSIZE|NOACTIVATE|SHOWWINDOW, HWND_TOPMOST: Explorer'ın üstüne tekrar yerleş.
        BataryaNative.SetWindowPos(hwnd, (IntPtr)(-1), 0, 0, 0, 0, 0x0002 | 0x0001 | 0x0010 | 0x0040);
        _shown = true;
    }

    protected override void OnMouseMove(MouseEventArgs e) {
        base.OnMouseMove(e);
        int idx = -1;
        for (int i = 0; i < _items.Count; i++) if (_items[i].Contains(e.Location)) { idx = i; break; }
        if (idx != _hover) {
            _hover = idx;
            _tt.Hide(this);
            // Seridin hemen ustunde goster (cubuk altta oldugu icin asagi tasar).
            if (idx >= 0) _tt.Show(_tips[idx], this, _items[idx].Left, -(Height * 3 / 4), 15000);
        }
    }
    protected override void OnMouseLeave(EventArgs e) { base.OnMouseLeave(e); _hover = -1; _tt.Hide(this); }
    protected override void OnMouseUp(MouseEventArgs e) {
        base.OnMouseUp(e);
        if (e.Button == MouseButtons.Right && TrayMenu != null) {
            BataryaNative.SetForegroundWindow(Handle);   // menü dışına tıklayınca kapanması için
            TrayMenu.Show(this, e.Location);
        }
    }

    protected override void Dispose(bool disposing) {
        if (disposing) { DisposeFonts(); _tt.Dispose(); }
        base.Dispose(disposing);
    }
}
'@
}

$script:AppName   = 'Taskbar Manager for Wireless Devices'
$script:LegacyAppName = 'BataryaTepsi'   # eski Run kaydı adı (bir kerelik geçiş için)
$script:RunKey    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$script:LowLimit  = 20
$script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---------------------------------------------------------------- Tür tespiti
# Dönüş: Audio | Mouse | Keyboard | Gamepad | Phone | Pen | Unknown
# Önce ada bakılır (en belirgin), sonra PnP Class'a. Arka plan runspace'inde de kullanıldığı
# için kaynak metin olarak tutulur ve hem burada hem sorgu betiğinde tanımlanır.
$script:KindSrc = @'
function Get-DeviceKind {
    param([string]$Name, [string]$Class)
    $n = if ($Name)  { $Name.ToLowerInvariant() }  else { '' }
    $c = if ($Class) { $Class.ToLowerInvariant() } else { '' }

    # 1) Ad anahtar kelimeleri
    if ($n -match 'controller|gamepad|joystick|xbox|dualshock|dualsense|kumanda') { return 'Gamepad' }
    if ($n -match 'headphone|headset|earbud|earphone|buds|airpods|speaker|soundbar|kulakl|hoparl') { return 'Audio' }
    if ($n -match 'mouse|\bfare\b|trackpad|trackball') { return 'Mouse' }
    if ($n -match 'keyboard|klavye|keypad') { return 'Keyboard' }
    if ($n -match 'phone|telefon|iphone|android|galaxy|pixel') { return 'Phone' }
    if ($n -match '\bpen\b|stylus|kalem') { return 'Pen' }

    # 2) PnP Class
    switch -Regex ($c) {
        '^(audioendpoint|media)$' { return 'Audio' }
        '^mouse$'                 { return 'Mouse' }
        '^keyboard$'              { return 'Keyboard' }
    }
    return 'Unknown'   # HIDClass dahil: ad ipucu vermiyorsa genel Bluetooth simgesi
}
'@
. ([scriptblock]::Create($script:KindSrc))

# Tür -> Segoe Fluent Icons / MDL2 glifi
function Get-KindGlyph {
    param([string]$Kind)
    $code = switch ($Kind) {
        'Audio'    { 0xE7F6 }
        'Mouse'    { 0xE962 }
        'Keyboard' { 0xE765 }
        'Gamepad'  { 0xE7FC }
        'Phone'    { 0xE8EA }
        'Pen'      { 0xEDC6 }
        default    { 0xE702 }
    }
    return [string][char]$code
}

# ---------------------------------------------------------------- Cihaz sorgusu
# Arka plan runspace'inde de çalışır; bu yüzden kendi içinde bağımsızdır.
$script:QueryBody = @'
    if ($Demo) {
        $demoList = @(
            @('Kulaklık',         85, 'AudioEndpoint'),
            @('Mouse',            18, 'Mouse'),
            @('Klavye',           50, 'Keyboard'),
            @('Xbox Controller',  62, 'HIDClass')
        )
        return @($demoList | ForEach-Object {
            [pscustomobject]@{ Name = $_[0]; Percent = $_[1]; Class = $_[2]; Kind = (Get-DeviceKind $_[0] $_[2]) }
        })
    }
    $key = '{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2'
    $seen = @{}
    $result = New-Object System.Collections.ArrayList
    try {
        # Önce yalnızca Bluetooth düğümleri; sonra sadece bunlara özellik sorgusu.
        $devs = @(Get-PnpDevice -PresentOnly -ErrorAction Stop |
            Where-Object { $_.InstanceId -match 'BTH|BTHLE|BTHENUM' -and $_.FriendlyName })
        foreach ($d in $devs) {
            if ($seen.ContainsKey($d.FriendlyName)) { continue }
            try {
                $p = Get-PnpDeviceProperty -InstanceId $d.InstanceId -KeyName $key -ErrorAction Stop
                if ($null -ne $p -and $null -ne $p.Data) {
                    $v = [int]$p.Data
                    if ($v -ge 0 -and $v -le 100) {
                        $seen[$d.FriendlyName] = $true
                        [void]$result.Add([pscustomobject]@{
                            Name = [string]$d.FriendlyName; Percent = $v; Class = [string]$d.Class
                            Kind = (Get-DeviceKind ([string]$d.FriendlyName) ([string]$d.Class)) })
                    }
                }
            } catch { }
        }
    } catch { }
    return @($result)
'@
$script:QueryScript = "param([bool]`$Demo)`n" + $script:KindSrc + "`n" + $script:QueryBody

function Get-BtBatteryDevices {
    param([switch]$Demo)
    @(& ([scriptblock]::Create($script:QueryScript)) $Demo.IsPresent)
}

# ---------------------------------------------------------------- Tema ve simge
function Get-IconFontName {
    $fc = New-Object System.Drawing.Text.InstalledFontCollection
    try {
        $names = @($fc.Families | ForEach-Object { $_.Name })
    } finally { $fc.Dispose() }
    foreach ($f in 'Segoe Fluent Icons', 'Segoe MDL2 Assets') { if ($names -contains $f) { return $f } }
    return 'Segoe UI Symbol'
}

# ---------------------------------------------------------------- Bildirim (toast)
$script:ToastAppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
$script:LastToastError = $null
$script:Fallbacks = New-Object System.Collections.ArrayList

function Remove-FallbackNotice {
    param($Pair)
    try { $Pair.Timer.Stop(); $Pair.Timer.Dispose() } catch { }
    try { $Pair.Icon.Visible = $false; $Pair.Icon.Dispose() } catch { }
    $script:Fallbacks.Remove($Pair)
}

# Windows toast; olmazsa gecici NotifyIcon balonu (10 sn sonra kaldirilir). Donus: 'toast' | 'fallback'
function Show-LowBatteryNotice {
    param([string]$Title, [string]$Message)
    try {
        [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        $t = [System.Security.SecurityElement]::Escape($Title)
        $m = [System.Security.SecurityElement]::Escape($Message)
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml("<toast><visual><binding template=""ToastGeneric""><text>$t</text><text>$m</text></binding></visual></toast>")
        $toast = New-Object Windows.UI.Notifications.ToastNotification($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($script:ToastAppId).Show($toast)
        return 'toast'
    } catch {
        $script:LastToastError = $_.Exception.Message
    }
    try {
        $tmp = New-Object System.Windows.Forms.NotifyIcon
        $tmp.Icon = [System.Drawing.SystemIcons]::Warning
        $tmp.Visible = $true
        $tmp.ShowBalloonTip(5000, $Title, $Message, [System.Windows.Forms.ToolTipIcon]::Warning)
        $tm = New-Object System.Windows.Forms.Timer
        $tm.Interval = 10000
        $pair = [pscustomobject]@{ Icon = $tmp; Timer = $tm }
        $tm.Tag = $pair
        [void]$script:Fallbacks.Add($pair)
        $tm.Add_Tick({ param($s, $e) Remove-FallbackNotice $s.Tag })
        $tm.Start()
    } catch { $script:LastToastError = $_.Exception.Message }
    return 'fallback'
}

# ---------------------------------------------------------------- Başlangıç ayarı
function Get-StartupCommand {
    return ('wscript.exe "{0}"' -f (Join-Path $script:ScriptDir 'Start.vbs'))
}
function Test-StartupEnabled {
    try { return [bool](Get-ItemProperty -Path $script:RunKey -Name $script:AppName -ErrorAction Stop).($script:AppName) } catch { return $false }
}
# Run kaydı onarımı/geçişi (idempotent). Yalnızca gerçek modda, açılışta çağrılır (-Demo/-LibOnly dokunmaz):
#  - Eski ad ('BataryaTepsi') varsa silinir ve yeni ad altında GÜNCEL komut (Get-StartupCommand) yazılır.
#  - Yeni ad var ama değeri güncel komuttan farklıysa (bayat yol) güncel komutla yeniden yazılır.
#  - Ne eski ne yeni ad varsa hiçbir şey yazılmaz.
# Dönüş: $true = bir değişiklik yapıldı. Path parametreli (testte geçici anahtar kullanılır).
function Move-LegacyStartup {
    param([string]$Path = $script:RunKey, [string]$OldName = $script:LegacyAppName, [string]$NewName = $script:AppName)
    $props = $null
    try { $props = Get-ItemProperty -Path $Path -ErrorAction Stop } catch { return $false }
    $hasOld = $props.PSObject.Properties.Name -contains $OldName
    $hasNew = $props.PSObject.Properties.Name -contains $NewName
    $cmd = Get-StartupCommand
    if ($hasOld) {
        Remove-ItemProperty -Path $Path -Name $OldName -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $Path -Name $NewName -Value $cmd
        return $true
    }
    if ($hasNew -and ([string]$props.$NewName) -ne $cmd) {
        Set-ItemProperty -Path $Path -Name $NewName -Value $cmd
        return $true
    }
    return $false
}

function Set-StartupEnabled {
    param([bool]$Enable)
    if ($Enable) { Set-ItemProperty -Path $script:RunKey -Name $script:AppName -Value (Get-StartupCommand) }
    else { Remove-ItemProperty -Path $script:RunKey -Name $script:AppName -ErrorAction SilentlyContinue }
}

if ($LibOnly) { return }

# ---------------------------------------------------------------- Tek örnek
$mutexName = if ($Demo) { 'Local\TaskbarManagerForWirelessDevices_Demo' } else { 'Local\TaskbarManagerForWirelessDevices' }
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) { $mutex.Dispose(); return }

if (-not $Demo) { try { [void](Move-LegacyStartup) } catch { } }   # eski 'BataryaTepsi' kaydını taşı / bayat yolu onar (Demo'da çalışmaz)

[BataryaNative]::EnableDpiAwareness()   # pencere oluşturulmadan önce (monitör başına DPI)

# ---------------------------------------------------------------- Arayüz durumu
$script:Devices = @()
$script:Alerted = @{}
$script:Ps = $null
$script:Rs = $null   # tek, kalici arka plan runspace (her yenilemede yenisi acilmaz)
$script:Async = $null
$script:IconFont = Get-IconFontName
$script:Items = $null   # son cihaz listesinden şerit içeriği
$script:Strips = @{}      # görev çubuğu HWND -> BataryaStrip

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$pollTimer = New-Object System.Windows.Forms.Timer
$pollTimer.Interval = 300
$refreshTimer = New-Object System.Windows.Forms.Timer
$refreshTimer.Interval = [Math]::Max(50, [int]($RefreshSeconds * 1000))
$posTimer = New-Object System.Windows.Forms.Timer
$posTimer.Interval = 1000

# Şerit içeriğini bir şeride uygular.
function Set-StripContent {
    param($S)
    $it = $script:Items
    $S.Dim = $it.Dim
    $S.SetItems($it.Glyphs, $it.Texts, $it.Low, $it.Tips)
}

# Her görev çubuğu (ana + ikincil) için bir şerit tutar; eklenen/çıkarılan ekranları izler ve hepsini konumlandırır.
function Sync-Strips {
    if ($null -eq $script:Items) { return }
    $bars = [BataryaNative]::GetTaskbars()
    $live = @{}
    foreach ($ti in $bars) {
        $key = [string]$ti.Hwnd.ToInt64()
        $live[$key] = $true
        if (-not $script:Strips.ContainsKey($key)) {
            $s = New-Object BataryaStrip
            $s.IconFontName = $script:IconFont
            $s.TrayMenu = $menu
            Set-StripContent $s
            $script:Strips[$key] = $s
        }
        $script:Strips[$key].Reposition($ti)
    }
    foreach ($k in @($script:Strips.Keys)) {
        if (-not $live.ContainsKey($k)) { $script:Strips[$k].Dispose(); $script:Strips.Remove($k) }
    }
}

function Start-Refresh {
    if ($null -ne $script:Async -and -not $script:Async.IsCompleted) { return }
    if ($null -eq $script:Rs) { $script:Rs = [runspacefactory]::CreateRunspace(); $script:Rs.Open() }
    $script:Ps = [powershell]::Create()
    $script:Ps.Runspace = $script:Rs
    [void]$script:Ps.AddScript($script:QueryScript).AddArgument($Demo.IsPresent)
    $script:Async = $script:Ps.BeginInvoke()
    $pollTimer.Start()
}

function Stop-App {
    $pollTimer.Stop(); $refreshTimer.Stop(); $posTimer.Stop()
    [System.Windows.Forms.Application]::Exit()
}

function Update-Menu {
    $menu.Items.Clear()
    $mi = $menu.Items.Add('Yenile')
    $mi.Add_Click({ Start-Refresh })
    [void]$menu.Items.Add('-')
    if ($script:Devices.Count -eq 0) {
        $i = $menu.Items.Add('Pil bilgisi veren cihaz yok'); $i.Enabled = $false
    } else {
        foreach ($d in $script:Devices) {
            $i = $menu.Items.Add(('{0} – %{1}' -f $d.Name, $d.Percent)); $i.Enabled = $false
        }
    }
    [void]$menu.Items.Add('-')
    $st = New-Object System.Windows.Forms.ToolStripMenuItem('Başlangıçta çalıştır')
    $st.Checked = (Test-StartupEnabled)
    $st.Add_Click({ param($s, $e) Set-StartupEnabled (-not $s.Checked); $s.Checked = (Test-StartupEnabled) })
    [void]$menu.Items.Add($st)
    $ex = $menu.Items.Add('Çıkış')
    $ex.Add_Click({ Stop-App })
}

function Update-Tray {
    param($Devices)
    $script:Devices = @($Devices | Sort-Object Name)
    $n = $script:Devices.Count

    # Şerit: [tür simgesi] [NN%] ; düşük pilde yanında uyarı glifi.
    # Cihaz yokken: soluk Bluetooth glifi (menüye erişim için şerit kalır).
    if ($n -eq 0) {
        $script:Items = @{ Dim = $true; Glyphs = @([string][char]0xE702); Texts = @(''); Low = @($false); Tips = @('Pil bilgisi veren cihaz yok') }
    } else {
        $gl = New-Object 'string[]' $n; $tx = New-Object 'string[]' $n; $tp = New-Object 'string[]' $n
        $lo = New-Object 'bool[]' $n
        for ($i = 0; $i -lt $n; $i++) {
            $d = $script:Devices[$i]
            $gl[$i] = Get-KindGlyph $d.Kind
            $tx[$i] = ('{0}%' -f $d.Percent)
            $lo[$i] = ($d.Percent -lt $script:LowLimit)
            $tp[$i] = ('{0} – {1}%' -f $d.Name, $d.Percent)
        }
        $script:Items = @{ Dim = $false; Glyphs = $gl; Texts = $tx; Low = $lo; Tips = $tp }
    }
    foreach ($s in @($script:Strips.Values)) { Set-StripContent $s }   # tek veri yenilemesi tüm şeritleri günceller
    Sync-Strips

    # Düşük pil bildirimi (cihaz başına tek sefer)
    $names = @($script:Devices | ForEach-Object { $_.Name })
    foreach ($k in @($script:Alerted.Keys)) { if ($names -notcontains $k) { $script:Alerted.Remove($k) } }
    $fresh = @()
    foreach ($d in $script:Devices) {
        if ($d.Percent -lt $script:LowLimit) {
            if (-not $script:Alerted.ContainsKey($d.Name)) { $script:Alerted[$d.Name] = $true; $fresh += $d }
        } else { $script:Alerted.Remove($d.Name) }
    }
    if ($fresh.Count -gt 0) {
        $msg = ($fresh | ForEach-Object { '{0}: %{1}' -f $_.Name, $_.Percent }) -join "`n"
        [void](Show-LowBatteryNotice $script:AppName ("Düşük pil`n" + $msg))
    }
    Update-Menu
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()   # PowerShell/WinForms nesneleri: handle birikmesin
}

$pollTimer.Add_Tick({
    if ($null -ne $script:Async -and $script:Async.IsCompleted) {
        $pollTimer.Stop()
        $res = @()
        try { $res = @($script:Ps.EndInvoke($script:Async)) } catch { }
        $script:Ps.Dispose(); $script:Ps = $null; $script:Async = $null
        Update-Tray @($res | Where-Object { $_ -and $_.Name })
    }
})
$refreshTimer.Add_Tick({ Start-Refresh })
$posTimer.Add_Tick({
    try {
        Sync-Strips
    } catch { }
})

# ---------------------------------------------------------------- Başlat
try {
    Update-Tray @()          # sorgu bitene kadar soluk glif
    Start-Refresh
    $refreshTimer.Start()
    $posTimer.Start()
    [System.Windows.Forms.Application]::Run()
} finally {
    $posTimer.Stop()
    foreach ($fb in @($script:Fallbacks)) { Remove-FallbackNotice $fb }
    foreach ($s in @($script:Strips.Values)) { try { $s.Dispose() } catch { } }
    $script:Strips.Clear()
    if ($script:Ps) { try { $script:Ps.Stop(); $script:Ps.Dispose() } catch { } }
    if ($script:Rs) { try { $script:Rs.Dispose() } catch { } }
    $menu.Dispose()
    try { $mutex.ReleaseMutex() } catch { }
    $mutex.Dispose()
}
