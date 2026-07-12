#!/usr/bin/env bash
# ============================================================================
# fetch-thirdparty.sh — populate sciTorch's untracked native runtime payload
# (macOS arm64) so a fresh clone can build/load the gateway
# (sci_gateway/cpp/libgw_sciTorch.dylib):
#
#   thirdparty/libtorch/Darwin/arm64/   libtorch 2.5.1 CPU (headers + dylibs +
#                                        static archives) — official pytorch.org
#                                        distribution, used at both build time
#                                        (headers) and runtime (@rpath dylibs).
#   thirdparty/opencv/Darwin/arm64/lib/ OpenCV 4.5.0 + its ffmpeg/libiconv
#                                        runtime closure, self-contained via
#                                        @loader_path (see commit b8d63183d27).
#
# Both are git-ignored (see .gitignore) because they are large binary blobs;
# they are hosted instead as release assets on this repo's own GitHub mirror
# (github.com/jlmoya/sciTorch, release "thirdparty-v1") and pinned by sha256
# below, so a re-publish upstream can't silently swap what gets installed.
#
#   ./fetch-thirdparty.sh                  # fetch + install + verify
#   ./fetch-thirdparty.sh --verify-only    # no network: check the payload
#   ./fetch-thirdparty.sh --force          # re-extract/reinstall everything
#   ./fetch-thirdparty.sh --dest DIR       # install into DIR instead of this
#                                          # source root (testing)
#
# See sci_gateway/cpp/builder_gateway_cpp.sce for how these paths are wired
# into the build (-I/-L flags) and link (-Wl,-rpath,@loader_path/...) steps.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"   # the repo root (sciTorch)
DEST="$SCRIPT_DIR"
CACHE="${SCITORCH_THIRDPARTY_CACHE:-$HOME/.cache/scitorch-thirdparty}"
VERIFY_ONLY=0
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dest)        DEST="$(mkdir -p "$2" && cd "$2" && pwd)"; shift 2;;
    --cache)       CACHE="$2"; shift 2;;
    --verify-only) VERIFY_ONLY=1; shift;;
    --force)       FORCE=1; shift;;
    -h|--help)     sed -n '2,26p' "$0"; exit 0;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

TP="$DEST/thirdparty"
mkdir -p "$TP" "$CACHE"

# ---------------------------------------------------------------------------
# pinned sources — release assets on this repo's own GitHub mirror
# ---------------------------------------------------------------------------
RELEASE_BASE="https://github.com/jlmoya/sciTorch/releases/download/thirdparty-v1"

LIBTORCH_URL="$RELEASE_BASE/libtorch-2.5.1-macos-arm64.tar.gz"
LIBTORCH_SHA="a3fb060ac0a1d37720a1b54edd0fa31d1957870cf0193e00bef4d7248b3006ff"

OPENCV_URL="$RELEASE_BASE/opencv-ipcv450-closure-macos-arm64.tar.gz"
OPENCV_SHA="eb4a5acd5c1c67e3bc48046a43c43c987f3164129bfa21b975967eaa4a0e1f6d"

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
sha256() { shasum -a 256 "$1" | awk '{print $1}'; }

# fetch <url> <sha256> <cache-name>  -> echoes the cached, sha256-verified path
fetch() {
  local url="$1" pin="$2" name="$3" f="$CACHE/$3" got
  if [ ! -f "$f" ]; then
    echo "      downloading $name …" >&2
    curl -fsSL --retry 3 --connect-timeout 20 -o "$f.part" "$url" \
      || { echo "ERROR: download failed ($url)" >&2; rm -f "$f.part"; exit 1; }
    mv "$f.part" "$f"
  fi
  got="$(sha256 "$f")"
  if [ "$got" != "$pin" ]; then
    echo "ERROR: sha256 mismatch for $name" >&2
    echo "  expected: $pin" >&2
    echo "  got:      $got   (cached at $f — delete it to re-download)" >&2
    exit 1
  fi
  echo "$f"
}

# ---------------------------------------------------------------------------
# fetch + install
# ---------------------------------------------------------------------------
if [ "$VERIFY_ONLY" = 0 ]; then

  echo "[1/2] libtorch 2.5.1 (CPU, arm64) — PyTorch C++ headers + runtime…"
  if [ "$FORCE" = 1 ] || [ ! -f "$TP/libtorch/Darwin/arm64/lib/libtorch_cpu.dylib" ]; then
    LIBTORCH_TAR="$(fetch "$LIBTORCH_URL" "$LIBTORCH_SHA" "libtorch-2.5.1-macos-arm64.tar.gz")"
    mkdir -p "$TP/libtorch"
    tar -xzf "$LIBTORCH_TAR" -C "$TP/libtorch"
    echo "      extracted -> $TP/libtorch/Darwin/arm64"
  else
    echo "      present (sentinel libtorch_cpu.dylib) — skip (--force to re-extract)"
  fi

  echo "[2/2] OpenCV 4.5.0 + ffmpeg/libiconv runtime closure (self-contained, arm64)…"
  if [ "$FORCE" = 1 ] || [ ! -f "$TP/opencv/Darwin/arm64/lib/libopencv_world.4.5.0.dylib" ]; then
    OPENCV_TAR="$(fetch "$OPENCV_URL" "$OPENCV_SHA" "opencv-ipcv450-closure-macos-arm64.tar.gz")"
    mkdir -p "$TP/opencv"
    tar -xzf "$OPENCV_TAR" -C "$TP/opencv"
    echo "      extracted -> $TP/opencv/Darwin/arm64/lib"
  else
    echo "      present (sentinel libopencv_world.4.5.0.dylib) — skip (--force to re-extract)"
  fi

  echo "codesign: re-applying ad-hoc signatures over the unpacked dylibs…"
  # Ad-hoc signatures (flags=0x2(adhoc)) don't always survive a tar round-trip
  # cleanly on macOS (e.g. a quarantine xattr picked up on download can throw
  # off the CodeDirectory). Re-signing is cheap and a no-op if already valid,
  # so just always do it rather than trying to detect "needs it".
  n=0
  while IFS= read -r -d '' dylib; do
    codesign -f -s - "$dylib" >/dev/null 2>&1
    n=$((n + 1))
  done < <(find "$TP/libtorch/Darwin/arm64/lib" "$TP/opencv/Darwin/arm64/lib" \
                -type f -name '*.dylib' -print0 2>/dev/null)
  echo "      signed $n dylib(s)"
fi

# ---------------------------------------------------------------------------
# verify — everything the gateway build/link/load steps need
# ---------------------------------------------------------------------------
echo
echo "verify: required payload…"
MISSING=0
need()      { [ -e "$1" ] || { echo "  MISSING: $1"; MISSING=1; }; }
need_arm64(){ need "$1"; [ -e "$1" ] && { lipo -archs "$1" 2>/dev/null | grep -q arm64 || { echo "  NOT arm64: $1"; MISSING=1; }; }; }

need "$TP/libtorch/Darwin/arm64/include/torch/csrc/api/include/torch/torch.h"
for lib in libtorch libtorch_cpu libc10 libtorch_global_deps libomp libshm; do
  need_arm64 "$TP/libtorch/Darwin/arm64/lib/$lib.dylib"
done

OCV="$TP/opencv/Darwin/arm64/lib"
need_arm64 "$OCV/libopencv_world.4.5.0.dylib"
need        "$OCV/libopencv_world.4.5.dylib"   # symlink -> libopencv_world.4.5.0.dylib
for lib in libavcodec.58.91.100 libavformat.58.45.100 libavutil.56.51.100 \
           libswscale.5.7.100 libswresample.3.7.100 libiconv.2; do
  need_arm64 "$OCV/$lib.dylib"
done

if [ "$MISSING" = 0 ]; then
  echo "RESULT: payload complete. Next: builder.sce (rebuild) or loader.sce (load prebuilt)."
else
  echo "RESULT: payload INCOMPLETE (see MISSING above)."
  exit 1
fi
