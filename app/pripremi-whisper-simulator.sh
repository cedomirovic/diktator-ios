#!/bin/bash
# Priprema whisper.cpp za iOS **simulator** (arm64), da bi aplikacija mogla da
# se pokrene u simulatoru — za snimke ekrana i brzu proveru UI-ja.
#
# Biblioteke idu u app/vendor-ios/whisper-sim/ (ne u git). Metal je isključen,
# jer simulator koristi CPU; na uređaju i dalje radi Metal build iz
# app/pripremi-whisper-ios.sh.
set -euo pipefail
cd "$(dirname "$0")"

VER="${WHISPER_VER:-v1.9.5}"
SRC="${WHISPER_SRC:-${TMPDIR:-/tmp}/whisper-cpp-sim-$VER}"
BUILD="$SRC/build-sim"

if ! xcodebuild -version >/dev/null 2>&1; then
  if [ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  fi
fi

if ! command -v cmake >/dev/null 2>&1; then
  echo "Nedostaje cmake. Instaliraj ga sa: brew install cmake" >&2
  exit 1
fi

if [ ! -d "$SRC/.git" ]; then
  git clone --depth 1 --branch "$VER" https://github.com/ggml-org/whisper.cpp "$SRC"
fi

cmake -S "$SRC" -B "$BUILD" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DWHISPER_BUILD_EXAMPLES=OFF \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_BUILD_SERVER=OFF \
  -DGGML_METAL=OFF \
  -DGGML_BLAS=ON \
  -DGGML_BLAS_VENDOR=Apple \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphonesimulator \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0

cmake --build "$BUILD" -j"$(sysctl -n hw.ncpu)"

mkdir -p vendor-ios/whisper-sim/lib
cp "$BUILD/src/libwhisper.a" vendor-ios/whisper-sim/lib/
cp "$BUILD/ggml/src/libggml.a" vendor-ios/whisper-sim/lib/
cp "$BUILD/ggml/src/libggml-base.a" vendor-ios/whisper-sim/lib/
cp "$BUILD/ggml/src/libggml-cpu.a" vendor-ios/whisper-sim/lib/
cp "$BUILD/ggml/src/ggml-blas/libggml-blas.a" vendor-ios/whisper-sim/lib/

if [ ! -f vendor-ios/whisper-sim/lib/libwhisper.a ]; then
  echo "Greška: libwhisper.a za simulator nije napravljen." >&2
  exit 1
fi

echo "whisper.cpp za iOS simulator je spreman u app/vendor-ios/whisper-sim."
