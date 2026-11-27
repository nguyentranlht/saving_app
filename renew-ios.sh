#!/usr/bin/env bash
# Gia hạn app trên iPhone (tài khoản Apple miễn phí, hết hạn sau 7 ngày):
# xin profile mới, build, kiểm tra build và ngày hết hạn, rồi mới cài đè (giữ dữ liệu).
#
#   ./renew-ios.sh            # tự chọn iPhone đang cắm
#   ./renew-ios.sh <ID>       # chọn máy theo Identifier (xcrun devicectl list devices)
#
# Chỉ cài khi build thành công: build lỗi thì build/ vẫn là bản cũ đã hết hạn.
set -euo pipefail
cd "$(dirname "$0")"

APP=build/ios/iphoneos/Runner.app
PROFILES="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
LOG_DIR="$(mktemp -d -t renew-ios)"
LOG="$LOG_DIR/install.log"

fail() { echo "❌ $*" >&2; exit 1; }

# Bản sửa iOS 14 trong Flutter (xem README) mất sau mỗi lần nâng cấp Flutter.
FLUTTER_ROOT="$(cd "$(dirname "$(readlink -f "$(command -v flutter)")")/.." && pwd)"
if ! grep -q "Ting Ting (local patch)" "$FLUTTER_ROOT/packages/flutter_tools/lib/src/darwin/darwin.dart"; then
  echo "⚠️  Flutter chưa có bản sửa iOS 14 (xem README). Build có thể lỗi lần đầu; script sẽ thử lại."
fi

# 1. Chọn iPhone
DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
  DEVICE="$(xcrun devicectl list devices 2>/dev/null | python3 -c '
import re, sys
for line in sys.stdin:
    cols = re.split(r"\s{2,}", line.strip())
    if len(cols) >= 5 and cols[3].startswith("available") and "iPhone" in cols[4]:
        print(cols[2]); break
')"
  [ -n "$DEVICE" ] || fail "Không thấy iPhone nào. Cắm cáp, mở khoá màn hình rồi chạy lại."
fi
echo "📱 iPhone: $DEVICE"

# 2. Xoá profile cũ để Xcode xin profile mới (thêm 7 ngày)
rm -f "$PROFILES"/*

# 3. Build (thử tối đa 2 lần nếu gặp lỗi)
built=0
for attempt in 1 2; do
  echo "🔨 Build lần $attempt..."
  BUILD_LOG="$LOG_DIR/build-$attempt.log"
  if flutter build ios --release >"$BUILD_LOG" 2>&1 && grep -q "✓ Built" "$BUILD_LOG"; then
    built=1
    break
  fi
  echo "   Build lỗi (log: $BUILD_LOG):"
  grep -iE "error|Target Integrity|No profiles|provisioning" "$BUILD_LOG" | grep -v "Automatically signing" | head -6 | sed 's/^/   /' || true
done
[ "$built" = 1 ] || fail "Build không thành công, KHÔNG cài. Log: $LOG_DIR"

# 4. Kiểm tra ngày hết hạn của app và widget (phải còn ít nhất 6 ngày)
for f in "$APP/embedded.mobileprovision" "$APP"/PlugIns/*.appex/embedded.mobileprovision; do
  security cms -D -i "$f" 2>/dev/null | python3 -c '
import datetime, plistlib, sys
exp = plistlib.loads(sys.stdin.buffer.read())["ExpirationDate"].replace(tzinfo=datetime.timezone.utc)
left = exp - datetime.datetime.now(datetime.timezone.utc)
name = sys.argv[1].split("/")[-2]
print(f"📅 {name}: hết hạn {exp.astimezone():%d/%m/%Y %H:%M}")
sys.exit(0 if left > datetime.timedelta(days=6) else 1)
' "$f" || fail "Profile chưa được làm mới. Mở ios/Runner.xcworkspace → Signing & Capabilities (Runner và TingTingWidget) rồi chạy lại."
done

# 5. Cài đè lên iPhone (giữ dữ liệu)
echo "📲 Cài lên iPhone..."
xcrun devicectl device install app --device "$DEVICE" "$APP" >"$LOG" 2>&1 || {
  grep -E "ERROR" "$LOG" | head -3 >&2
  fail "Cài không thành công. Log: $LOG"
}
echo "✅ Đã gia hạn. Nếu iPhone báo \"Nhà phát triển không được tin cậy\": Cài đặt → Cài đặt chung → Quản lý VPN & thiết bị → Tin cậy."
