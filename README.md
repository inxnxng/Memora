# Memora

> 🧠 기억력 훈련 iOS 앱 - Flutter 기반

기억력 향상을 위한 매일의 훈련을 제공하고, 친구와의 경쟁 및 습관 형성을 통해 지속적으로 성장할 수 있도록 돕는 iOS 전용 Flutter 앱입니다.

---

## ✅ 핵심 목표
- **친구와의 경쟁** 및 성장 지표 제공
- **알림**을 통한 꾸준한 동기부여

1. 사용자의 **단기 및 장기 기억력 향상**
- **30일 루틴 기반** 훈련 시스템으로 습관화 유도

2. **TIL 노션 DB 연동**을 통한 복습 시스템 제공
- **하루 하나의 과제**로 뇌를 자극하는 지속적 훈련

---

## 🧩 주요 기능

| 기능 | 설명 |
|------|------|
| 🔹 일일 훈련 제공 | 매일 하나의 기억력 훈련 과제를 카드 형식으로 제공 |
| 🔹 완료 체크 | 사용자는 완료 버튼으로 훈련 완료 여부를 저장 |
| 🔹 루틴 트래킹 | 30일 루틴 진행 상황 시각화 |
| 🔹 Firebase 저장 | 훈련 기록을 Firebase Firestore에 저장 및 동기화 |
| 🔹 친구 경쟁 (랭킹 v1) | Firebase를 기반으로 다른 사용자와 루틴 진행률 비교 |
| 🔹 알림 기능 | 매일 알림을 통해 사용자에게 훈련 리마인드 |
| 🔹 Notion 연동 | 사용자의 TIL 노션 DB를 연동해 복습 콘텐츠 제공 |

---

## 🗂️ 기술 스택 및 구성

- **개발 프레임워크:** Flutter
- **플랫폼:** iOS (우선 개발)
- **데이터 저장소:**
  - Local DB (예: `shared_preferences`, `hive`)
  - Firebase Firestore

- **인증:** Firebase Auth (익명 또는 Apple ID)
- **노션 연동:** Notion API + 사용자 토큰

---

## 🧱 디렉토리 구조 (예정)

lib/
├── main.dart
├── screens/
│   ├── home_screen.dart
│   ├── task_screen.dart
│   └── notion_review_screen.dart
├── models/
│   ├── task_model.dart
│   └── notion_til_model.dart
├── services/
│   ├── firebase_service.dart
│   ├── notification_service.dart
│   └── notion_service.dart
├── providers/
│   └── task_provider.dart
├── utils/
│   └── date_util.dart
└── constants/
└── task_list.dart

---

## 🚧 개발 단계 로드맵 (v1)

1. [ ] **홈 화면 + 일일 과제 카드 UI**
2. [ ] **Firebase Firestore 연동 (루틴 진행 저장)**
3. [ ] **일일 알림 기능 구현**
4. [ ] **30일 루틴 진행률 표시**
5. [ ] **친구 간 랭킹 시스템 UI (기본 통계 제공)**
6. [ ] **노션 DB 연동**
   - [ ] 사용자 노션 토큰/DB ID 등록
   - [ ] TIL 항목 가져오기
   - [ ] 랜덤 카드 복습 UI 구성
7. [ ] openai 연동하여 훈련에 필요한 데이터를 생성하거나, 챗봇 시스템을 만들기
    - [ ] 노션 db 데이터를 읽어서 팝 퀴즈를 만들기
    - [ ] 기억력 훈련에 필요한 데일리 퀘스트 생성 및 앞으로의 진행을 위한 가이드 챗봇 만들기
---

## 📌 Notion 연동 관련 참고

- Notion API 사용 (https://developers.notion.com/)
- 사용자가 제공한 `integration token`과 `database_id` 필요
- 필터링 예: 오늘 작성한 TIL, 지난 일주일 내 작성 내용 복습
- UI는 **랜덤 카드 형식** 또는 **리스트 + 필터** 방식

---

## 📱 배포 및 사용 대상

- **앱스토어 출시 전 MVP**: iOS TestFlight로 개인 테스트
- **대상 사용자**: 기억력 향상을 원하거나 일상을 구조화하고 싶은 사용자
- **추후 계획**: Android 확장, 친구 초대/팔로우 시스템, 퀴즈 기반 회고 추가



firebase apps:create ios memora (macos) --bundle-id=com.inkyung.memora --json --project=memora-a49c9