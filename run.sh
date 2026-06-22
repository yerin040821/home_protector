#!/usr/bin/env bash
# HomeProtector 실행 헬퍼.
# - 웹 포트를 56940 으로 고정한다(카카오 지도 도메인 등록 http://localhost:56940 과 일치).
# - .env 의 KAKAO_JS_KEY 를 읽어 web/kakao_config.js 를 생성한다(키를 코드에 하드코딩하지 않음).
#
#   ./run.sh            # 웹(Chrome), 포트 56940
#   ./run.sh release    # 웹 릴리스 모드
#   ./run.sh device     # 연결된 모바일 기기/에뮬레이터
set -euo pipefail

cd "$(dirname "$0")"

PORT=56940
MODE="${1:-web}"

# ── .env → web/kakao_config.js 주입 ───────────────────────────────
if [ -f .env ]; then
  # shellcheck disable=SC1091
  set -a; . ./.env; set +a
fi
KEY="${KAKAO_JS_KEY:-}"
if [ -n "$KEY" ] && [ "$KEY" != "your_kakao_javascript_key" ]; then
  printf 'window.KAKAO_JS_KEY = "%s";\n' "$KEY" > web/kakao_config.js
  echo "▶ web/kakao_config.js 생성 완료 (.env 의 KAKAO_JS_KEY 주입)"
else
  echo "ℹ .env 에 KAKAO_JS_KEY 가 없어 web/index.html 의 fallback 키를 사용합니다."
fi

# ── 베이스 URL 오버라이드(선택) ───────────────────────────────────
DEFINE=()
if [ -n "${FLOOD_API_BASE_URL:-}" ]; then
  DEFINE=(--dart-define=FLOOD_API_BASE_URL="$FLOOD_API_BASE_URL")
fi

echo "▶ flutter pub get"
flutter pub get

case "$MODE" in
  web)
    exec flutter run -d chrome --web-hostname localhost --web-port "$PORT" "${DEFINE[@]}"
    ;;
  release)
    exec flutter run -d chrome --release --web-hostname localhost --web-port "$PORT" "${DEFINE[@]}"
    ;;
  device)
    exec flutter run "${DEFINE[@]}"
    ;;
  *)
    echo "Unknown mode: $MODE (use: web | release | device)" >&2
    exit 1
    ;;
esac
