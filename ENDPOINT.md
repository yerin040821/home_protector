# 🌐 API 명세 · Ready-Flow AI (Seoul Flood Risk API)

서울 법정동 단위 침수 확률 예측 API. **인증 토큰이 필요 없습니다.**

- **Base URL**: `https://ready-flow-ai.vercel.app`
- **Swagger UI**: https://ready-flow-ai.vercel.app/docs
- **OpenAPI JSON**: https://ready-flow-ai.vercel.app/openapi.json
- **버전**: `1.0.0` · OpenAPI `3.1.0`
- **커버리지**: 침수 이력이 있는 **서울 93개 법정동** (그 외는 `404`)

> 입력: 유저 주소(→법정동) + 실시간 예보 일강우 시퀀스
> 출력: 침수 확률 `flood_probability ∈ [0, 1]`

앱에서의 매핑은 [`lib/services/flood_api_service.dart`](./lib/services/flood_api_service.dart) 참고.

---

## `GET /api/health` — 헬스체크

**Response `200`** (`HealthResponse`)
```json
{ "status": "ok", "dongs": 93, "features": 16 }
```
| 필드 | 타입 | 설명 |
|---|---|---|
| `status` | string | 서비스 상태 (`"ok"`) |
| `dongs` | integer | 커버리지 동 수 |
| `features` | integer | 모델 피처 수 |

---

## `GET /api/dongs` — 커버리지 동 목록

예측 가능한 93개 법정동(`adm_cd`, 구, 동) 목록. 클라이언트 커버리지 해석/폴백 UI용.
앱은 주소 SDK(다음 우편번호)로 받은 **동/구를 이 목록과 대조**해 예측 `adm_cd` 를
정하고(`resolveCoverageForAddress`), 커버리지 밖이면 이 목록 기반 선택 모달
(`dong_picker.dart`)로 폴백합니다.

**Response `200`** — `DongInfo[]`
```json
[
  { "adm_cd": 1162010200, "gu": "관악구", "dong": "신림동" },
  { "adm_cd": 1111017400, "gu": "종로구", "dong": "창신동" },
  { "adm_cd": 1114013200, "gu": "중구",   "dong": null }
]
```
| 필드 | 타입 | 설명 |
|---|---|---|
| `adm_cd` | integer | 10자리 법정동코드 |
| `gu` | string | 자치구 |
| `dong` | string \| null | 동 라벨 (없을 수 있음) |

---

## `POST /api/predict` — 침수 확률 예측

주소(또는 `adm_cd`) + 예보 일강우 → 해당 법정동의 침수 확률.

### Request Body (`PredictRequest`)
```json
{
  "address": "서울 노원구 중계동 23-28",
  "forecast_daily_rain": [5, 40, 60, 100],
  "adm_cd": 1135010600,
  "building_type": "residential"
}
```
| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `forecast_daily_rain` | number[] (1–30) | ✅ | 일강우(mm) 시퀀스. **과거→오늘 순서**(오늘이 마지막) |
| `address` | string | — | 유저 주소. 지오코딩 → 법정동. `adm_cd`를 주면 생략 가능 |
| `adm_cd` | integer \| null | — | 10자리 법정동코드. **주면 지오코딩을 건너뛴다**(권장) |
| `building_type` | enum \| null | — | `residential` · `commercial` · `industrial` · `underground` · `road` · `etc`. *현재 모델 미사용(예약 필드)* |

> 💡 **앱 전략**: 선택한 동의 `adm_cd`를 직접 전달해 지오코딩 실패(404)를 원천 차단합니다.
> 서버 지오코더는 단순 문자열 매칭이라 임의 주소는 해석되지 않을 수 있습니다.

### Response `200` (`PredictResponse`)
```json
{ "adm_cd": 1135010600, "gu": "노원구", "dong": "중계동",
  "flood_probability": 0.7473, "risk_level": "warning", "risk_percentile": 88 }
```
| 필드 | 타입 | 설명 |
|---|---|---|
| `adm_cd` | integer | 법정동코드 |
| `gu` | string | 자치구 |
| `dong` | string \| null | 동 라벨 |
| `flood_probability` | number `[0,1]` | 침수 확률(isotonic 보정값) |
| `risk_level` | enum \| null | 상대 위험등급 `info`·`warning`·`danger` (학습분포 백분위 기준) |
| `risk_percentile` | integer \| null | 학습 예측분포 내 백분위(0–100). 높을수록 상대 고위험 |

### 오류 응답
| 코드 | 의미 | 본문 |
|---|---|---|
| `404` | 동 미해결 / 커버리지 밖 | `{ "detail": "dong not resolved from address ..." }` (`ErrorResponse`) |
| `422` | 페이로드 검증 실패 | FastAPI 검증 오류 |

앱에서는 `404` → `CoverageException`(미지원 지역 안내), 그 외 → `FloodApiException`으로 처리합니다.

---

## `GET /api/forecast/flood-week` — 향후 침수 예보 (백엔드 KMA 프록시)

거주지 `adm_cd` 만 받아서 **백엔드가 직접 기상청 단기예보(`getVilageFcst`)를 호출**하고
(거주지 자치구의 KMA 격자 좌표 사용), 날짜별 예상 강수량으로 `/api/predict` 모델을 돌려
**일자별 침수확률 + 가장 위험한 날**을 돌려줍니다. 웹의 CORS 제약을 백엔드가 대신 해소합니다.

### Query
| 파라미터 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `adm_cd` | integer | ✅ | 10자리 법정동코드 |
| `building_type` | enum | — | 예약 필드(현재 모델 미사용) |

### Response `200` (`FloodWeekForecastResponse`)
```json
{
  "adm_cd": 1162010200, "gu": "관악구", "dong": "신림동",
  "days": [
    { "date": "2026-06-24", "rain_mm": 12.5, "flood_probability": 0.06, "risk_level": "info", "risk_percentile": 61 },
    { "date": "2026-06-25", "rain_mm": 48.0, "flood_probability": 0.11, "risk_level": "warning", "risk_percentile": 83 }
  ],
  "peak": { "date": "2026-06-25", "rain_mm": 48.0, "flood_probability": 0.11, "risk_level": "warning", "risk_percentile": 83 },
  "source": "kma_vilage_fcst",
  "detail": "KMA getVilageFcst base ..."
}
```
> `days` 는 **단기예보가 닿는 날짜(보통 오늘~+3일)만** 포함합니다(예보 밖 날을 0mm로 채워
> '0%'로 오해되지 않도록). 캘린더는 이 미래 확률 + 과거 ASOS 실측을 함께 그립니다.

### 오류 응답
| 코드 | 의미 |
|---|---|
| `404` | 커버리지 밖 `adm_cd` |
| `502` | 기상청 호출/응답 실패 |
| `503` | 백엔드에 `KMA_SERVICE_KEY` 미설정 **또는** 그 키가 단기예보 서비스 미신청 |

```bash
curl "https://ready-flow-ai.vercel.app/api/forecast/flood-week?adm_cd=1162010200"
```

---

## cURL / 빠른 확인

```bash
# 헬스체크
curl https://ready-flow-ai.vercel.app/api/health


# adm_cd 로 예측 (지오코딩 생략 — 항상 해결)
curl -X POST https://ready-flow-ai.vercel.app/api/predict \
  -H 'Content-Type: application/json' \
  -d '{"adm_cd":1162010200,"forecast_daily_rain":[10,30,80]}'

# 주소 문자열로 예측 (커버리지 밖이면 404)
curl -X POST https://ready-flow-ai.vercel.app/api/predict \
  -H 'Content-Type: application/json' \
  -d '{"address":"서울 관악구 신림동","forecast_daily_rain":[5,40,60,100]}'
```

---

# 🌧️ 기상청 기상특보 조회서비스 (알림 탭 · 실시간 특보)

공공데이터포털 **기상청_기상특보 조회서비스** — 알림 탭의 "기상청 실시간 특보"에 사용.
앱 구현은 [`lib/services/weather_warning_service.dart`](./lib/services/weather_warning_service.dart).

- **Base URL**: `https://apis.data.go.kr/1360000/WthrWrnInfoService`
- **인증**: `serviceKey` 쿼리 파라미터 (data.go.kr 발급, `KMA_SERVICE_KEY`)
- **포털**: https://www.data.go.kr/data/15000415/openapi.do
- ⚠️ **CORS 미지원** → Flutter 웹(브라우저)에서는 차단될 수 있음. 모바일에서 정상 동작.

## 호출 흐름

| 단계 | 오퍼레이션 | 설명 |
|---|---|---|
| 1 | `GET /getWthrWrnList` | 최근 발표 목록 → 가장 최신 `tmFc`(발표시각)/`tmSeq` 선택 |
| 2 | `GET /getWthrWrnMsg` | 위 발표의 통보문 전문(`t6`) — "특보 발효 현황" 포함 |

주요 파라미터: `serviceKey`, `dataType=JSON`, `stnId`(109=서울지방기상청),
`fromTmFc`/`toTmFc`(yyyyMMddHHmm), `pageNo`, `numOfRows`, (2단계) `tmFc`/`tmSeq`.

## 파싱 전략

통보문(`t6`)에서 `"<재해><주의보|경보>"` 라인을 정규식으로 찾아 **사용자 지역 키워드**
(`['서울', '관악구']`)가 포함된 특보만 추출합니다. 지역 매칭이 없으면 **통보문 원문**을 그대로
노출하고(실제 정보), 발효 특보가 없으면 "발효 중인 특보 없음"을 표시합니다.

```bash
# 1) 최근 발표 목록
curl "https://apis.data.go.kr/1360000/WthrWrnInfoService/getWthrWrnList\
?serviceKey=YOUR_KEY&dataType=JSON&numOfRows=10&pageNo=1&stnId=109\
&fromTmFc=202606200000&toTmFc=202606222359"

# 2) 통보문 전문
curl "https://apis.data.go.kr/1360000/WthrWrnInfoService/getWthrWrnMsg\
?serviceKey=YOUR_KEY&dataType=JSON&stnId=109&tmFc=202606221500"
```
