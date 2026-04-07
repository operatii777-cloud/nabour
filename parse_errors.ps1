$lines = Get-Content "analyze_output2.txt" -Encoding UTF8
$errors   = @($lines | Where-Object { $_ -match "^\s+error\s+-\s+" })
$warnings = @($lines | Where-Object { $_ -match "^\s+warning\s+-\s+" })
$infos    = @($lines | Where-Object { $_ -match "^\s+info\s+-\s+" })

Write-Host "TOTAL ERRORS:   $($errors.Count)"
Write-Host "TOTAL WARNINGS: $($warnings.Count)"
Write-Host "TOTAL INFOS:    $($infos.Count)"
Write-Host ""

$byFile = @{}
foreach ($line in $errors) {
    if ($line -match "([a-zA-Z_]+\.dart):\d+:\d+") {
        $f = $Matches[1]
        if ($byFile.ContainsKey($f)) { $byFile[$f]++ } else { $byFile[$f] = 1 }
    }
}

Write-Host "=== TOP FISIERE CU ERORI ==="
$byFile.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 20 | ForEach-Object {
    Write-Host "$($_.Value.ToString().PadLeft(4))  ->  $($_.Key)"
}

$errorTypes = @{}
foreach ($line in $errors) {
    if ($line -match "\s-\s+([a-z_]+)\s*$") {
        $t = $Matches[1]
        if ($errorTypes.ContainsKey($t)) { $errorTypes[$t]++ } else { $errorTypes[$t] = 1 }
    }
}

Write-Host ""
Write-Host "=== TIPURI DE ERORI ==="
$errorTypes.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15 | ForEach-Object {
    Write-Host "$($_.Value.ToString().PadLeft(4))  ->  $($_.Key)"
}
