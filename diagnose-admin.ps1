param(
  [string]$Root = (Get-Location).Path
)

Write-Host "▶ CONNECTA Admin Route Diagnostics" -ForegroundColor Cyan
Write-Host "Project root: $Root`n"

function Test-ImportInFile($filePath, $needle) {
  if (!(Test-Path $filePath)) { return $false }
  $raw = Get-Content $filePath -Raw
  return ($raw -match [regex]::Escape($needle))
}

function Read-File($path) { if (Test-Path $path) { Get-Content $path -Raw } else { "" } }

# Existence checks
$hasAppDir        = Test-Path "$Root\src\app"
$hasPagesDir      = Test-Path "$Root\src\pages"
$hasAppAdmin      = Test-Path "$Root\src\app\admin\page.tsx"
$hasPagesAdmin    = Test-Path "$Root\src\pages\admin\index.tsx"
$hasAppLayout     = Test-Path "$Root\src\app\layout.tsx"
$hasPagesApp      = Test-Path "$Root\src\pages\_app.tsx"
$appGlobalsFile   = Test-Path "$Root\src\app\globals.css"
$stylesGlobalsFile= Test-Path "$Root\src\styles\globals.css"
$componentUpload1 = Test-Path "$Root\src\components\admin\AAConnectorUpload.tsx"
$componentUpload2 = Test-Path "$Root\src\components\admin\AAConnectorUpload.jsx"

# Configs
$nextConfig       = Get-ChildItem $Root -Filter "next.config.*" -ErrorAction SilentlyContinue | Select-Object -First 1
$tailwindConfig   = Get-ChildItem $Root -Filter "tailwind.config.*" -ErrorAction SilentlyContinue | Select-Object -First 1
$middlewarePath   = "$Root\src\middleware.ts"
$tsconfigPath     = "$Root\tsconfig.json"

$nextCfgRaw       = if ($nextConfig)  { Get-Content $nextConfig.FullName -Raw } else { "" }
$tailwindRaw      = if ($tailwindConfig){ Get-Content $tailwindConfig.FullName -Raw } else { "" }
$middlewareRaw    = Read-File $middlewarePath
$tsconfigRaw      = Read-File $tsconfigPath
$appLayoutRaw     = Read-File "$Root\src\app\layout.tsx"
$pagesAppRaw      = Read-File "$Root\src\pages\_app.tsx"

# Parse next.config for basePath/pageExtensions/i18n
$basePath = $null
$pageExtensions = $null
$hasI18n = $false
if ($nextCfgRaw -match "basePath\s*:\s*['""]([^'""]+)['""]") { $basePath = $Matches[1] }
if ($nextCfgRaw -match "pageExtensions\s*:\s*\[([^\]]+)\]") { $pageExtensions = $Matches[1] }
if ($nextCfgRaw -match "i18n\s*:") { $hasI18n = $true }

# Tailwind content globs
$twHasApp        = ($tailwindRaw -match "app/\*\*/\*")
$twHasPages      = ($tailwindRaw -match "pages/\*\*/\*")
$twHasComponents = ($tailwindRaw -match "components/\*\*/\*")

# Middleware touching /admin?
$mwTouchesAdmin = ($middlewareRaw -match "/admin")

# Do app/pages import globals?
$layoutImportsGlobals = ($appLayoutRaw -match "globals\.css")
$pagesAppImportsGlobals = ($pagesAppRaw -match "globals\.css")

# tsconfig alias for @/*
$tsHasAlias = ($tsconfigRaw -match '"paths"\s*:\s*\{\s*"@/\\\*"\s*:\s*\["\*/\*\*"\]|"paths"\s*:\s*\{\s*"@/\*"\s*:')
$tsBaseUrlSrc = ($tsconfigRaw -match '"baseUrl"\s*:\s*"src"')

# Print quick table
$rows = @(
  @{ Key = "src/app present";               Val = $hasAppDir }
  @{ Key = "src/pages present";             Val = $hasPagesDir }
  @{ Key = "App Router /admin page";        Val = $hasAppAdmin }
  @{ Key = "Pages Router /admin page";      Val = $hasPagesAdmin }
  @{ Key = "App layout.tsx";                Val = $hasAppLayout }
  @{ Key = "Pages _app.tsx";                Val = $hasPagesApp }
  @{ Key = "App globals.css";               Val = $appGlobalsFile }
  @{ Key = "Styles globals.css";            Val = $stylesGlobalsFile }
  @{ Key = "Tailwind has app/*";            Val = $twHasApp }
  @{ Key = "Tailwind has pages/*";          Val = $twHasPages }
  @{ Key = "Tailwind has components/*";     Val = $twHasComponents }
  @{ Key = "next.config basePath";          Val = ($basePath ? $basePath : "(none)") }
  @{ Key = "next.config pageExtensions";    Val = ($pageExtensions ? $pageExtensions : "(default)") }
  @{ Key = "i18n enabled";                  Val = $hasI18n }
  @{ Key = "middleware touches /admin";     Val = $mwTouchesAdmin }
  @{ Key = "tsconfig alias @/*";            Val = $tsHasAlias }
  @{ Key = "tsconfig baseUrl=src";          Val = $tsBaseUrlSrc }
  @{ Key = "AAConnectorUpload.tsx exists";  Val = ($componentUpload1 -or $componentUpload2) }
  @{ Key = "layout.tsx imports globals";    Val = $layoutImportsGlobals }
  @{ Key = "_app.tsx imports globals";      Val = $pagesAppImportsGlobals }
)

$rows | ForEach-Object {
  $color = if ($_.Val -is [bool]) { if ($_.Val) { "Green" } else { "Red" } } else { "Yellow" }
  Write-Host ("{0,-28} : {1}" -f $_.Key, $_.Val) -ForegroundColor $color
}

Write-Host "`n▶ Recommended Fix (based on checks)" -ForegroundColor Cyan
$recs = @()

# Case 1: App Router admin exists, but CSS not wired
if ($hasAppAdmin) {
  if (-not $hasAppLayout) {
    $recs += "Create src/app/layout.tsx and import a globals.css so Tailwind/styles load for App Router."
  } elseif ($hasAppLayout -and -not $layoutImportsGlobals) {
    $recs += "Add `import '../styles/globals.css'` (or './globals.css') at top of src/app/layout.tsx."
  }

  if ($hasAppLayout -and $layoutImportsGlobals -and -not $appGlobalsFile -and $stylesGlobalsFile) {
    $recs += "Change layout import to `import '../styles/globals.css'` (you have styles/globals.css but no app/globals.css)."
  }

  if (-not $twHasApp) {
    $recs += "Update tailwind.config.* content[] to include './src/app/**/*.{js,ts,jsx,tsx}'."
  }
}

# Case 2: Pages Router admin intended
if ($hasPagesAdmin -and -not $hasAppAdmin) {
  if ($pageExtensions -and ($pageExtensions -notmatch "tsx")) {
    $recs += "Add 'tsx' to next.config.js pageExtensions so Next discovers /pages TSX files."
  }
  if ($basePath) {
    $recs += "Your basePath='$basePath'. Open http://localhost:3000$basePath/admin or remove basePath."
  }
  if ($mwTouchesAdmin) {
    $recs += "middleware.ts rewrites/redirects '/admin'. Adjust or disable to let /admin resolve."
  }
  if (-not $pagesAppImportsGlobals) {
    $recs += "Ensure src/pages/_app.tsx imports '@/styles/globals.css' so Tailwind applies."
  }
}

# Case 3: Both routers define /admin → choose one
if ($hasAppAdmin -and $hasPagesAdmin) {
  $recs += "Both App and Pages define /admin. Pick one. Easiest: delete src/app/admin/page.tsx to return to Pages Router styling."
}

if (-not ($componentUpload1 -or $componentUpload2)) {
  $recs += "Missing component '@/components/admin/AAConnectorUpload'. Ensure the filename matches and extension is .tsx or adjust the import."
}

if ($recs.Count -eq 0) { $recs += "No blocking issues found. Try clearing cache: `rd -r .next` then `npm run dev`." }

$idx = 1
$recs | ForEach-Object { Write-Host ("{0}. {1}" -f $idx, $_) -ForegroundColor Green; $idx++ }

Write-Host "`nDone."
