#!/bin/bash
# Jednokratna priprema whisper.cpp za iOS: statičke biblioteke za arm64
# (iPhone), Metal + Accelerate. Biblioteke idu u app/vendor-ios/ (ne u git).
set -euo pipefail
cd "$(dirname "$0")"

VER="${WHISPER_VER:-v1.9.5}"
SRC="${WHISPER_SRC:-${TMPDIR:-/tmp}/whisper-cpp-ios-$VER}"
BUILD="$SRC/build-ios"

# Ako je xcode-select još na Command Line Tools, koristi Xcode.app direktno.
if ! xcodebuild -version >/dev/null 2>&1; then
  if [ -x /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  fi
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Nedostaje Xcode. Instaliraj Xcode 26.x iz App Store-a i pokreni:" >&2
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  echo "  sudo xcodebuild -license accept" >&2
  exit 1
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
  -DGGML_METAL=ON \
  -DGGML_METAL_EMBED_LIBRARY=ON \
  -DGGML_BLAS=ON \
  -DGGML_BLAS_VENDOR=Apple \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0

cmake --build "$BUILD" -j"$(sysctl -n hw.ncpu)"

mkdir -p vendor-ios/whisper/lib vendor-ios/whisper/include
cp "$SRC"/include/*.h vendor-ios/whisper/include/
cp "$SRC"/ggml/include/*.h vendor-ios/whisper/include/
cp "$BUILD/src/libwhisper.a" vendor-ios/whisper/lib/
cp "$BUILD"/ggml/src/*.a vendor-ios/whisper/lib/ 2>/dev/null || true
cp "$BUILD/ggml/src/ggml-metal/libggml-metal.a" vendor-ios/whisper/lib/
cp "$BUILD/ggml/src/ggml-blas/libggml-blas.a" vendor-ios/whisper/lib/

if [ ! -f vendor-ios/whisper/lib/libwhisper.a ]; then
  echo "Greška: libwhisper.a nije napravljen." >&2
  exit 1
fi

echo "whisper.cpp za iOS je spreman u app/vendor-ios/whisper."
