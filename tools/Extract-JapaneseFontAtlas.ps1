param(
    [Parameter(Mandatory = $true)]
    [string] $GameDirectory,

    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'

$expectedExeHash = '86D982094B9426F934B1B1925DA44766BBB524D430D203A5B94DC16F036C48E1'
$expectedAtlasHash = '235E5B729CFFC9C1C818BEF553926DEC1CEA025A9E0BE41A5D0A3E6F2DE03C89'
$menuAtlasOffset = [int64] 0xC6710
$lcdAtlasOffset = [int64] 0xC6AC8
$atlasByteCount = 238 * 4

$exePath = Join-Path $GameDirectory 'AbeWin.exe'
if (!(Test-Path -LiteralPath $exePath -PathType Leaf)) {
    throw "AbeWin.exe was not found: $exePath"
}

$actualExeHash = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash
if ($actualExeHash -ne $expectedExeHash) {
    throw "Unsupported AbeWin.exe. Expected SHA-256 $expectedExeHash but found $actualExeHash"
}

$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

Add-Type @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class ReliveJapaneseAtlasMemory
{
    private const uint PROCESS_VM_READ = 0x0010;
    private const uint PROCESS_QUERY_INFORMATION = 0x0400;

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint access, bool inheritHandle, int processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool ReadProcessMemory(IntPtr process, IntPtr address, byte[] buffer, int size, out IntPtr bytesRead);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr handle);

    public static byte[] Read(int processId, long address, int size)
    {
        IntPtr process = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, processId);
        if (process == IntPtr.Zero)
        {
            throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        try
        {
            byte[] buffer = new byte[size];
            IntPtr bytesRead;
            if (!ReadProcessMemory(process, new IntPtr(address), buffer, size, out bytesRead) || bytesRead.ToInt64() != size)
            {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
            return buffer;
        }
        finally
        {
            CloseHandle(process);
        }
    }
}
'@

$existingProcessIds = @(Get-Process -Name 'AbeWin' -ErrorAction SilentlyContinue | ForEach-Object Id)
$startedProcess = Start-Process -FilePath $exePath -WorkingDirectory $GameDirectory -WindowStyle Hidden -PassThru
$ownedProcesses = @()

try {
    $deadline = [DateTime]::UtcNow.AddSeconds(20)
    $lastError = $null

    do {
        Start-Sleep -Milliseconds 250
        $ownedProcesses = @(Get-Process -Name 'AbeWin' -ErrorAction SilentlyContinue | Where-Object { $existingProcessIds -notcontains $_.Id })
        if (!$startedProcess.HasExited -and $ownedProcesses.Id -notcontains $startedProcess.Id) {
            $ownedProcesses += $startedProcess
        }

        foreach ($process in $ownedProcesses) {
            try {
                $process.Refresh()
                $moduleBase = $process.MainModule.BaseAddress.ToInt64()
                $menuAtlas = [ReliveJapaneseAtlasMemory]::Read($process.Id, $moduleBase + $menuAtlasOffset, $atlasByteCount)
                $lcdAtlas = [ReliveJapaneseAtlasMemory]::Read($process.Id, $moduleBase + $lcdAtlasOffset, $atlasByteCount)

                $combined = [byte[]]::new($atlasByteCount * 2)
                [Array]::Copy($menuAtlas, 0, $combined, 0, $atlasByteCount)
                [Array]::Copy($lcdAtlas, 0, $combined, $atlasByteCount, $atlasByteCount)
                [IO.File]::WriteAllBytes($OutputPath, $combined)

                $actualAtlasHash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
                if ($actualAtlasHash -ne $expectedAtlasHash) {
                    Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
                    throw "Extracted data failed validation. Expected SHA-256 $expectedAtlasHash but found $actualAtlasHash"
                }

                Write-Output "Created: $OutputPath"
                Write-Output "Size: $($combined.Length) bytes"
                Write-Output "SHA-256: $actualAtlasHash"
                return
            }
            catch {
                $lastError = $_
            }
        }
    } while ([DateTime]::UtcNow -lt $deadline)

    if ($lastError) {
        throw "Could not extract the Japanese font atlas: $($lastError.Exception.Message)"
    }
    throw 'Could not find the newly started AbeWin process.'
}
finally {
    foreach ($process in $ownedProcesses) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    if ($startedProcess -and !$startedProcess.HasExited -and $existingProcessIds -notcontains $startedProcess.Id) {
        Stop-Process -Id $startedProcess.Id -Force -ErrorAction SilentlyContinue
    }
}


