# Runs the patient app against the REAL PRODUCTION backend
# (api.docwellness.fit - Oracle VPS, real patients' data). Same
# dart-defines .github/workflows/build-release-aab.yml uses for the Play
# Store release. For everyday work use scripts/run-dev.ps1 instead.
#
# The API URL and SDK keys live in config/prod.json. Pass extra `flutter
# run` args through, e.g.:  .\scripts\run-prod.ps1 -d emulator-5554

$flutter = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (-not $flutter) { $flutter = "C:\flutter\bin\flutter.bat" }

Write-Host "This build talks to PRODUCTION (api.docwellness.fit) - real patient data." -ForegroundColor Yellow

& $flutter run --dart-define-from-file=config/prod.json @args
