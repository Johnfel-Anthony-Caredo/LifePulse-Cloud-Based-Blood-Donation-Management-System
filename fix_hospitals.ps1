$file = 'lib\models\hospital.dart'
$content = Get-Content $file -Raw

# Add is24Hours before urgency
$newline = [Environment]::NewLine
$pattern = '(\s+)(urgency: HospitalUrgency\.\w+,)'
$replacement = '$1is24Hours: true,' + $newline + '$1$2'
$content = $content -replace $pattern, $replacement

$content | Set-Content $file -NoNewline
Write-Host "Fixed all Hospital entries"
