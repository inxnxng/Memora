class AppStrings {
  // Profile Screen
  static const String profileTitle = '내 정보';
  static const String noName = '이름 없음';
  static const String streak = '스트릭';
  static const String proficiency = '숙련도';
  static const String notSet = '미설정';

  // Ranking Card
  static const String rankingInfo = '랭킹 정보';
  static const String myCurrentRank = '현재 나의 랭킹';
  static const String noRank = '랭킹 없음';
  static const String checkFullRanking = '전체 랭킹 확인하기';

  // Edit Profile Card
  static const String editProfile = '프로필 수정';
  static const String nameLabel = '이름';
  static const String save = '저장';
  static const String profileSavedMessage = '프로필이 저장되었습니다.';

  // Logout
  static const String logout = '로그아웃';

  // Dialog
  static const String close = '닫기';

  // Login Screen
  static const String loginTitle = '로그인';
  static const String signInWithGoogle = 'Google 계정으로 로그인';
  static const String loginFailed = '로그인에 실패했습니다. 다시 시도해주세요.';

  // Onboarding Screen
  static const String welcomeToMemora = 'Memora에 오신 것을 환영합니다!';
  static const String personalizeExperience = '더 나은 사용을 위해, 당신의 학습 레벨을 선택해주세요.';
  static const String getStarted = '시작하기';
  static const String selectYourLevel = '레벨 선택';
  static const String saveAndContinue = '저장하고 계속하기';
  static String dailyGoal(int count) => '하루 $count번 학습';

  // TIL Review Selection Screen
  static const String tilReviewSelectionTitle = 'TIL 복습 주제 선택';
  static const String noNotionPagesFound =
      'Notion 페이지를 찾을 수 없습니다. 설정에서 API 키와 데이터베이스 ID를 확인해주세요.';
  static const String noTitle = '제목 없음';
  static const String loadingPageContent = '페이지 내용을 불러오는 중...';
  static const String startTraining = '훈련 시작';
  static const String pageContentLoadFailed = '페이지 내용을 불러오는 데 실패했습니다.';
  static const String unknownDb = '알 수 없는 DB';

  // Home Screen
  static const String appName = '🧠 Memora';
  static const String tilReview = 'TIL 복습';
  static const String notionConnected = 'Notion DB 연결됨';
  static const String notionConnectionNeeded = 'Notion 연결 필요';
  static const String learningRecord = '학습 기록';

  // Heatmap Screen
  static const String heatmapTitle = '학습 현황';
  static const String detailedLearningRecord = '학습 상세 기록';
  static const String noLearningRecord = '학습 기록이 없습니다.';
  static String totalLearningCount(int count) => '총 $count회 학습';
  static String databasePrefix(String name) => 'DB: $name';
  static String formattedDate(int year, int month, int day) =>
      '$year년 $month월 $day일';
}
