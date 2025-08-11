## ANDROID
flutter clean \
&& flutter pub get \
&& flutter build appbundle --release


> 파일 경로
build/app/outputs/bundle/release/app-release.aab
> 업로드
Go to the Google Play Console (https://play.google.com/console).
Upload the app-release.aab file you located in the previous step.

flutter build apk --release

## IOS
flutter clean \
&& flutter pub get \
&& flutter build ipa --release --export-options-plist=ios/ExportOptions.plist


## WEB
flutter clean \
&& flutter pub get \
&& flutter build web --release --pwa-strategy=offline-first

---

## WEB PWA 설정 샘플과 Vercel 최소 배포 설정

### 1) web/manifest.json 샘플
다음 내용을 `web/manifest.json`에 반영하세요. 앱 이름, 색상, 아이콘 경로만 프로젝트에 맞게 수정하면 됩니다.

```json
{
  "name": "Memora",
  "short_name": "Memora",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#6D28D9",
  "orientation": "portrait-primary",
  "icons": [
    { "src": "icons/Icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/Icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/maskable_icon_x192.png", "sizes": "192x192", "type": "image/png", "purpose": "maskable any" },
    { "src": "icons/maskable_icon_x512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable any" }
  ]
}
```

아이콘 파일은 `web/icons/`에 위치시키는 것을 전제로 합니다.

### 2) web/index.html iOS PWA 메타 태그 샘플
Flutter 기본 템플릿에 아래 메타와 링크를 추가해 iOS 홈 화면 설치 품질을 높입니다.

```html
<!-- iOS PWA 개선용 메타 -->
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="Memora">
<link rel="apple-touch-icon" href="icons/apple-touch-icon-180.png">
<link rel="apple-touch-startup-image" href="icons/apple-splash-1170x2532.png" media="(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3)">

<!-- 기본 테마 컬러와 주소창 색상 -->
<meta name="theme-color" content="#6D28D9">
```

참고 사항
- `apple-touch-icon`은 최소 180x180 권장. 필요 시 다양한 해상도를 추가하세요.
- 스플래시 이미지는 기기별로 여러 장을 둘 수 있으며, 없더라도 동작에는 문제 없습니다.

### 3) Flutter 서비스워커 관련
Flutter 빌드 시 `flutter_service_worker.js`가 자동 생성됩니다. 별도 등록 코드를 넣을 필요는 없고, 캐시 정책만 과도하게 캐싱되지 않도록 주의합니다.

### 4) Vercel 정적 호스팅 최소 설정
빌드 산출물만 배포하는 전제입니다.

옵션 A. CLI로 산출물 폴더를 직접 배포

```bash
flutter build web --release --pwa-strategy=offline-first
vercel --prod ./build/web
```

옵션 B. `vercel.json`으로 SPA 라우팅 및 캐시 헤더 보강
프로젝트 루트에 `vercel.json` 파일을 만들고 아래 예시를 사용하세요. 리포지토리를 연동하지 않고도 CLI 배포에 적용됩니다. (단, `vercel --prod ./build/web` 대신 루트에서 배포할 경우에만 의미가 있습니다.)

```json
{
  "cleanUrls": true,
  "trailingSlash": false,
  "headers": [
    {
      "source": "/flutter_service_worker.js",
      "headers": [
        { "key": "Cache-Control", "value": "no-cache" }
      ]
    },
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ],
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

설명
- SPA 라우팅: 새로고침 시 404를 피하기 위해 모든 경로를 `index.html`로 rewrite.
- 캐시: 대용량 정적 리소스는 장기 캐싱, 서비스워커 파일은 최신 반영을 위해 no-cache.

### 5) iOS 체크리스트
- Safari에서 앱 접속 후 공유 아이콘 → "홈 화면에 추가" 안내 UI를 앱 내에 제공.
- 웹 푸시가 필요하면 iOS 16.4 이상, 홈 화면 설치 상태에서 권한 요청을 사용자 상호작용 이후에 트리거.
- 오프라인 동작은 `--pwa-strategy=offline-first`로 기본 제공되지만, 네트워크 오류 처리 및 재시도 로직은 앱 레벨에서 추가.

### 6) 자주 발생하는 이슈
- 아이콘 경로 불일치: `manifest.json`의 아이콘 경로와 실제 파일 경로가 다르면 iOS 설치 시 기본 아이콘으로 보일 수 있음.
- 과도한 캐시: 새 빌드 반영이 늦으면 iOS에서 앱 삭제 후 재설치를 안내하거나 `flutter_service_worker.js` 버전 업데이트 확인.
- SPA 라우팅 누락: 딥링크나 새로고침 시 404가 발생하면 `vercel.json`의 rewrites를 점검.