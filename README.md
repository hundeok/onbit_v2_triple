# 🧠 onbit_v2_triple

[![Flutter CI](https://github.com/hundeok/onbit_v2_triple/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/hundeok/onbit_v2_triple/actions/workflows/flutter_ci.yml)
[![Code Coverage](https://codecov.io/gh/hundeok/onbit_v2_triple/branch/main/graph/badge.svg?token=5182d729-a03f-4417-8aea-7687b9307e84)](https://codecov.io/gh/hundeok/onbit_v2_triple)
![Branch](https://img.shields.io/badge/branch-main-blue)

---

## 🧠 프로젝트 개요

**AI 기반 트리플 협업 코인 프로젝트**  
GPT + Claude + Groq 구조로 구성된 초고속 자동화 시스템.  
실전 클린 아키텍처 기준으로 설계된 고성능 크립토 분석 앱입니다.

---

## 🧩 프로젝트 구조

- `core/` → 공통 유틸, DI, 설정, 테마, 라우팅
- `data/` → API, 소켓, DB 등 구현체
- `domain/` → Entity, Repository 인터페이스, UseCase
- `presentation/` → UI, 컨트롤러, 상태관리

> ✅ `4 Layer Clean Architecture`  
> ✅ `GetX 기반 단방향 흐름`  
> ✅ `AI 협업 + 유지보수 최적화`

---

## ✅ 기능 목표

- 실시간 코인 트레이드 데이터 분석 및 시각화
- AI 3단계 협업 기반 전략 설계 로직 탑재
- 자동화 트레이딩 & 실시간 알림 이벤트 처리
- 기술 부채 최소화 + 확장성과 생산성 최우선 구조

---

## 🚀 실행 방법

```bash
flutter pub get
bash tool/watch_build.sh     # json_serializable 자동 생성
flutter run
🧪 테스트

flutter test
flutter test --coverage
통합 테스트: test/integration/app_flow_test.dart
커버리지 목표: 80% 이상
활용 도구: mockito, patrol, mock_server
🧠 설계 철학

항목	기준
파일명	snake_case.dart
클래스명	PascalCase
import 규칙	같은 레이어: 상대경로 / 크로스 레이어: package:onbit_v2_triple/
DI 구조	Get.lazyPut(() => X(), tag: 'data.xxx'), fenix: false
에러 핸들링	Result<T> or Either<Failure, T> + .fold() + 메시지 매핑
상태 공유	Controller 단위 최소화, Get.putAsync() 실패 시 재시도 포함
기술 부채 추적	// TODO: [TECH-DEBT] + GitHub Issues + P1/P2/P3 태그
🌍 다국어 지원 (i18n)

arb 파일: en.arb, ko.arb
flutter gen-l10n 자동 생성
l10n.yaml: nullable-getter: false 설정
🚧 CI/CD

GitHub Actions 자동화 파이프라인:
flutter analyze
flutter test
flutter build --release --obfuscate
flutter build --analyze-size
문서 포함: CHANGELOG.md, CONTRIBUTING.md
브랜치 네이밍 규칙:
feature/socket-stream
fix/trade-bug
📈 성능 모니터링

PerformanceOverlay 사용 + build --profile 모드
StreamQueue 메모리 최적화, compute() 구조 점검
Rx: throttle, debounce 연산 적용
🔐 프로덕션 디테일

보안:
SSL 핀닝 (Dio 인증서 고정)
Secure Storage → timeout + catch 처리
로깅:
10MB 이상 자동 로그 회전
gzip 압축 + Crashlytics 연동
UX 안정성:
Skeleton Loader, Fallback UI
ConnectionStatusBar 상태 표시 및 재시도 버튼
📦 실행 우선순위 (Phase 1)

core/config/app_config.dart, env_config.dart
data/datasources/socket_trade_source.dart
presentation/widgets/trade_card.dart, skeleton_loader.dart
domain/usecases/get_filtered_trades.dart
test/integration/app_flow_test.dart
📎 문서 & 참고

docs/extension_points.md → 기능 확장 기준
analysis_options.yaml → 정적 분석 규칙
tool/watch_build.sh → json 자동 빌드 스크립트
build.yaml → explicit_to_json: true
✊ 프로젝트 선언

이 리포지토리는 단순한 앱이 아닙니다.
AI 협업 × 온체인 품질 기준 × 실전 로직이 결합된
풀스택 고성능 크립토 시스템의 시작점입니다.

📌 모든 협업자 및 AI Agent는 위 구조를 기반으로
클래스, 파일, 유즈케이스, 컨트롤러 등을 정확히 생성하세요.