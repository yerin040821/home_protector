# 🏠 HomeProtector · 홈프로텍터

> 사계절 생활재난 보호 서비스 — 서울 법정동 단위 **AI 침수 위험 예측** 모바일/웹 앱

반지하·저지대 거주자를 위한 침수 대비 서비스입니다. 거주 지역과 건물 유형을 선택하면
[Ready-Flow AI 침수 예측 API](https://ready-flow-ai.vercel.app/docs)로부터 **실시간 침수 확률**을
받아오고, 대피소·체크리스트·카드뉴스·긴급 연락처 등 행동 지침을 한 화면에서 제공합니다.

| | |
|---|---|
| **Framework** | Flutter (Dart `^3.10.9`) · Material 3 |
| **상태관리** | `provider` |
| **차트** | `fl_chart` |
| **지도** | Kakao Maps JS SDK (웹) |
| **예측 API** | Ready-Flow AI — Seoul Flood Risk API (인증 불필요) |
| **데모 지역** | 서울 관악구 신림동 (2022 침수 피해 지역, API 커버리지 내) |

---

## ✨ 주요 기능

- **실시간 AI 침수 확률** — `/api/predict` 결과를 홈 화면 *Ready-Flow AI 실시간 예측* 카드에 표시
- **지원 지역 강제 선택** — 자유 입력 대신 `/api/dongs` 커버리지 목록 기반 검색 모달로
  주소를 선택하므로, 선택값에 항상 법정동코드(`adm_cd`)가 실려 예측이 **404 없이** 해결됩니다
- **시나리오 위험도 엔진** — 강수량·고도·배수량·건물유형 가중치로 계산한 보조 위험 지표 (경보 배너·게이지)
- **대피소/알림/캘린더/대비 체크리스트/카드뉴스/긴급 연락처** 탭

> 참고: 외부 AI 모델의 실측 확률(보통 낮음)과 앱 자체 *시나리오 위험도*(연출용)는
> 각각 별도 카드로 **구분 표시**합니다. 자세한 설계는 아래 [아키텍처](#-아키텍처) 참고.

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
| `FLOOD_API_BASE_URL` | 예측 API 베이스 URL 오버라이드 | ✗ |

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
│  └─ flood_api_service.dart      Ready-Flow API 클라이언트 (health/predict/dongs)
├─ providers/
│  └─ app_provider.dart           전역 상태 · 예측 요청 · 시나리오 위험도 엔진
├─ screens/
│  ├─ splash_screen.dart          로그인(소셜 데모)
│  ├─ setup_screen.dart           지역·건물유형 선택 (지원 지역 모달)
│  └─ dashboard_screen.dart       홈/지도/알림/캘린더/대비계획 탭
└─ widgets/
   ├─ dong_picker.dart            /api/dongs 기반 지원 지역 검색 모달  ← 주소 강제 선택
   ├─ live_flood_card.dart        /api/predict 실시간 결과 카드
   ├─ alert_banner.dart · ...     시나리오 위험도 연출 위젯
   └─ kakao_map_{web,mobile,stub}.dart   플랫폼별 지도 (조건부 import)
```

**두 가지 위험 지표를 분리**합니다:
1. **Ready-Flow AI 실측 확률** (`apiPredict`) — 외부 머신러닝 모델의 `flood_probability ∈ [0,1]`.
   `LiveFloodCard`에 법정동 라벨과 함께 솔직하게 표시.
2. **시나리오 위험도** (`floodProbability`) — 앱 자체의 가중치 계산. 경보 배너·게이지 등
   리치 UI 연출용 보조 지표.

---

## 🌐 API 연동

전체 명세는 [`ENDPOINT.md`](./ENDPOINT.md) 참고. 요약:

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/api/health` | 헬스체크 + 커버리지 동 수 |
| `GET` | `/api/dongs` | 예측 가능한 서울 93개 법정동 목록 (선택 UI용) |
| `POST` | `/api/predict` | 침수 확률 예측 (`adm_cd` 또는 `address` + 일강우 시퀀스) |

> 커버리지는 **서울 침수 이력 93개 법정동**입니다. 그 외 지역은 `404`를 반환하므로,
> 앱은 `/api/dongs` 목록에서만 주소를 선택하도록 강제합니다.

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

---

## 📄 라이선스 / 고지

- 침수 예측 모델: Ready-Flow AI (`doubled_seven`)
- 본 앱의 대피소·제보·상품·연락처 등 일부 콘텐츠는 **데모용 예시 데이터**입니다.
