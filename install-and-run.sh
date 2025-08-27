#!/bin/bash

echo "🚀 OnchainWalletDemo Setup & Initialization Starting..."
echo "--------------------------------------"

# =============================
# 1️⃣ Node / npm / yarn / watchman
# =============================
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not installed. Please install: https://nodejs.org/"
else
    echo "✅ Node.js version: $(node -v)"
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm not installed (it comes with Node.js)"
else
    echo "✅ npm version: $(npm -v)"
fi

if ! command -v yarn &> /dev/null; then
    echo "⚠️ Yarn not installed. Recommended: npm install -g yarn"
else
    echo "✅ Yarn version: $(yarn -v)"
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v watchman &> /dev/null; then
        echo "⚠️ watchman not installed (recommended for macOS to avoid file watching issues)"
        echo "👉 Install with: brew install watchman"
    else
        echo "✅ watchman version: $(watchman --version)"
    fi
fi

# =============================
# 2️⃣ Java / Android SDK
# =============================
if ! command -v java &> /dev/null; then
    echo "❌ Java not installed. Please install JDK 17 or 21: https://adoptium.net/"
else
    echo "✅ Java version: $(java -version 2>&1 | head -n 1)"
fi

if [ -d "$HOME/Library/Android/sdk" ]; then
    echo "✅ Android SDK detected"
    export ANDROID_HOME=$HOME/Library/Android/sdk
    export PATH=$PATH:$ANDROID_HOME/emulator
    export PATH=$PATH:$ANDROID_HOME/platform-tools
else
    echo "❌ Android SDK not found. Please install Android Studio and SDK 34+"
fi

# =============================
# 3️⃣ Xcode
# =============================
if ! command -v xcodebuild &> /dev/null; then
    echo "⚠️ Xcode not installed (Required for iOS). Install via App Store: https://apps.apple.com/app/xcode/id497799835"
else
    echo "✅ Xcode installed: $(xcodebuild -version)"
fi

# =============================
# 4️⃣ npm install + CocoaPods + Gradle
# =============================
echo "📦 Installing npm dependencies..."
npm install

if [ -d "ios" ]; then
    echo "📦 Checking iOS CocoaPods..."
    if ! command -v pod &> /dev/null; then
        echo "⚠️ CocoaPods not installed. Run: sudo gem install cocoapods"
    fi
    echo "✅ Running pod install..."
    cd ios && pod install && cd ..
fi

if [ -d "android" ]; then
    echo "📌 Initializing Android Gradle..."
    cd android
    ./gradlew tasks || true
    cd ..
    echo "📌 Note: First Android build may require Gradle/SDK updates."
    echo "👉 Open Android Studio → File → Sync Project with Gradle Files if needed."
fi

# =============================
# 5️⃣ Launch VS Code
# =============================
if [ -d "/Applications/Visual Studio Code.app" ]; then
    if command -v code &> /dev/null; then
        echo "✅ Launching VS Code..."
        code .
    else
        echo "⚠️ VS Code installed but 'code' command not found"
        echo "👉 In VS Code: Press Command+Shift+P → Shell Command: Install 'code' command in PATH"
    fi
fi

# =============================
# 6️⃣ Metro Bundler
# =============================
if pgrep -f "react-native start" > /dev/null; then
    echo "✅ Metro Bundler is already running"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "📡 Launching Metro Bundler in a new terminal..."
        osascript <<EOF
tell application "Terminal"
    do script "cd \"$(pwd)\" && npx react-native start"
end tell
EOF
    else
        echo "⚠️ Non-macOS detected. Please manually run: npx react-native start"
    fi
    sleep 5
fi

# =============================
# 7️⃣ Choose Platform & Run
# =============================
echo "--------------------------------------"
echo "📱 Select a platform to run:"
echo "1) Android"
echo "2) iOS (Simulator)"
read -p "Enter number (1/2): " platform

case $platform in
    1)
        emulators=$(emulator -list-avds)
        if [ -z "$emulators" ]; then
            echo "⚠️ No Android emulators found. Create one in Android Studio:"
            echo "   1. Android Studio → Tools → Device Manager"
            echo "   2. Create Device → Select a model"
            echo "   3. Choose Android 13/14 system image → Download"
            open -a "Android Studio"
            exit 1
        fi
        echo "📋 Available Android Emulators:"
        echo "$emulators" | nl
        read -p "Enter emulator number: " choice
        emulator_name=$(echo "$emulators" | sed -n "${choice}p")
        emulator "$emulator_name" &
        echo "⏳ Waiting for emulator to fully boot..."
        sleep 25
        npm run android
        ;;
    2)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            devices=$(xcrun simctl list devices available | grep -E "iPhone|iPad" | awk -F '[()]' '{print $1 " | " $2}' | nl)
            echo "$devices"
            read -p "Enter simulator number: " choice
            udid=$(xcrun simctl list devices available | grep -E "iPhone|iPad" | sed -n "${choice}p" | awk -F '[()]' '{print $2}')
            if [ -n "$udid" ]; then
                xcrun simctl boot "$udid" || true
                open -a Simulator
                sleep 5
                npm run ios -- --udid "$udid"
            fi
        else
            echo "❌ iOS is supported on macOS only."
        fi
        ;;
    *)
        echo "⚠️ Invalid selection"
        ;;
esac

echo "--------------------------------------"
echo "✅ All done!"
