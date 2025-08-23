# connecta-audit-min.ps1  (run from repo root)
$ErrorActionPreference = 'Stop'

function To-MB($bytes) { if ($bytes -is [long]) { "{0:N2}" -f ($bytes/1MB) } else { "0.00" } }
function FolderSummary($path) {
    if (-not (Test-Path $path)) { return [pscustomobject]@{Path=$path;Count=0;Bytes=0;SizeMB="0.00"} }
    $files = Get-ChildItem -LiteralPath $path -Recurse -File -ErrorAction SilentlyContinue
    $bytes = ($files | Measure-Object -Property Length -Sum).Sum
    [pscustomobject]@{
        Path   = $path
        Count  = $files.Count
        Bytes  = [long]$bytes
        SizeMB = To-MB([long]$bytes)
    }
}

# --- Setup
$root  = Get-Location
$stamp = Get-Date -Format "yyyyMMdd_HHmm"
$AUD   = ".\.audit"
New-Item -ItemType Directory -Force -Path $AUD | Out-Null

# Universe (exclude heavy/build/archives)
$universe = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\node_modules\\|\\\.next\\|\\connecta-next-archive\\|\\connecta-next-inner-backup\\|\\\.git\\' }

function SampleFiles($path, $pattern='*') {
    if (-not (Test-Path $path)) { return @() }
    Get-ChildItem -LiteralPath $path -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
        Select-Object -First 5 -ExpandProperty FullName
}

$categories = @()

# 1) Backups/archives inside repo
$backupFolders = @("connecta-next-inner-backup","connecta-next-archive",".audit") |
    ForEach-Object { if (Test-Path $_) { $_ } }

foreach ($bf in $backupFolders) {
    $sum = FolderSummary $bf
    $categories += [pscustomobject]@{
        Category = "Backup/Archive in repo"
        Path     = $sum.Path
        Count    = $sum.Count
        SizeMB   = $sum.SizeMB
        Reason   = "Backups inflate repo and cause CRLF noise; keep outside Git"
        Examples = (SampleFiles $bf | ForEach-Object { $_.Replace($root,".") }) -join "`n"
    }
}

# 2) ZIPs at root
$zips = Get-ChildItem -File -Filter *.zip -ErrorAction SilentlyContinue
if ($zips) {
    $bytes = ($zips | Measure-Object Length -Sum).Sum
    $categories += [pscustomobject]@{
        Category = "ZIP archives"
        Path     = "(repo root)"
        Count    = $zips.Count
        SizeMB   = To-MB([long]$bytes)
        Reason   = "Binary archives shouldn’t be committed; store outside repo"
        Examples = ($zips | Sort-Object Length -Descending | Select-Object -First 5 | ForEach-Object { $_.FullName.Replace($root,".") }) -join "`n"
    }
}

# 3) Legacy/demo routes that often break builds
$legacyRoutes = @(
    "src\app\firebase-test",
    "src\app\test-firebase",
    "src\app\minimal-test",
    "src\app\dashboard",
    "src\app\onboarding",
    "src\app\individual-onboarding",
    "src\app\merchant-onboarding"
)
foreach ($r in $legacyRoutes) {
    if (Test-Path $r) {
        $sum = FolderSummary $r
        $categories += [pscustomobject]@{
            Category = "Legacy/Demo route"
            Path     = $sum.Path
            Count    = $sum.Count
            SizeMB   = $sum.SizeMB
            Reason   = "Old/demo pages; some import Firebase/AuthContext and fail builds"
            Examples = (SampleFiles $r | ForEach-Object { $_.Replace($root,".") }) -join "`n"
        }
    }
}

# 4) Firebase/AuthContext import hits (grouped by folder)
$codeFiles = Get-ChildItem -Recurse -File -Include *.ts,*.tsx,*.js,*.jsx -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch '\\node_modules\\|\\\.next\\|\\connecta-next-archive\\|\\connecta-next-inner-backup\\|\\\.git\\' }

$patterns = '@/lib/firebase','firebase/','@/context/AuthContext'
$importHits = foreach ($p in $patterns) { Select-String -Path $codeFiles.FullName -Pattern $p -SimpleMatch -ErrorAction SilentlyContinue }

if ($importHits) {
    $importReport = "$AUD\import-hits_$stamp.txt"
    $importHits | Select-Object Path, LineNumber, Line | Sort-Object Path, LineNumber |
        Format-Table -AutoSize | Out-String | Set-Content $importReport

    $hitGroups = $importHits | Group-Object { (Split-Path $_.Path -Parent) }
    foreach ($g in $hitGroups) {
        $path = $g.Name.Replace($root,".")
        $categories += [pscustomobject]@{
            Category = "Route with Firebase/AuthContext import"
            Path     = $path
            Count    = ($g.Group | Measure-Object).Count
            SizeMB   = ""
            Reason   = "Likely depends on missing Firebase/AuthContext; candidate to archive"
            Examples = ($g.Group | Select-Object -First 5 | ForEach-Object { ("L{0}: {1}" -f $_.LineNumber, $_.Line.Trim()) }) -join "`n"
        }
    }
}

# 5) Scattered .bak files
$bakFiles = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '\.bak($|_)' -and $_.FullName -notmatch '\\connecta-next-archive\\|\\connecta-next-inner-backup\\' }

if ($bakFiles) {
    $byFolder = $bakFiles | Group-Object { Split-Path $_.FullName -Parent }
    foreach ($grp in $byFolder) {
        $categories += [pscustomobject]@{
            Category = "Scattered .bak files"
            Path     = $grp.Name.Replace($root,".")
            Count    = $grp.Count
            SizeMB   = To-MB([long](($grp.Group | Measure-Object Length -Sum).Sum))
            Reason   = "Local backups next to sources; safe to archive"
            Examples = ($grp.Group | Select-Object -First 3 | ForEach-Object { $_.FullName.Replace($root,".") }) -join "`n"
        }
    }
}

# 6) Duplicate locales & backup
$srcLocales = "src\locales"
$pubLocalesBackup = "public\locales\backup"
if (Test-Path $srcLocales) {
    $sum = FolderSummary $srcLocales
    $categories += [pscustomobject]@{
        Category = "Duplicate locales tree"
        Path     = $sum.Path
        Count    = $sum.Count
        SizeMB   = $sum.SizeMB
        Reason   = "Runtime uses public\locales; src\locales likely redundant"
        Examples = (SampleFiles $srcLocales '*.json' | ForEach-Object { $_.Replace($root,".") }) -join "`n"
    }
}
if (Test-Path $pubLocalesBackup) {
    $sum = FolderSummary $pubLocalesBackup
    $categories += [pscustomobject]@{
        Category = "Locales backup"
        Path     = $sum.Path
        Count    = $sum.Count
        SizeMB   = $sum.SizeMB
        Reason   = "Backup copies not used at runtime; archive outside repo"
        Examples = (SampleFiles $pubLocalesBackup '*.json' | ForEach-Object { $_.Replace($root,".") }) -join "`n"
    }
}

# 7) Helper scripts/data piles
$scriptDirs = @('scripts','translation-backup','remaining_countries_json','supabase-language-upload') |
    ForEach-Object { if (Test-Path $_) { $_ } }

foreach ($sd in $scriptDirs) {
    $sum = FolderSummary $sd
    $categories += [pscustomobject]@{
        Category = "Helper scripts/data"
        Path     = $sum.Path
        Count    = $sum.Count
        SizeMB   = $sum.SizeMB
        Reason   = "Utility assets; archive or mark non-runtime"
        Examples = (SampleFiles $sd | ForEach-Object { $_.Replace($root,".") }) -join "`n"
    }
}

# 8) Largest files (top 25)
$largest = $universe | Sort-Object Length -Descending | Select-Object -First 25
$largestReport = "$AUD\largest_$stamp.txt"
$largest | Select-Object FullName, @{n='SizeMB';e={ To-MB($_.Length) }} |
    Format-Table -AutoSize | Out-String | Set-Content $largestReport

# 9) Save CSV + Markdown
$csv = "$AUD\redundancy_summary_$stamp.csv"
$md  = "$AUD\redundancy_summary_$stamp.md"
$categories | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

$mdLines = @()
$mdLines += ("# CONNECTA Redundancy Audit ({0})" -f $stamp)
$mdLines += ""
$mdLines += ("Repo: {0}" -f $root.Path)
$mdLines += ""
$mdLines += "## Findings"
$mdLines += ""

foreach ($row in $categories) {
    $mdLines += ("### {0}" -f $row.Category)
    $mdLines += ("- **Path:** `{0}`" -f $row.Path)
    $mdLines += ("- **Files:** {0}  |  **Size:** {1} MB" -f $row.Count, $row.SizeMB)
    $mdLines += ("- **Reason:** {0}" -f $row.Reason)
    if ($row.Examples) {
        $mdLines += "- **Examples:**"
        $mdLines += "```"
        $mdLines += $row.Examples
        $mdLines += "```"
    }
    $mdLines += ""
}

$mdLines += "## Extra Reports"
$mdLines += ("- Largest files: `{0}`" -f (Split-Path $largestReport -Leaf))
if ($importHits) { $mdLines += ("- Import hits: `{0}`" -f (Split-Path $importReport -Leaf)) }

$mdLines -join "`n" | Set-Content $md -Encoding UTF8

# 10) Console summary
"`n===== REDUNDANCY SUMMARY ====="
$categories | Sort-Object Category, Path | Format-Table Category, Path, Count, SizeMB, Reason -AutoSize
"`nSaved:`n - $csv`n - $md`n - $largestReport"
if ($importHits) { "`n - $importReport" }
