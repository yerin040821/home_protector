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

예측 가능한 93개 법정동(`adm_cd`, 구, 동) 목록. 클라이언트 자동완성/선택 UI용.
앱의 **지원 지역 검색 모달**(`dong_picker.dart`)이 이 응답을 사용합니다.

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
{ "adm_cd": 1135010600, "gu": "노원구", "dong": "중계동", "flood_probability": 0.7473 }
```
| 필드 | 타입 | 설명 |
|---|---|---|
| `adm_cd` | integer | 법정동코드 |
| `gu` | string | 자치구 |
| `dong` | string \| null | 동 라벨 |
| `flood_probability` | number `[0,1]` | 침수 확률 |

### 오류 응답
| 코드 | 의미 | 본문 |
|---|---|---|
| `404` | 동 미해결 / 커버리지 밖 | `{ "detail": "dong not resolved from address ..." }` (`ErrorResponse`) |
| `422` | 페이로드 검증 실패 | FastAPI 검증 오류 |

앱에서는 `404` → `CoverageException`(미지원 지역 안내), 그 외 → `FloodApiException`으로 처리합니다.

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
