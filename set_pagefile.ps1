$pf = Get-WmiObject Win32_PageFileSetting -Filter "Name='E:\\pagefile.sys'"
if ($pf) {
    try {
        $pf.InitialSize = 25600
        $pf.MaximumSize = 25600
        $pf.Put()
        Write-Host "Success! Pagefile size has been increased to 25 GB on E:."
        Write-Host "A system restart is required for these changes to take full effect."
    } catch {
        Write-Host "Error occurred while setting pagefile."
    }
} else {
    Write-Host "Could not find pagefile.sys on E: drive."
}
Write-Host "You can close this window now..."
Start-Sleep -Seconds 10
