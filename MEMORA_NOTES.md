## ANDROID
flutter clean \
&& flutter pub get \
&& flutter build appbundle --release


> 파일 경로
build/app/outputs/bundle/release/app-release.aab
> 업로드
Go to the Google Play Console (https://play.google.com/console).
Upload the app-release.aab file you located in the previous step.


## IOS
flutter clean \
&& flutter pub get \
&& flutter build ipa --release --export-options-plist=ios/ExportOptions.plist