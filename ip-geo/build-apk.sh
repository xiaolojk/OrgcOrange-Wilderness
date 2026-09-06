#!/usr/bin/env bash
# ================================================================
#  🌐 IP 归属地查询 - 一键构建 APK 脚本
#  适用：macOS / Linux / Windows(WSL或GitBash)
#  前置：Node.js 18+、JDK 17+、Android SDK（含 platform-36）
# ================================================================
set -e
cd "$(dirname "$0")"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
INFO="${GREEN}[INFO]${NC}"; WARN="${YELLOW}[WARN]${NC}"; ERR="${RED}[ERR ]${NC}"

echo -e "${INFO} === 🌐 IP 归属地查询 APK 构建 ==="

# ---- 环境检查 ----
MISSING=0
for c in node npm java; do
    command -v $c >/dev/null || { echo -e "${ERR} 缺少 $c"; MISSING=1; }
done
[ -z "$JAVA_HOME" ] && command -v java >/dev/null && \
    export JAVA_HOME=$(cd "$(dirname "$(command -v java)")/.." && pwd) && \
    echo -e "${WARN} JAVA_HOME 自动推测: $JAVA_HOME"
for v in ANDROID_SDK_ROOT ANDROID_HOME; do
    [ -n "${!v}" ] && [ -d "${!v}" ] && export ANDROID_SDK_ROOT="${!v}" && break
done
if [ -z "$ANDROID_SDK_ROOT" ]; then
    for p in "$HOME/Android/Sdk" "$HOME/Library/Android/sdk" "/opt/android-sdk"; do
        [ -d "$p" ] && export ANDROID_SDK_ROOT="$p" && break
    done
fi
[ -z "$ANDROID_SDK_ROOT" ] && { echo -e "${ERR} 未找到 Android SDK（装 Android Studio 或设置 ANDROID_SDK_ROOT）"; MISSING=1; }
[ "$MISSING" = "1" ] && exit 1
echo -e "${INFO} JAVA_HOME=$JAVA_HOME"
echo -e "${INFO} ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"

# ---- 构建流程 ----
echo -e "${INFO} [1/4] npm 依赖"
[ -d node_modules ] || npm install

echo -e "${INFO} [2/4] Vite 构建 web (dist/)"
npm run build

echo -e "${INFO} [3/4] Capacitor 同步 android"
npx cap sync android

echo -e "${INFO} [4/4] Gradle 打包 APK"
cd android
if [ -x ./gradlew ]; then ./gradlew assembleDebug --no-daemon -x lint
else gradle assembleDebug --no-daemon -x lint; fi

APK="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK" ]; then
    cp "$APK" ../IP归属地查询-v1.0.0.apk
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN} 🎉 APK 构建成功${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e " 📦 $(cd .. && pwd)/IP归属地查询-v1.0.0.apk ($(ls -lh ../IP归属地查询-v1.0.0.apk | awk '{print $5}'))"
    echo -e " 📲 安装: adb install -r IP归属地查询-v1.0.0.apk"
    echo -e " 💡 发布版: gradle assembleRelease 后用 keytool 签名"
else
    echo -e "${ERR} 未生成 APK，请查看日志"
    exit 2
fi
