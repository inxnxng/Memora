import 'package:flutter/widgets.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/services/task_service.dart';

/// 작업(Task) 및 학습 관련 데이터(히트맵)의 상태를 관리합니다.
///
/// 이 Provider는 다음과 같은 역할을 담당합니다:
/// - 데이터 소스에서 작업 목록을 가져옵니다.
/// - 작업 완료 진행률을 추적합니다.
/// - 학습 히트맵 데이터를 관리하고 제공합니다.
/// - 상태 변경 시 리스너에게 알려 UI를 업데이트합니다.
class TaskProvider with ChangeNotifier {
  /// 작업 데이터에 대한 백엔드 또는 로컬 저장소와 상호 작용하는 서비스 계층입니다.
  /// `final`로 선언되어 Provider의 생명주기 동안 변경되지 않습니다.
  final TaskService _taskService;

  /// 작업을 가져올 Notion 데이터베이스의 ID입니다.
  /// 이 값은 선택 사항이며 초기화 시에만 사용됩니다. 한 번 설정된 후에는 변경되지 않도록 `final`로 선언됩니다.
  final String? _notionDatabaseId;

  /// 작업 목록을 저장하는 내부 변수입니다.
  /// private 변수와 public getter를 사용하여 UI에서 직접 목록을 수정하는 것을 방지합니다.
  List<Task> _tasks = [];

  /// 데이터 로딩 상태를 추적하는 내부 플래그입니다.
  /// 데이터를 가져오는 동안 UI에 로딩 인디케이터를 표시하는 데 유용합니다.
  bool _isLoading = true;

  /// 히트맵 데이터를 저장하는 내부 변수입니다.
  /// 키는 날짜(DateTime), 값은 해당 날짜의 학습 세션 횟수입니다.
  Map<DateTime, List<Map<String, dynamic>>> _heatmapData = {};

  /// TaskProvider의 생성자입니다.
  ///
  /// 데이터 작업을 위한 [TaskService]와 선택적인 [notionDatabaseId]가 필요합니다.
  /// 생성 즉시 데이터 초기화 프로세스를 시작합니다.
  TaskProvider({required TaskService taskService, String? notionDatabaseId})
    : _taskService = taskService,
      _notionDatabaseId = notionDatabaseId {
    _initialize();
  }

  // --- Public Getters ---

  /// 작업 목록에 대한 public getter입니다.
  List<Task> get tasks => _tasks;

  /// 로딩 상태에 대한 public getter입니다.
  bool get isLoading => _isLoading;

  /// 작업 완료 진행률을 계산합니다.
  /// 0.0에서 1.0 사이의 값을 반환하며, 작업이 없으면 0.0을 반환합니다.
  double get progress => _tasks.isEmpty
      ? 0.0
      : _tasks.where((task) => task.isCompleted).length / _tasks.length;

  /// 히트맵 데이터에 대한 public getter입니다.
  Map<DateTime, List<Map<String, dynamic>>> get heatmapData => _heatmapData;

  // --- Private and Public Methods ---

  /// 작업 및 히트맵에 대한 초기 데이터를 가져옵니다.
  ///
  /// 이 메소드는 Provider가 생성될 때 호출됩니다. 로딩 상태를 설정하고,
  /// 필요한 모든 데이터를 가져온 후 리스너에게 알려 UI를 업데이트합니다.
  Future<void> _initialize() async {
    _isLoading = true;
    // 위젯 빌드 중에 Provider가 생성될 경우를 대비하여 microtask로 리스너를 호출합니다.
    Future.microtask(notifyListeners);

    // 성능 향상을 위해 작업 및 히트맵 데이터를 병렬로 가져옵니다.
    await Future.wait([
      _fetchTasks(),
      fetchHeatmapData(notify: false), // 데이터 로딩 후 마지막에 한 번만 UI를 업데이트합니다.
    ]);

    _isLoading = false;
    // 초기화가 완료되고 데이터가 준비되었음을 리스너에게 알립니다.
    Future.microtask(() => notifyListeners());
  }

  /// TaskService에서 작업 목록을 가져옵니다.
  Future<void> _fetchTasks() async {
    _tasks = await _taskService.getTasks(_notionDatabaseId);
    // 이 메소드는 초기화 흐름의 일부이므로, UI 업데이트는 호출자인 _initialize에서 처리합니다.
  }

  /// 특정 작업의 완료 상태를 토글합니다.
  ///
  /// [taskId]로 작업을 찾아 `isCompleted` 상태를 반전시킨 후,
  /// 리스너에게 알려 UI를 업데이트합니다.
  /// 참고: 이 구현은 로컬 상태만 업데이트합니다.
  Future<void> toggleTaskCompletion(String taskId) async {
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].isCompleted = !_tasks[taskIndex].isCompleted;
      Future.microtask(() => notifyListeners());
    }
  }

  /// 오늘 날짜로 학습 기록을 추가합니다.
  ///
  /// 사용자가 학습 세션을 완료했을 때 호출됩니다.
  /// 기록을 추가한 후, 변경사항을 반영하기 위해 히트맵 데이터를 새로고침합니다.
  Future<void> addStudyRecordForToday({
    required String databaseName,
    required String title,
  }) async {
    await _taskService.addStudyRecordForToday(
      databaseName: databaseName,
      title: title,
    );
    // 히트맵 데이터를 새로고침하고 UI에 변경사항을 알립니다.
    await fetchHeatmapData();
  }

  /// TaskService에서 최신 히트맵 데이터를 가져옵니다.
  ///
  /// 선택적 파라미터 [notify]는 `notifyListeners` 호출 여부를 제어합니다.
  /// 이는 `_initialize`와 같이 여러 상태 업데이트를 한 번에 처리할 때 유용합니다.
  Future<void> fetchHeatmapData({bool notify = true}) async {
    _heatmapData = await _taskService.getHeatmapData();
    if (notify) {
      Future.microtask(() => notifyListeners());
    }
  }
}
