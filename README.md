# 🏠 HomeProtector · 홈프로텍터

> 사계절 생활재난 보호 서비스 — 서울 법정동 단위 **AI 침수 위험 예측** 모바일/웹 앱

반지하·저지대 거주자를 위한 침수 대비 서비스입니다. 거주 지역과 건물 유형을 선택하면
[Ready-Flow AI 침수 예측 API](https://ready-flow-ai.vercel.app/docs)로부터 **실시간 침수 확률**을
받아오고, 대피소·체크리스트·카드뉴스·긴급 연락처 등 행동 지침을 한 화면에서 제공합니다.

| | |
|---|---|
| **Framework** | Flutter (Dart `^3.10.9`) · Material 3 |
| **상태관리** | `provider` |
| **지도** | Kakao Maps JS SDK (웹) |
| **예측 API** | Ready-Flow AI — Seoul Flood Risk API (인증 불필요) |
| **데모 지역** | 서울 관악구 신림동 (2022 침수 피해 지역, API 커버리지 내) |

---

## ✨ 주요 기능

- **실시간 AI 침수 확률** — `/api/predict` 결과를 홈 화면 *Ready-Flow AI 실시간 예측* 카드에 표시
- **개인화된 주소 입력 (SDK 모달)** — 자유 텍스트 입력 대신 **다음(카카오) 우편번호 SDK**
  모달을 띄워 실제 거주지 주소를 받습니다(웹=JS 팝업, 모바일=`kpostal` 웹뷰). 받은 주소에서
  **법정동·자치구만 추출**해 예측에 씁니다. 예: `성동구 상왕십리동 811` → `상왕십리동`(동) 또는
  `성동구`(구)로 해석.
  - **정확 매칭**: 그 동이 커버리지(93개) 안이면 그대로 예측
  - **구 단위 근사**: 동은 밖이지만 같은 구에 지원 동이 있으면 그 동 기준으로 예측(안내 표시)
  - **커버리지 밖**: 지원 지역을 직접 고르도록 안내 (예: 성동구는 현재 커버리지 없음)
  - 실제 주소·위경도는 보존해 **지도에 내 집 핀**으로 고정 표시합니다
- **기상청 실시간 특보** — 알림 탭은 데모 데이터가 아니라 **기상청(KMA) 기상특보 조회 API**로
  현재 발효 중인 실제 특보(호우주의보 등)만 표시. 상태를 상세히 구분: '연동 대기'(키 없음)·
  '키 오류'·'웹 CORS 차단'·'발효 없음'·'네트워크 오류' (HTTP 상태/resultCode 진단 포함)
- **위험도 = 100% 실측** — 홈의 침수확률·위험단계·경보 배너는 모두 Ready-Flow AI 실측치에서만
  파생됩니다. 임의의 하드코딩 수치(기온/강수확률/풍속/시나리오 %)는 모두 제거했습니다.
- **월간 캘린더 + 위험일 하이라이트** — 과거/현재는 기상청 ASOS 일자료(실측 강수량),
  미래(단기예보가 닿는 ~3일)는 **Ready-Flow 백엔드가 거주지 자치구 격자로 기상청 단기예보를
  직접 호출**해 날짜별 침수확률을 계산하고 **가장 위험한 날짜와 %**를 강조합니다.
  CORS 때문에 막히던 웹에서도 백엔드 프록시(`/api/forecast/flood-week`)로 동작합니다.
- **대피소/주민제보/커머스** 등 실 API가 없는 콘텐츠는 **`예시` 배지**로 명시

> 데이터 출처가 없는 값은 화면에 '실시간'처럼 표기하지 않습니다. 데이터를 못 불러오면
> 숫자를 지어내지 않고 `—`(데이터 없음)로 표시합니다.

---

## 🚀 빠른 시작 (클론 후 실행)

### 1. 사전 준비
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 설치 (`flutter --version` ≥ 3.10)
- 웹 실행용 Chrome

### 2. 클론 & 의존성 설치
```bash
git clone <this-repo-url>
cd home_protector
flutter pub get
```

### 3. (선택) 환경 변수 설정
키 없이도 **바로 실행됩니다** (웹 지도용 공개 키가 `web/index.html`에 포함되어 있고,
예측 API는 인증이 필요 없습니다). 본인 키로 교체하려면:
```bash
cp .env.example .env   # .env 는 git 에 커밋되지 않습니다
```
→ 자세한 키 설정은 [환경 변수](#-환경-변수) 참고.

### 4. 실행 — 웹 (포트 56940 고정)
카카오 지도 도메인 등록과 일치시키기 위해 **웹 포트를 `56940`으로 고정**합니다.
```bash
./run.sh                 # = flutter run -d chrome --web-hostname localhost --web-port 56940
```
또는 직접:
```bash
flutter run -d chrome --web-hostname localhost --web-port 56940
```
VS Code 사용자는 실행 패널에서 **“HomeProtector (Chrome · :56940)”** 구성을 선택하면 됩니다.

브라우저에서 → http://localhost:56940

### 5. 실행 — 모바일 (실기기/에뮬레이터)
```bash
./run.sh device          # 또는: flutter run
```

---

## 🔑 환경 변수

| 변수 | 용도 | 필수 |
|---|---|---|
| `KAKAO_JS_KEY` | 웹 카카오 지도 (공개 클라이언트 키) | 웹 지도 사용 시 |
| `KAKAO_NATIVE_KEY` | 네이티브 카카오 SDK (현재 빌드 미사용) | ✗ |
| `KMA_SERVICE_KEY` | 기상청 특보 조회 (알림 탭 실시간 특보) | 실시간 특보 사용 시 |
| `CORS_PROXY` | 웹에서 기상청 API 호출용 자체 CORS 프록시 (모바일은 불필요) | ✗ |
| `FLOOD_API_BASE_URL` | 예측 API 베이스 URL 오버라이드 | ✗ |

> **기상청 특보 키**: [공공데이터포털](https://www.data.go.kr/data/15000415/openapi.do) →
> "기상청_기상특보 조회서비스" 활용신청 → 발급된 **일반 인증키(Encoding)** 를 `.env` 의
> `KMA_SERVICE_KEY` 에 넣으면 `run.sh` 가 `--dart-define` 으로 주입합니다. 미설정 시 알림 탭은
> 데모 없이 '연동 대기'로 표시됩니다.
> ⚠️ data.go.kr 은 CORS 미지원이라 **웹 브라우저에서는 차단**됩니다. **모바일(APK/iOS)** 에서는
> 직접 호출되어 정상 동작합니다(검증: 약 280ms). 공개 CORS 프록시(allorigins 등)는 현재
> 불안정/유료라 기본으로 쓰지 않으며, 웹에서 쓰려면 아래처럼 **자체 프록시**를 띄우세요.

<details>
<summary>웹에서 기상청 특보/일자료를 쓰려면 — Cloudflare Worker 프록시 예시</summary>

```js
// Cloudflare Worker — ?url= 뒤의 대상 URL 을 대신 호출하고 CORS 헤더를 붙여 반환
export default {
  async fetch(req) {
    const target = new URL(req.url).searchParams.get('url');
    if (!target) return new Response('missing url', { status: 400 });
    const r = await fetch(target);
    const h = new Headers(r.headers);
    h.set('Access-Control-Allow-Origin', '*');
    return new Response(r.body, { status: r.status, headers: h });
  }
}
```

배포 후 `.env` 에 `CORS_PROXY=https://<your-worker>.workers.dev/?url=` 를 추가하면 웹에서도 동작합니다.
</details>

- **Kakao JS 키**는 브라우저에 노출되는 *공개* 키로, `web/index.html`에 포함되어 있습니다.
  본인 키로 바꾸려면 `web/index.html`의 `appkey` 값을 교체하고,
  [카카오 개발자센터](https://developers.kakao.com) → 내 앱 → 플랫폼 → **Web 사이트 도메인**에
  `http://localhost:56940`을 등록하세요.
- **예측 API 베이스 URL**을 바꾸려면 빌드 시 주입합니다:
  ```bash
  flutter run -d chrome --web-port 56940 --dart-define=FLOOD_API_BASE_URL=https://my-api.example.com
  ```

---

## 🧱 아키텍처

```
lib/
├─ main.dart                      앱 진입점 · 테마 · 시스템 UI
├─ models/
│  └─ user_model.dart             거주지/건물유형 · 법정동코드(adm_cd)
├─ services/
│  ├─ flood_api_service.dart      Ready-Flow API 클라이언트 (health/predict/dongs/flood-week) + 커버리지 해석
│  ├─ address_result.dart         주소 SDK 결과 공통 모델 (sido/sigungu/bname/lat/lon)
│  ├─ address_search.dart         주소 SDK 모달 단일 진입점 (조건부 import)
│  ├─ address_search_{web,mobile,stub}.dart  웹=다음 우편번호 JS / 모바일=kpostal
│  ├─ kma_daily_service.dart      기상청 ASOS 일자료 (캘린더 과거 실측 강수량)
│  └─ weather_warning_service.dart 기상청 기상특보 조회 (실시간 특보)
├─ providers/
│  └─ app_provider.dart           전역 상태 · 예측/주간예보 요청 · 위험도
├─ screens/
│  ├─ splash_screen.dart          로그인(소셜 데모)
│  ├─ setup_screen.dart           주소(SDK)·건물유형 선택
│  └─ dashboard_screen.dart       홈/지도/알림/캘린더/대비계획 탭
└─ widgets/
   ├─ home_address_flow.dart      주소 SDK → 커버리지 해석 → (필요 시)지원 지역 선택 공통 흐름
   ├─ dong_picker.dart            /api/dongs 기반 지원 지역 선택 모달 (커버리지 밖 폴백)
   ├─ live_flood_card.dart        /api/predict 실시간 결과 카드
   ├─ alert_banner.dart · ...     위험도 연출 위젯
   └─ kakao_map_{web,mobile,stub}.dart   플랫폼별 지도 (조건부 import, 집 핀 고정)
```

**위험도는 단일 출처(실측 API)에서만 파생**합니다:
- `floodProbability` → `apiPredict?.percent` (없으면 `null` → UI에 `—`)
- 경보 배너·위험단계·게이지·지도 위험표시 모두 이 값을 사용
- 강우 입력(`forecast_daily_rain`)은 실시간 강우예보 연동 전까지 문서화된 기본 가정치이며,
  화면에 '실측 강수량'으로 표기하지 않습니다
- 기상특보(`weather_warning_service`)는 별도 출처(KMA)로 알림 탭에만 사용

---

## 🌐 API 연동

전체 명세는 [`ENDPOINT.md`](./ENDPOINT.md) 참고. 요약:

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/api/health` | 헬스체크 + 커버리지 동 수 |
| `GET` | `/api/dongs` | 예측 가능한 서울 93개 법정동 목록 (선택 UI용) |
| `POST` | `/api/predict` | 침수 확률 예측 (`adm_cd` 또는 `address` + 일강우 시퀀스) |
| `GET` | `/api/forecast/flood-week` | 백엔드가 기상청 단기예보를 호출해 향후 7일 침수확률/최고 위험일 계산 |

> 커버리지는 **서울 침수 이력 93개 법정동**입니다. 그 외 지역은 `404`를 반환하므로,
> 앱은 주소 SDK 로 받은 동/구를 커버리지로 해석(정확→구근사→폴백)합니다.

> **`/api/forecast/flood-week` 사용 조건** (백엔드 = `doubled_seven`/Ready-Flow-AI):
> 백엔드가 서버에서 기상청 **단기예보(`getVilageFcst`)** 를 호출하므로,
> 1) 백엔드 Vercel 프로젝트에 `KMA_SERVICE_KEY` 환경변수 설정,
> 2) 그 키가 data.go.kr 에서 **"기상청_단기예보 조회서비스(VilageFcstInfoService_2.0)"** 에
>    활용신청되어 있어야 합니다(기상특보·ASOS와는 별개 신청). 미신청 시 `503` + 안내 메시지를
>    반환하고, 캘린더는 과거 실측만 표시합니다.

> ⚠️ **예측 모델 자체의 한계**: 라이브 검증 결과 `flood_probability`가 강우 크기에 거의
> 무감각하고 비단조적입니다(실제 침수일도 ~8%). 상세 분석·개선 제안은 [`PREDICTION.md`](./PREDICTION.md) 참고.

---

## ✅ 검증

```bash
flutter analyze          # 정적 분석 (경고 0 목표)
flutter test             # 위젯/유닛 테스트
flutter build web        # 웹 프로덕션 빌드 → build/web
```

## 📦 배포 (웹)

```bash
flutter build web --release
# build/web 디렉터리를 정적 호스팅(Vercel/Netlify/GitHub Pages 등)에 업로드
```
> 배포 도메인을 카카오 개발자센터의 허용 도메인에 추가해야 지도가 로드됩니다.

### Vercel

이 앱은 Flutter 웹 정적 산출물(`build/web`)을 배포해야 합니다. 루트 디렉터리를 그대로
정적 사이트로 배포하면 `index.html`이 없어 `404: NOT_FOUND`가 날 수 있습니다.

```bash
flutter build web --release --base-href /
vercel deploy build/web --prod
```

Git 연동 배포를 사용할 때는 루트 [`vercel.json`](./vercel.json)이 Flutter를 빌드한 뒤
`build/web`을 출력 디렉터리로 쓰도록 설정합니다.

---

## 📄 라이선스 / 고지

- 침수 예측 모델: Ready-Flow AI (`doubled_seven`)
- 본 앱의 대피소·제보·상품·연락처 등 일부 콘텐츠는 **데모용 예시 데이터**입니다.
