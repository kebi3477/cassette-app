#!/bin/bash
# 시뮬레이터에서 integration_test/app_flow_test.dart를 돌리며 화면을 찍는다 (docs/SETUP.md).
# 쓰는 법: tool/sim_flow.sh <시뮬레이터 UDID> [API_BASE_URL]
# 결과: build/screenshots/*.png (커밋하지 않는다)
# 앱이 로그에 `CASSETTE_SHOT <이름>`을 찍으면 simctl로 화면을 저장한다.
set -uo pipefail
DEV="$1"
BASE="${2:-}"
OUT="$PWD/build/screenshots"

flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_flow_test.dart -d "$DEV" \
  ${BASE:+--dart-define=API_BASE_URL=$BASE} 2>&1 |
  while IFS= read -r line; do
    echo "$line"
    if [[ "$line" == *CASSETTE_SHOT* ]]; then
      name="${line##*CASSETTE_SHOT }"
      name="${name%$'\r'}"
      sleep 0.8
      mkdir -p "$OUT"
      xcrun simctl io "$DEV" screenshot "$OUT/$name.png" >/dev/null 2>&1
    fi
  done
