# Universal Copy/Paste for Windows.
# Ctrl+Alt+C copies the selection with fallbacks. Ctrl+Alt+V types clipboard text
# as keystrokes so it works in apps that block normal paste. Native Ctrl+C and
# Ctrl+V stay unchanged unless -TakeOverCtrlC or -TakeOverCtrlV is passed.

#requires -version 5.1
param(
    [switch]$StartDisabled,
    [switch]$TakeOverCtrlC,
    [switch]$TakeOverCtrlV,
    [switch]$CompileOnly
)

$ErrorActionPreference = "Stop"

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw "UniversalCopyPaste only supports Windows."
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$source = @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace KitsuneTools
{
    public static class UniversalCopyPaste
    {
        private const int WH_KEYBOARD_LL = 13;
        private const int WM_KEYDOWN = 0x0100;
        private const int WM_KEYUP = 0x0101;
        private const int WM_SYSKEYDOWN = 0x0104;
        private const int WM_SYSKEYUP = 0x0105;

        private const int VK_CONTROL = 0x11;
        private const int VK_LCONTROL = 0xA2;
        private const int VK_RCONTROL = 0xA3;
        private const int VK_SHIFT = 0x10;
        private const int VK_LSHIFT = 0xA0;
        private const int VK_RSHIFT = 0xA1;
        private const int VK_MENU = 0x12;
        private const int VK_LMENU = 0xA4;
        private const int VK_RMENU = 0xA5;
        private const int VK_C = 0x43;
        private const int VK_V = 0x56;
        private const int VK_INSERT = 0x2D;
        private const int VK_ESCAPE = 0x1B;

        private const int WM_COPY = 0x0301;

        private const uint CF_UNICODETEXT = 13;
        private const uint INPUT_KEYBOARD = 1;
        private const uint KEYEVENTF_KEYUP = 0x0002;
        private const uint KEYEVENTF_UNICODE = 0x0004;

        private static readonly LowLevelKeyboardProc Proc = HookCallback;
        private static IntPtr hookId = IntPtr.Zero;
        private static NotifyIcon trayIcon;
        private static ToolStripMenuItem enabledItem;
        private static SynchronizationContext uiContext;
        private static Mutex appMutex;
        private static volatile bool enabled = true;
        private static volatile bool takeOverCtrlC = false;
        private static volatile bool takeOverCtrlV = false;
        private static int copyRunning = 0;
        private static int pasteRunning = 0;

        public static void Run(bool startEnabled, bool shouldTakeOverCtrlC, bool shouldTakeOverCtrlV)
        {
            enabled = startEnabled;
            takeOverCtrlC = shouldTakeOverCtrlC;
            takeOverCtrlV = shouldTakeOverCtrlV;

            bool createdNew;
            appMutex = new Mutex(true, "KitsuneTools.UniversalCopyPaste", out createdNew);
            if (!createdNew)
            {
                Log("Universal Copy/Paste is already running.");
                return;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            SynchronizationContext.SetSynchronizationContext(new WindowsFormsSynchronizationContext());
            uiContext = SynchronizationContext.Current;

            hookId = SetHook(Proc);
            if (hookId == IntPtr.Zero)
            {
                throw new InvalidOperationException("Could not install the keyboard hook.");
            }

            BuildTrayIcon();

            Log("Universal Copy/Paste is running.");
            Log(takeOverCtrlC ? "Ctrl+C: normal copy with fallback copy" : "Ctrl+C: native copy");
            Log("Ctrl+Alt+C: backup copy");
            Log(takeOverCtrlV ? "Ctrl+V: universal text paste" : "Ctrl+V: native paste");
            Log("Ctrl+Alt+V: universal text paste");
            Log("Ctrl+Alt+Shift+V: toggle universal copy/paste");
            Log("Ctrl+Alt+Shift+Esc: exit");

            Application.ApplicationExit += delegate
            {
                if (trayIcon != null)
                {
                    trayIcon.Visible = false;
                    trayIcon.Dispose();
                    trayIcon = null;
                }

                if (hookId != IntPtr.Zero)
                {
                    UnhookWindowsHookEx(hookId);
                    hookId = IntPtr.Zero;
                }

                if (appMutex != null)
                {
                    appMutex.ReleaseMutex();
                    appMutex.Dispose();
                    appMutex = null;
                }
            };

            Application.Run();
        }

        private static void Log(string message)
        {
            try
            {
                Console.WriteLine(message);
            }
            catch
            {
                // No console attached (e.g. hidden launch); nothing to write to, safe to ignore.
            }
        }

        private static void BuildTrayIcon()
        {
            trayIcon = new NotifyIcon();
            trayIcon.Icon = SystemIcons.Application;
            trayIcon.Visible = true;

            var menu = new ContextMenuStrip();
            enabledItem = new ToolStripMenuItem("Universal copy/paste enabled");
            enabledItem.Checked = enabled;
            enabledItem.CheckOnClick = true;
            enabledItem.Click += delegate
            {
                SetEnabled(enabledItem.Checked, true);
            };

            var exitItem = new ToolStripMenuItem("Exit");
            exitItem.Click += delegate { Application.Exit(); };

            menu.Items.Add(enabledItem);
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add(exitItem);
            trayIcon.ContextMenuStrip = menu;

            UpdateTrayText();
        }

        private static void SetEnabled(bool value, bool showTip)
        {
            enabled = value;
            if (enabledItem != null)
            {
                enabledItem.Checked = value;
            }

            UpdateTrayText();

            if (showTip && trayIcon != null)
            {
                trayIcon.ShowBalloonTip(
                    900,
                    "Universal Copy/Paste",
                    value ? "Backup copy and universal paste are on." : "Backup copy and universal paste are paused.",
                    ToolTipIcon.Info
                );
            }
        }

        private static void ToggleEnabled()
        {
            PostToUi(delegate { SetEnabled(!enabled, true); });
        }

        private static void UpdateTrayText()
        {
            if (trayIcon != null)
            {
                trayIcon.Text = enabled
                    ? "Universal Copy/Paste: backup copy + universal paste"
                    : "Universal Copy/Paste: paused";
            }
        }

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && IsKeyDownMessage(wParam))
            {
                int vkCode = Marshal.ReadInt32(lParam);
                bool ctrl = IsPressed(VK_CONTROL) || IsPressed(VK_LCONTROL) || IsPressed(VK_RCONTROL);
                bool shift = IsPressed(VK_SHIFT) || IsPressed(VK_LSHIFT) || IsPressed(VK_RSHIFT);
                bool alt = IsPressed(VK_MENU) || IsPressed(VK_LMENU) || IsPressed(VK_RMENU);

                if (ctrl && alt && shift && vkCode == VK_ESCAPE)
                {
                    PostToUi(delegate { Application.Exit(); });
                    return (IntPtr)1;
                }

                if (ctrl && alt && shift && vkCode == VK_V)
                {
                    ToggleEnabled();
                    return (IntPtr)1;
                }

                if (enabled && ctrl && alt && !shift && vkCode == VK_C)
                {
                    uint before = GetClipboardSequenceNumber();
                    if (Interlocked.CompareExchange(ref copyRunning, 1, 0) == 0)
                    {
                        Task.Run((Action)(() => BackupCopyAfterNativeCopy(before)));
                    }

                    return (IntPtr)1;
                }

                if (enabled && ctrl && alt && !shift && vkCode == VK_V)
                {
                    if (Interlocked.CompareExchange(ref pasteRunning, 1, 0) == 0)
                    {
                        Task.Run((Action)PasteClipboardTextAfterKeysRelease);
                    }

                    return (IntPtr)1;
                }

                if (enabled && takeOverCtrlC && ctrl && !shift && !alt && vkCode == VK_C)
                {
                    uint before = GetClipboardSequenceNumber();
                    if (Interlocked.CompareExchange(ref copyRunning, 1, 0) == 0)
                    {
                        Task.Run((Action)(() => BackupCopyAfterNativeCopy(before)));
                    }

                    return CallNextHookEx(hookId, nCode, wParam, lParam);
                }

                if (enabled && takeOverCtrlV && ctrl && !shift && !alt && vkCode == VK_V)
                {
                    if (!IsClipboardFormatAvailable(CF_UNICODETEXT))
                    {
                        return CallNextHookEx(hookId, nCode, wParam, lParam);
                    }

                    if (Interlocked.CompareExchange(ref pasteRunning, 1, 0) == 0)
                    {
                        Task.Run((Action)PasteClipboardTextAfterKeysRelease);
                    }

                    return (IntPtr)1;
                }
            }

            return CallNextHookEx(hookId, nCode, wParam, lParam);
        }

        private static bool IsKeyDownMessage(IntPtr wParam)
        {
            int message = wParam.ToInt32();
            return message == WM_KEYDOWN || message == WM_SYSKEYDOWN;
        }

        private static void BackupCopyAfterNativeCopy(uint originalSequence)
        {
            try
            {
                WaitForCopyKeysRelease();

                if (WaitForClipboardChange(originalSequence, 250))
                {
                    return;
                }

                if (TryWmCopy(originalSequence))
                {
                    return;
                }

                TryUiAutomationCopy();
            }
            catch (Exception ex)
            {
                Log("Backup copy failed: " + ex.Message);
            }
            finally
            {
                Interlocked.Exchange(ref copyRunning, 0);
            }
        }

        private static void WaitForCopyKeysRelease()
        {
            for (int i = 0; i < 120; i++)
            {
                bool ctrl = IsPressed(VK_CONTROL) || IsPressed(VK_LCONTROL) || IsPressed(VK_RCONTROL);
                bool c = IsPressed(VK_C);
                if (!ctrl && !c)
                {
                    return;
                }

                Thread.Sleep(10);
            }
        }

        private static bool TryWmCopy(uint originalSequence)
        {
            IntPtr target = GetFocusedControlOrForegroundWindow();
            if (target == IntPtr.Zero)
            {
                return false;
            }

            SendMessage(target, WM_COPY, IntPtr.Zero, IntPtr.Zero);
            return WaitForClipboardChange(originalSequence, 350);
        }

        private static bool TryUiAutomationCopy()
        {
            string selectedText = GetSelectedTextFromUiAutomation();
            if (String.IsNullOrEmpty(selectedText))
            {
                return false;
            }

            SetClipboardText(selectedText);
            return true;
        }

        private static string GetSelectedTextFromUiAutomation()
        {
            try
            {
                System.Windows.Automation.AutomationElement focused =
                    System.Windows.Automation.AutomationElement.FocusedElement;
                if (focused == null)
                {
                    return String.Empty;
                }

                object patternObject;
                if (focused.TryGetCurrentPattern(
                    System.Windows.Automation.TextPattern.Pattern,
                    out patternObject))
                {
                    var textPattern = (System.Windows.Automation.TextPattern)patternObject;
                    System.Windows.Automation.Text.TextPatternRange[] selections = textPattern.GetSelection();
                    if (selections == null || selections.Length == 0)
                    {
                        return String.Empty;
                    }

                    var pieces = new List<string>();
                    foreach (System.Windows.Automation.Text.TextPatternRange range in selections)
                    {
                        string text = range.GetText(-1);
                        if (!String.IsNullOrEmpty(text))
                        {
                            pieces.Add(text);
                        }
                    }

                    return String.Join(Environment.NewLine, pieces.ToArray());
                }
            }
            catch
            {
                return String.Empty;
            }

            return String.Empty;
        }

        private static void SetClipboardText(string text)
        {
            Exception lastError = null;

            for (int attempt = 0; attempt < 8; attempt++)
            {
                lastError = null;
                bool completed = false;

                using (var done = new ManualResetEvent(false))
                {
                    Thread thread = new Thread(new ThreadStart(delegate
                    {
                        try
                        {
                            Clipboard.SetText(text, TextDataFormat.UnicodeText);
                        }
                        catch (Exception ex)
                        {
                            lastError = ex;
                        }
                        finally
                        {
                            done.Set();
                        }
                    }));

                    thread.SetApartmentState(ApartmentState.STA);
                    thread.IsBackground = true;
                    thread.Start();

                    completed = done.WaitOne(500);
                }

                if (completed && lastError == null)
                {
                    return;
                }

                if (!completed)
                {
                    lastError = new TimeoutException("Timed out while setting clipboard text.");
                }

                Thread.Sleep(35);
            }

            if (lastError != null)
            {
                throw lastError;
            }
        }

        private static bool ClipboardChanged(uint originalSequence)
        {
            return GetClipboardSequenceNumber() != originalSequence;
        }

        private static bool WaitForClipboardChange(uint originalSequence, int timeoutMs)
        {
            int waited = 0;
            while (waited < timeoutMs)
            {
                if (ClipboardChanged(originalSequence))
                {
                    return true;
                }

                Thread.Sleep(25);
                waited += 25;
            }

            return ClipboardChanged(originalSequence);
        }

        private static IntPtr GetFocusedControlOrForegroundWindow()
        {
            IntPtr foreground = GetForegroundWindow();
            if (foreground == IntPtr.Zero)
            {
                return IntPtr.Zero;
            }

            uint foregroundThread = GetWindowThreadProcessId(foreground, IntPtr.Zero);
            uint currentThread = GetCurrentThreadId();
            IntPtr focused = IntPtr.Zero;

            if (foregroundThread != 0 && foregroundThread != currentThread)
            {
                if (AttachThreadInput(currentThread, foregroundThread, true))
                {
                    focused = GetFocus();
                    AttachThreadInput(currentThread, foregroundThread, false);
                }
            }
            else
            {
                focused = GetFocus();
            }

            return focused != IntPtr.Zero ? focused : foreground;
        }

        private static void PasteClipboardTextAfterKeysRelease()
        {
            try
            {
                WaitForPasteKeysRelease();
                string text = ReadClipboardText();
                if (!String.IsNullOrEmpty(text))
                {
                    TypeText(text);
                }
            }
            catch (Exception ex)
            {
                Log("Universal paste failed: " + ex.Message);
            }
            finally
            {
                Interlocked.Exchange(ref pasteRunning, 0);
            }
        }

        private static void WaitForPasteKeysRelease()
        {
            for (int i = 0; i < 120; i++)
            {
                bool ctrl = IsPressed(VK_CONTROL) || IsPressed(VK_LCONTROL) || IsPressed(VK_RCONTROL);
                bool v = IsPressed(VK_V);
                if (!ctrl && !v)
                {
                    return;
                }

                Thread.Sleep(10);
            }
        }

        private static string ReadClipboardText()
        {
            string result = String.Empty;
            Exception lastError = null;

            for (int attempt = 0; attempt < 8; attempt++)
            {
                using (var done = new ManualResetEvent(false))
                {
                    Thread thread = new Thread(new ThreadStart(delegate
                    {
                        try
                        {
                            if (Clipboard.ContainsText(TextDataFormat.UnicodeText))
                            {
                                result = Clipboard.GetText(TextDataFormat.UnicodeText);
                            }
                        }
                        catch (Exception ex)
                        {
                            lastError = ex;
                        }
                        finally
                        {
                            done.Set();
                        }
                    }));

                    thread.SetApartmentState(ApartmentState.STA);
                    thread.IsBackground = true;
                    thread.Start();

                    done.WaitOne(500);
                }

                if (!String.IsNullOrEmpty(result))
                {
                    return result;
                }

                Thread.Sleep(35);
            }

            if (lastError != null)
            {
                throw lastError;
            }

            return result;
        }

        private static void TypeText(string text)
        {
            text = text.Replace("\r\n", "\n").Replace("\r", "\n");

            var inputs = new List<INPUT>(256);
            foreach (char raw in text)
            {
                char ch = raw == '\n' ? '\r' : raw;
                inputs.Add(MakeUnicodeInput(ch, false));
                inputs.Add(MakeUnicodeInput(ch, true));

                if (inputs.Count >= 240)
                {
                    SendInputs(inputs);
                    inputs.Clear();
                    Thread.Sleep(1);
                }
            }

            if (inputs.Count > 0)
            {
                SendInputs(inputs);
            }
        }

        private static INPUT MakeUnicodeInput(char ch, bool keyUp)
        {
            var input = new INPUT();
            input.type = INPUT_KEYBOARD;
            input.U.ki.wVk = 0;
            input.U.ki.wScan = ch;
            input.U.ki.dwFlags = KEYEVENTF_UNICODE | (keyUp ? KEYEVENTF_KEYUP : 0);
            input.U.ki.time = 0;
            input.U.ki.dwExtraInfo = IntPtr.Zero;
            return input;
        }

        private static void SendInputs(List<INPUT> inputs)
        {
            INPUT[] array = inputs.ToArray();
            SendInput((uint)array.Length, array, Marshal.SizeOf(typeof(INPUT)));
        }

        private static void PostToUi(Action action)
        {
            SynchronizationContext context = uiContext;
            if (context != null)
            {
                context.Post(delegate { action(); }, null);
            }
            else
            {
                action();
            }
        }

        private static bool IsPressed(int virtualKey)
        {
            return (GetAsyncKeyState(virtualKey) & 0x8000) != 0;
        }

        private static IntPtr SetHook(LowLevelKeyboardProc proc)
        {
            using (Process currentProcess = Process.GetCurrentProcess())
            using (ProcessModule currentModule = currentProcess.MainModule)
            {
                return SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(currentModule.ModuleName), 0);
            }
        }

        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT
        {
            public uint type;
            public InputUnion U;
        }

        [StructLayout(LayoutKind.Explicit)]
        private struct InputUnion
        {
            [FieldOffset(0)]
            public KEYBDINPUT ki;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct KEYBDINPUT
        {
            public ushort wVk;
            public char wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll")]
        private static extern short GetAsyncKeyState(int vKey);

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool IsClipboardFormatAvailable(uint format);

        [DllImport("user32.dll")]
        private static extern uint GetClipboardSequenceNumber();

        [DllImport("user32.dll")]
        private static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll")]
        private static extern IntPtr GetFocus();

        [DllImport("user32.dll")]
        private static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr lpdwProcessId);

        [DllImport("kernel32.dll")]
        private static extern uint GetCurrentThreadId();

        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    }
}
'@

Add-Type -ReferencedAssemblies @("System.Windows.Forms", "System.Drawing", "UIAutomationClient", "UIAutomationTypes") -TypeDefinition $source -Language CSharp

if ($CompileOnly.IsPresent) {
    Write-Host "UniversalCopyPaste compiled successfully."
    return
}

[KitsuneTools.UniversalCopyPaste]::Run(-not $StartDisabled.IsPresent, $TakeOverCtrlC.IsPresent, $TakeOverCtrlV.IsPresent)
