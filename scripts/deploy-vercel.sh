#!/usr/bin/env bash
# Flutter 웹 빌드 후, 정적 파일 + api 프록시를 한 루트에 모아 Vercel로 배포합니다.
set -e

echo "Building Flutter web..."
flutter clean
flutter pub get
flutter build web --release --pwa-strategy=offline-first

echo "Preparing deploy folder..."
DEPLOY_DIR=".deploy"
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR"
cp -r build/web/* "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/api"
cp api/notion-proxy.js "$DEPLOY_DIR/api"
cp vercel.deploy.json "$DEPLOY_DIR/vercel.json"

echo "Deploying to Vercel..."
vercel --prod "$DEPLOY_DIR"

echo "Done. You can remove .deploy if you want: rm -rf .deploy"
