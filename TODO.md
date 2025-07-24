You are a Flutter/Dart developer tasked with enhancing the `local_storage_service.dart` file in the Memora project. Please implement the following features:

---

## 1. Comment out legacy memory‑training code
- Locate methods like `saveChatHistory` and `loadChatHistory` related to the old memory training feature.
- Surround them with `// TODO: deprecated` comments or comment them out entirely, keeping the code in place for reference.

## 2. Add streak tracking functionality
- Add a method `incrementStreak(String userId, DateTime date)` that:
  - Uses SharedPreferences keys `streak_count_<userId>` and `streak_date_<userId>`.
  - Checks if the user studied the day before. If yes, increments the streak; if no, resets it to 1.
- Add `Future<int?> loadStreakCount(String userId)` to fetch the current streak count.

## 3. Implement heat‑map session recording
- Add `recordSession(String userId, DateTime date)`:
  - Stores daily session counts in SharedPreferences under a JSON key `session_map_<userId>`.
- Add `Future<Map<String, int>> loadSessionMap(String userId)` to retrieve the date→count map.

## 4. Support user‑level settings and daily‑goal calculation
- Add `saveUserLevel(String userId, String level)` where level ∈ {“expert”, “intermediate”, “beginner”}.
- Add `Future<String?> loadUserLevel(String userId)` to retrieve the user’s level.
- Add `Future<int> getDailyGoal(String userId)` that returns the numeric daily goal based on level:
  - expert → 7 sessions/day
  - intermediate → 5 sessions/day
  - beginner → 3 sessions/day

## 5. Render Notion DB data as Markdown
- Integrate Notion API (or `notion_api`), and `flutter_markdown` package.
- Add `Future<String> renderNotionDbAsMarkdown(String pageId)` that:
  - Fetches Notion page content via Notion Blocks API.
  - Converts the JSON response into Markdown format (either via custom logic or a library like `notion-to-md`).
  - Returns a Markdown string to be displayed in a widget, e.g. `Markdown(data: ...)`.

## 6. Unit Tests
- Create `local_storage_service_test.dart` containing tests for:
  - streak behavior (increment vs reset based on dates)
  - session recording and retrieval
  - setting and loading user level, and validating `getDailyGoal` values
  - calling `renderNotionDbAsMarkdown` and verifying Markdown output format

---

### Requirements
- Use SharedPreferences for persistent storage
- Follow existing code style and null‑safety conventions
- Use unique keys per user (`<feature>_<userId>`)
- Only modify `local_storage_service.dart` and add the test file; do not change other parts of the project


Please implement everything within this scope only.