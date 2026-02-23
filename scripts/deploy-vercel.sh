#!/usr/bin/env bash
set -e

if [ -f ".env.local" ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env.local | xargs)
    echo "GLOBAL_SECRET = $GLOBAL_SECRET"
fi
echo ""

echo "Building Flutter web (locally)..."
flutter clean
flutter pub get
flutter build web --release --pwa-strategy=offline-first --dart-define=GLOBAL_SECRET=$GLOBAL_SECRET

echo "Preparing deploy folder..."
DEPLOY_DIR=".deploy"

if [ -d "$DEPLOY_DIR" ]; then
    echo "Removing existing deploy folder..."
    rm -rf "$DEPLOY_DIR"
fi

mkdir -p "$DEPLOY_DIR"
cp -r build/web/* "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/api"
cp api/notion-proxy.js "$DEPLOY_DIR/api"
cp vercel.deploy.json "$DEPLOY_DIR/vercel.json"

# .vercel 폴더가 있으면 배포 폴더에 복사하여 프로젝트 링크 유지
if [ -d ".vercel" ]; then
    cp -r .vercel "$DEPLOY_DIR/"
fi

echo ""
echo "Deploying to Vercel (no build on Vercel - pre-built only)..."
echo "※ 빌드 오류가 나면: Vercel 대시보드 → 프로젝트 → Settings → General"
echo "   - Build Command / Install Command 를 비우고 저장한 뒤 다시 배포하세요."
echo ""
vercel --prod "$DEPLOY_DIR"

echo "Done. Remove deploy folder..."
rm -rf "$DEPLOY_DIR"
