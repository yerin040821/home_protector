#!/usr/bin/env pwsh
# HomeProtector 실행 헬퍼 — Windows / PowerShell 판 (run.sh 의 Windows 버전).
# - 웹 포트를 56940 으로 고정(카카오 지도 도메인 등록 http://localhost:56940 과 일치).
# - .env 의 KAKAO_JS_KEY 를 읽어 web/kakao_config.js 생성(키 하드코딩 안 함).
# - .env 의 FLOOD_API_BASE_URL / KMA_SERVICE_KEY / CORS_PROXY 를 --dart-define 으로 주입.
#
#   .\run.ps1            # 웹(Chrome), 포트 56940
#   .\run.ps1 release    # 웹 릴리스 모드
#   .\run.ps1 device     # 연결된 모바일 기기/에뮬레이터
#
# 처음 실행 시 PowerShell 실행정책에 막히면:  powershell -ExecutionPolicy Bypass -File .\run.ps1
# (또는 동봉된 run.bat 더블클릭/실행)
param([string]$Mode = "web")
$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

$Port = 56940

# ── .env 로드 (KEY=VALUE) ────────────────────────────────────────
$envMap = @{}
if (Test-Path ".env") {
  Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
      $idx = $line.IndexOf("=")
      $k = $line.Substring(0, $idx).Trim()
      $v = $line.Substring($idx + 1).Trim().Trim('"')
      $envMap[$k] = $v
    }
  }
}
function Get-EnvVal($name) { if ($envMap.ContainsKey($name)) { $envMap[$name] } else { "" } }

# ── Kakao JS 키 → web/kakao_config.js ────────────────────────────
$kakao = Get-EnvVal "KAKAO_JS_KEY"
if ($kakao -and $kakao -ne "your_kakao_javascript_key") {
  "window.KAKAO_JS_KEY = `"$kakao`";" | Set-Content -Path "web/kakao_config.js" -Encoding utf8
  Write-Host "▶ web/kakao_config.js 생성 완료 (.env 의 KAKAO_JS_KEY 주입)"
} else {
  Write-Host "ℹ .env 에 KAKAO_JS_KEY 가 없어 web/index.html 의 fallback 키를 사용합니다."
}

# ── --dart-define 주입 ───────────────────────────────────────────
$defs = @()
$apiBase = Get-EnvVal "FLOOD_API_BASE_URL"
if ($apiBase) { $defs += "--dart-define=FLOOD_API_BASE_URL=$apiBase" }
$kma = Get-EnvVal "KMA_SERVICE_KEY"
if ($kma) { $defs += "--dart-define=KMA_SERVICE_KEY=$kma"; Write-Host "▶ 기상청 특보 키(KMA_SERVICE_KEY) 주입됨" }
else { Write-Host "ℹ .env 에 KMA_SERVICE_KEY 가 없어 알림 탭은 '연동 대기' 상태로 표시됩니다." }
$cors = Get-EnvVal "CORS_PROXY"
if ($cors) { $defs += "--dart-define=CORS_PROXY=$cors"; Write-Host "▶ CORS 프록시 주입됨 (웹에서 기상청 호출용)" }

Write-Host "▶ flutter pub get"
flutter pub get

switch ($Mode) {
  "web"     { flutter run -d chrome --web-hostname localhost --web-port $Port @defs }
  "release" { flutter run -d chrome --release --web-hostname localhost --web-port $Port @defs }
  "device"  { flutter run @defs }
  default   { Write-Error "Unknown mode: $Mode (use: web | release | device)"; exit 1 }
}
