import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// 앱 전체 설정을 관리하는 클래스
/// 모든 필터값, 타임프레임 등의 공통 설정 포함
class AppConfig {
  // 거래 필터 값 (금액 기준)
  static final List<double> tradeFilters = [
    2000000.0,
    5000000.0,
    10000000.0,
    20000000.0,
    50000000.0,
    100000000.0,
    200000000.0,
    300000000.0,
    400000000.0,
    500000000.0,
    1000000000.0,
  ];

  // 거래 필터에 대한 표시명
  static final Map<double, String> filterNames = {
    2000000.0: '2백만',
    5000000.0: '5백만',
    10000000.0: '1천만',
    20000000.0: '2천만',
    50000000.0: '5천만',
    100000000.0: '1억',
    200000000.0: '2억',
    300000000.0: '3억',
    400000000.0: '4억',
    500000000.0: '5억',
    1000000000.0: '10억',
  };

  // 타임프레임 값 (분 단위)
  static final List<int> timeFrames = [
    1,
    5,
    15,
    30,
    60,
    120,
    240,
    480,
    720,
    1440,
  ];

  // 타임프레임 표시명
  static final Map<int, String> timeFrameNames = {
    1: '1분',
    5: '5분',
    15: '15분',
    30: '30분',
    60: '1시간',
    120: '2시간',
    240: '4시간',
    480: '8시간',
    720: '12시간',
    1440: '1일',
  };

  // 거래 병합 윈도우 (밀리초)
  static const int mergeWindowMs = 1000;
  
  // 시스템 설정
  static const int maxCacheSize = 1000;       // 캐시 최대 크기
  static const int maxListSize = 200;         // 리스트 최대 크기 
  static const int batchSize = 50;            // 배치 처리 사이즈
  static const int throttleMs = 300;          // 스로틀링 간격 (밀리초)
  static const int uiUpdateIntervalMs = 200;  // UI 업데이트 간격
  static const double momentaryMinAmount = 500000.0; // 순간거래 최소 금액
  static const double surgeThreshold = 1.1;   // 급등 기준치 (퍼센트)
  
  // 플랫폼별 소켓 설정
  static const Map<String, String> webSocketUrls = {
    'upbit': 'wss://api.upbit.com/websocket/v1',
    'binance': 'wss://stream.binance.com:9443/ws',
    'bybit': 'wss://stream.bybit.com/v5/public/spot',
    'bithumb': 'wss://pubwss.bithumb.com/pub/ws',
  };
  
  // 플랫폼별 API 설정
  static const Map<String, String> apiBaseUrls = {
    'upbit': 'https://api.upbit.com/v1',
    'binance': 'https://api.binance.com',
    'bybit': 'https://api.bybit.com',
    'bithumb': 'https://api.bithumb.com',
  };
  
  // 성능 관련 설정
  static const bool enableLogging = false;    // 로깅 활성화 여부
  static const bool useIsolates = true;       // 격리 처리 사용 여부
  static const bool useObjectPool = true;     // 객체 풀 사용 여부
  static const int maxTradesPerSecond = 500;  // 초당 최대 처리 거래수
}

/// 앱 설정 컨트롤러 (동적 설정 관리)
class AppConfigController extends GetxController {
  // 현재 선택된 거래소 플랫폼
  final RxString platform = 'upbit'.obs;
  
  // 현재 선택된 테마 모드
  final RxString themeMode = 'system'.obs;
  
  // 로컬 저장소 키
  static const String themeModeKey = 'themeMode';
  static const String platformKey = 'platform';
  static const String sliderPositionKey = 'sliderPosition';
  
  // UI 컨트롤
  final RxString sliderPosition = 'top'.obs;
  final RxBool keepScreenOn = false.obs;
  
  // 업데이트 가능한 필터 목록
  final RxList<double> tradeFilters = AppConfig.tradeFilters.obs;
  
  // 로컬 저장소 객체
  late final GetStorage _storage;
  
  void setPlatform(String newPlatform) {
    platform.value = newPlatform;
    _storage.write(platformKey, newPlatform);
  }
  
  void setThemeMode(String mode) {
    themeMode.value = mode;
    _storage.write(themeModeKey, mode);
  }
  
  void setSliderPosition(String position) {
    sliderPosition.value = position; 
    _storage.write(sliderPositionKey, position);
  }
  
  void setKeepScreenOn(bool value) {
    keepScreenOn.value = value;
    _storage.write('keepScreenOn', value);
  }
  
  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<GetStorage>();
    _loadSettings();
  }
  
  void _loadSettings() {
    final storedThemeMode = _storage.read<String>(themeModeKey);
    if (storedThemeMode != null) themeMode.value = storedThemeMode;
    
    final storedPlatform = _storage.read<String>(platformKey);
    if (storedPlatform != null) platform.value = storedPlatform;
    
    final storedSliderPosition = _storage.read<String>(sliderPositionKey);
    if (storedSliderPosition != null) sliderPosition.value = storedSliderPosition;
    
    final storedKeepScreenOn = _storage.read<bool>('keepScreenOn');
    if (storedKeepScreenOn != null) keepScreenOn.value = storedKeepScreenOn;
  }
}