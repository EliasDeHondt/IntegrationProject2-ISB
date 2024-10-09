############################
# @author Elias De Hondt   #
# @see https://eliasdh.com #
# @since 09/10/2024        #
############################
# Extra-Kiosk.ps1

<#
.SYNOPSIS    
    This script is used to monitor the "Kioks PC" and restart the processes that are needed for the kiosk to function properly.
.DESCRIPTION
    This script is used to monitor the "Kioks PC" and restart the processes that are needed for the kiosk to function properly.
    The script will check if Google Chrome is running. If the process is not running, the script will start Google Chrome in kiosk mode.
    The script will also check if the "Escape" or "F11" keys are pressed. If they are pressed, the script will ignore the key press.
    The script will run indefinitely until it is stopped manually.
.EXAMPLE
    .\Extra-Kiosk.ps1
#>

Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public class KeyInterceptor {
        public const int VK_ESCAPE = 0x1B;          // Escape key
        public const int VK_F11 = 0x7A;             // F11 key
        public const int VK_CTRL = 0x11;            // Ctrl key
        public const int VK_ALT = 0x12;             // Alt key
        public const int VK_DELETE = 0x2E;          // Delete key
        public const int VK_WIN = 0x5B;             // Windows key
        
        public const int WH_KEYBOARD_LL = 13;       // Keyboard hook
        public const int WM_KEYDOWN = 0x0100;       // Key down event
        public const int WM_SYSKEYDOWN = 0x0104;    // System key down event
        
        private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        private static IntPtr hookId = IntPtr.Zero;
        private static LowLevelKeyboardProc proc = HookCallback;

        public static void SetHook() {
            using (var curProcess = System.Diagnostics.Process.GetCurrentProcess())
            using (var curModule = curProcess.MainModule) {
                hookId = SetWindowsHookEx(WH_KEYBOARD_LL, proc, GetModuleHandle(curModule.ModuleName), 0);
            }
        }

        public static void Unhook() {
            UnhookWindowsHookEx(hookId);
        }

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
            if (nCode >= 0 && (wParam == (IntPtr)WM_KEYDOWN || wParam == (IntPtr)WM_SYSKEYDOWN)) {
                int vkCode = Marshal.ReadInt32(lParam);

                if (vkCode == VK_ESCAPE || vkCode == VK_F11 || vkCode == VK_CTRL || vkCode == VK_ALT || vkCode == VK_DELETE || vkCode == VK_WIN) {
                    return (IntPtr)1; // Ignore the key press
                }
            }

            return CallNextHookEx(IntPtr.Zero, nCode, wParam, lParam);
        }
    }
"@

[KeyInterceptor]::SetHook()

function ProcessRunning {
    param (
        [string]$process
    )

    Get-Process $process -ErrorAction SilentlyContinue | Out-null

    if ($? -eq $false) {
        return $false
    }
    return $true
}

$processname1 = "chrome" # Google Chrome
Stop-Process -Name $processname1 -ErrorAction SilentlyContinue

$url = "https://canvas.kdg.be"

while ($true) {
    $chromeRunning = ProcessRunning -process $processname1

    if (-not $chromeRunning) {
        Write-Host "Google Chrome is not running. Starting Google Chrome."
        Start-Process "chrome.exe" -ArgumentList "--kiosk", $url -WindowStyle Maximized -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 1
}

[KeyInterceptor]::Unhook()