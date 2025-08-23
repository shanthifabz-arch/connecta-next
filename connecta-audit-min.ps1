# connecta-audit-min.ps1  (run from repo root)
$ErrorActionPreference = 'Stop'

function To-MB([long]$b){ '{0:N2}' -f ($b/1MB) }
function FolderSummary($p){
  if(-not(Test-Path $p)){ return [pscustomobject]@{Path=$p;Count=0;Bytes=0;SizeMB='0.00'} }
  $f = Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue
  $s = ($f | Measure-Object Length -Sum).Sum
  [pscustomobject]@{ Path=$p; Count=$f.Count; Bytes=[long]$s; SizeMB=(To-MB $s) }
}

$root  = Get-Location
$stamp = Get-Date -Format 'yyyyMMdd_HHmm'
$AUD   = '.\.audit'
New-Item -ItemType Directory -Force -Path $AUD | Out-Null

# Universe (exclude heaviest/build/archives)
$code = Get-ChildItem -Recurse -File -Include *.ts,*.tsx,*.js,*.jsx -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\node_modules\\|\\\.next\\|\\connecta-next-archive\\|\\connecta-next-inner-backup\\|\\\.git\\' }

$cats = @()

# A) Backups/archives inside repo
$backs = @('connecta-next-inner-backup','connecta-next-archive','.audit') | Where-Object { Test-Path $_ }
foreach($b in $backs){
  $sum = FolderSummary $b
  $cats += [pscustomobject]@{
    Category='Backup/Archive'; Path=$sum.Path; Count=$sum.Count; SizeMB=$sum.SizeMB
    Reason='Backups inside repo'; Examples=(Get-ChildItem -LiteralPath $b -Recurse -File | Select -First 5 -Expand FullName) -join "`n"
  }
}

# B) ZIPs at root
$z = Get-ChildItem -File -Filter *.zip -ErrorAction SilentlyContinue
if($z){
  $bytes = ($z|Measure-Object Length -Sum).Sum
  $cats += [pscustomobject]@{
    Category='ZIP archives'; Path='(repo root)'; Count=$z.Count; SizeMB=(To-MB $bytes)
    Reason='Binary archives in repo'; Examples=($z|Sort Length -Descending|Select -First 5 -Expand FullName) -join "`n"
  }
}

# C) Legacy/demo routes
$legacy = @('src\app\firebase-test','src\app\test-firebase','src\app\minimal-test','src\app\dashboard','src\app\onboarding','src\app\individual-onboarding','src\app\merchant-onboarding')
foreach($r in $legacy){
  if(Test-Path $r){
    $sum = FolderSummary $r
    $cats += [pscustomobject]@{
      Category='Legacy/Demo route'; Path=$sum.Path; Count=$sum.Count; SizeMB=$sum.SizeMB
      Reason='Old/demo pages'; Examples=(Get-ChildItem -LiteralPath $r -Recurse -File | Select -First 5 -Expand FullName) -join "`n"
    }
  }
}

# D) Firebase/AuthContext import hits grouped by folder
$patterns = '@/lib/firebase','firebase/','@/context/AuthContext'
$hits = @()
foreach($p in $patterns){ $hits += Select-String -Path $code.FullName -Pattern $p -SimpleMatch -ErrorAction SilentlyContinue }
if($hits){
  $imp = "$AUD\import-hits_$stamp.txt"
  $hits | Select Path,LineNumber,Line | Sort Path,LineNumber | Format-Table -AutoSize | Out-String | Set-Content $imp
  $grp = $hits | Group-Object { Split-Path $_.Path -Parent }
  foreach($g in $grp){
    $cats += [pscustomobject]@{
      Category='Route with Firebase/AuthContext import'
      Path=$g.Name.Replace($root,' .'); Count=($g.Group|Measure-Object).Count; SizeMB=''
      Reason='Depends on Firebase/AuthContext'; Examples=($g.Group|Select -First 5 | ForEach-Object {'L'+$_.LineNumber+': '+$_.Line.Trim()}) -join "`n"
    }
  }
}

# E) Scattered .bak files
$bak = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.bak($|_)' -and $_.FullName -notmatch '\\connecta-next-archive\\|\\connecta-next-inner-backup\\' }
if($bak){
  $by = $bak | Group-Object { Split-Path $_.FullName -Parent }
  foreach($g in $by){
    $cats += [pscustomobject]@{
      Category='Scattered .bak files'; Path=$g.Name.Replace($root,' .'); Count=$g.Count
      SizeMB=(To-MB ( ($g.Group|Measure-Object Length -Sum).Sum )); Reason='Local backups'
      Examples=($g.Group|Select -First 3 -Expand FullName) -join "`n"
    }
  }
}

# F) Duplicate locales & backups
if(Test-Path 'src\locales'){
  $sum = FolderSummary 'src\locales'
  $cats += [pscustomobject]@{
    Category='Duplicate locales tree'; Path=$sum.Path; Count=$sum.Count; SizeMB=$sum.SizeMB
    Reason='Likely redundant vs public\locales'; Examples=(Get-ChildItem -LiteralPath 'src\locales' -Recurse -File -Filter *.json | Select -First 5 -Expand FullName) -join "`n"
  }
}
if(Test-Path 'public\locales\backup'){
  $sum = FolderSummary 'public\locales\backup'
  $cats += [pscustomobject]@{
    Category='Locales backup'; Path=$sum.Path; Count=$sum.Count; SizeMB=$sum.SizeMB
    Reason='Backup copies'; Examples=(Get-ChildItem -LiteralPath 'public\locales\backup' -Recurse -File -Filter *.json | Select -First 5 -Expand FullName) -join "`n"
  }
}

# G) Helper scripts/data piles
$dirs = @('scripts','translation-backup','remaining_countries_json','supabase-language-upload') | Where-Object { Test-Path $_ }
foreach($d in $dirs){
  $sum = FolderSummary $d
  $cats += [pscustomobject]@{
    Category='Helper scripts/data'; Path=$sum.Path; Count=$sum.Count; SizeMB=$sum.SizeMB
    Reason='Utility assets'; Examples=(Get-ChildItem -LiteralPath $d -Recurse -File | Select -First 5 -Expand FullName) -join "`n"
  }
}

# Outputs
$csv = "$AUD\redundancy_summary_$stamp.csv"
$md  = "$AUD\redundancy_summary_$stamp.md"
$cats | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

"CONNECTA Redundancy Audit $stamp`n" | Set-Content $md -Encoding UTF8
$cats | Sort-Object Category,Path | ForEach-Object {
  Add-Content $md ("Category: {0}" -f $_.Category)
  Add-Content $md ("Path: {0}" -f $_.Path)
  Add-Content $md ("Files: {0} | SizeMB: {1}" -f $_.Count, $_.SizeMB)
  Add-Content $md ("Reason: {0}" -f $_.Reason)
  if($_.Examples){ Add-Content $md 'Examples:'; Add-Content $md $_.Examples }
  Add-Content $md ''
}

"`n===== REDUNDANCY SUMMARY ====="
$cats | Sort-Object Category, Path | Format-Table Category, Path, Count, SizeMB, Reason -AutoSize
"`nSaved:`n - $csv`n - $md"
if($imp){ "`n - $imp" }
