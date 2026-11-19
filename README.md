# Ting Ting

App ghi chép thu chi cá nhân, viết bằng Flutter, chạy trên **iOS** và **Android**. Dữ liệu lưu ngay trên máy, không cần tài khoản hay internet.

## Chức năng

- **Ghi giao dịch** chi / thu, có máy tính trong ô số tiền (`45.000 + 30.000`, `600.000 ÷ 4`).
- **Tổng quan theo tháng**: số dư, thu chi tháng, biểu đồ theo danh mục, ngân sách.
- **Lịch sử**: tìm kiếm không cần gõ dấu, lọc theo thời gian và danh mục.
- **Thống kê** theo tuần / tháng / năm, lùi về kỳ trước, so sánh giữa các tháng.
- **Ngân sách** theo danh mục, cảnh báo khi dùng từ 80%.
- **Giao dịch định kỳ** (tiền nhà, lương, Netflix…): tự ghi khi đến hạn.
- **Danh mục**: 64 biểu tượng, đổi màu, kéo thả để sắp xếp.
- **Sao lưu / khôi phục** file `.json`, xuất CSV cho Excel.
- **Nhắc ghi chép** hằng ngày, giao diện Sáng / Tối / Theo hệ thống, tiếng Việt / English.
- **Widget màn hình chính** (iOS và Android): chi tiêu tháng này, số dư, ngân sách tổng.
- **Chỉ có trên iPhone**:
  - Menu **"Sổ thu chi"** trong app Phím tắt: ghi chi / thu không cần mở app.
  - **Tự ghi khi thanh toán Apple Pay**, qua tự động hóa "Giao dịch" của Phím tắt.

  Hướng dẫn cài đặt nằm trong app: **Cài đặt → Phím tắt & Apple Pay**.

## Yêu cầu

- Flutter (stable) và Xcode 16 trở lên để build iOS.
- Android Studio (Android SDK và Command-line Tools) để build Android.
- iOS 14+ / Android 5.0+ (API 21).

Kiểm tra môi trường:

```bash
flutter doctor
```

> Dòng `Android license status unknown` có thể vẫn hiện dù đã cài đủ. Bản SDK mới không còn dùng lệnh chấp nhận giấy phép cũ. Build được là ổn.

## Chạy app

```bash
flutter pub get
flutter devices                    # xem các máy đang kết nối, lấy ID
flutter run -d <ID>                # bản debug: hot reload (r), phải cắm cáp
flutter run --release -d <ID>      # bản release: rút cáp vẫn dùng được
```

Có thể dùng `-d ios` hoặc `-d android` thay cho ID nếu chỉ cắm một máy.

### iPhone

- Lần đầu cần chọn Team: mở `ios/Runner.xcworkspace` → target **Runner** → **Signing & Capabilities** → **Team**. Trên iPhone: **Cài đặt → Cài đặt chung → Quản lý VPN & thiết bị → Tin cậy**.
- Bản **debug** không mở được bằng cách chạm biểu tượng khi không cắm máy tính, và **Phím tắt cũng không chạy được**. Muốn dùng hằng ngày thì cài bản **release**.
- Tài khoản Apple **miễn phí**: app hết hạn sau **7 ngày**, phải cài lại. Tài khoản trả phí là 1 năm. Xem [Gia hạn mỗi 7 ngày](#gia-hạn-mỗi-7-ngày-tài-khoản-miễn-phí).

#### Gia hạn mỗi 7 ngày (tài khoản miễn phí) 19/11/2026

Hết hạn thì app bật ra ngay khi mở; widget và Phím tắt (kể cả tự ghi Apple Pay) cũng ngừng chạy. **Dữ liệu vẫn còn** nếu không xoá app. Để gia hạn, cắm iPhone, mở khoá màn hình rồi chạy:

```bash
./renew-ios.sh
```

Script tự làm: xoá profile cũ → build (lỗi thì thử lại 1 lần) → kiểm tra ngày hết hạn mới của app và widget → **chỉ cài khi mọi bước đều ổn** (cài đè, giữ dữ liệu). Cắm nhiều máy thì chỉ định máy: `./renew-ios.sh <ID>` (lấy ID bằng `xcrun devicectl list devices`).

Nếu iPhone báo "Nhà phát triển không được tin cậy": **Cài đặt → Cài đặt chung → Quản lý VPN & thiết bị → Tin cậy**.

<details>
<summary>Làm tay (khi không dùng script)</summary>

```bash
rm -f ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*
flutter build ios --release
security cms -D -i build/ios/iphoneos/Runner.app/embedded.mobileprovision | grep -A1 ExpirationDate
xcrun devicectl device install app --device <ID> build/ios/iphoneos/Runner.app
```

- Lệnh build phải in ra `✓ Built build/ios/iphoneos/Runner.app`. **Build lỗi thì đừng cài**: `build/` vẫn là bản cũ đã hết hạn, cài lên thì app vẫn hết hạn.
- Ngày hết hạn phải là khoảng 7 ngày sau hôm nay. Vẫn là ngày cũ thì mở `ios/Runner.xcworkspace`, vào **Signing & Capabilities** của **Runner** và **TingTingWidget** để Xcode xin lại profile.

</details>

#### Lỗi "requires minimum platform version 14.0 ... supports 13.0"

Flutter 3.44 gắn cứng iOS **13.0** cho package plugin nó tự sinh (`ios/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage`), trong khi `home_widget` và `file_picker` cần **14.0**. Hậu quả: build bằng Xcode luôn lỗi, `flutter build` hay lỗi lần đầu. Project đã đặt iOS 14.0, không cần đổi **Minimum Deployments**.

**Đã sửa trên máy này** bằng 1 dòng trong Flutter: `packages/flutter_tools/lib/src/darwin/darwin.dart`, hàm `supportedPackagePlatform`, iOS dùng `Version(14, 0, null)` (có comment "Ting Ting (local patch)").

⚠️ **Nâng cấp Flutter (`brew upgrade`, `flutter upgrade`) sẽ mất bản sửa.** `./renew-ios.sh` sẽ cảnh báo khi thiếu. Sửa lại:

1. Thử build bằng Xcode trước: Flutter mới có thể đã tự sửa lỗi này.
2. Nếu vẫn lỗi, mở `/opt/homebrew/share/flutter/packages/flutter_tools/lib/src/darwin/darwin.dart` (thư mục Flutter: `dirname $(dirname $(readlink -f $(which flutter)))`), trong `supportedPackagePlatform` đổi `version: deploymentTarget(),` thành:
   ```dart
   // Ting Ting (local patch): home_widget / file_picker need iOS 14.
   version: this == FlutterDarwinPlatform.ios ? Version(14, 0, null) : deploymentTarget(),
   ```
3. Xoá bộ đệm để Flutter build lại công cụ: `rm /opt/homebrew/share/flutter/bin/cache/flutter_tools.{snapshot,stamp}` rồi chạy `flutter --version`.

Gỡ bản sửa: `git -C /opt/homebrew/share/flutter checkout packages/flutter_tools/lib/src/darwin/darwin.dart` rồi xoá bộ đệm như bước 3.

### Android

Tạo file APK để cài hoặc gửi cho người khác:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

File nằm ở `build/app/outputs/flutter-apk/app-release.apk`.

### ⚠️ Cài đè để giữ dữ liệu

**Không dùng `flutter install`**: lệnh này **gỡ app trước khi cài**, làm mất toàn bộ dữ liệu. Dùng các lệnh sau:

| Nền tảng | Lệnh cài đè |
|---|---|
| iOS | `flutter run --release`, hoặc `xcrun devicectl device install app --device <ID> build/ios/iphoneos/Runner.app` |
| Android | `adb install -r <file.apk>` |

**Đổi Bundle ID (iOS) / applicationId (Android) là thành app khác**: dữ liệu cũ không chuyển sang. Trước khi đổi, hãy sao lưu trong app cũ rồi khôi phục ở app mới.

## Kiểm tra

```bash
flutter analyze
flutter test
```

`test/overflow_test.dart` mở mọi màn hình ở màn hẹp (320px), chữ phóng to và cả hai ngôn ngữ để bắt lỗi chữ tràn ô. Nên chạy lại mỗi khi sửa giao diện.

## Icon app

Logo nằm ở `assets/Ting-Ting-logo/`. Khi đổi logo, thay file rồi chạy:

```bash
dart run flutter_launcher_icons
```

Cấu hình nằm trong `pubspec.yaml` (mục `flutter_launcher_icons`):

- iOS dùng `ting-ting-appstore-1024.png`.
- Android dùng `ting-ting-android-foreground.png`: logo đã thu nhỏ vào vùng an toàn trên nền xanh, để không bị cắt khi bo tròn.

> Sau khi chạy, kiểm tra `git diff ios/Runner.xcodeproj/project.pbxproj`. Công cụ này có lỗi: hay ghi nhầm `AppIcon` vào dòng `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS`. Nếu thấy thì hoàn tác dòng đó.

## Cấu trúc code

```
lib/
  main.dart                 Khởi động app, giao diện, ngôn ngữ
  store.dart                Dữ liệu và mọi thao tác (giao dịch, danh mục, ngân sách, định kỳ, sao lưu)
  models.dart               Category, Tx, Recurring
  l10n.dart                 Toàn bộ chữ tiếng Việt / English (sửa câu chữ ở đây)
  format.dart               Định dạng tiền, ngày; tìm không dấu; máy tính
  backup.dart               Định dạng file sao lưu
  export.dart               Chia sẻ CSV / sao lưu, chọn file khôi phục
  reminder.dart             Thông báo nhắc ghi chép
  theme.dart                Màu sắc sáng / tối
  screens/                  Các màn hình
  widgets/                  Thành phần dùng chung (common.dart, calculator.dart)
  home_widget_sync.dart     Gửi số liệu tháng này sang widget màn hình chính
ios/Runner/ShortcutIntents.swift   Hành động cho app Phím tắt (menu, Apple Pay)
ios/TingTingWidget/                Widget iOS (SwiftUI, target TingTingWidget)
android/app/src/main/kotlin/com/nguyentran/tingting/TingTingWidgetProvider.kt   Widget Android
test/                       Test
```

### Widget màn hình chính

App tính sẵn số liệu, định dạng thành chữ, rồi ghi qua package `home_widget` (xem `lib/home_widget_sync.dart`). Widget chỉ việc hiển thị.

- **iOS** đọc từ App Group `group.com.nguyentran.tingting`. Cả app (`Runner/Runner.entitlements`) và widget (`TingTingWidget/TingTingWidget.entitlements`) phải khai báo cùng group này.
- **Android** đọc qua `HomeWidgetProvider`. Bố cục ở `res/layout/ting_ting_widget.xml`.
- Widget **chỉ cập nhật khi app chạy**. Giao dịch ghi qua Phím tắt sẽ hiện trên widget sau khi mở app.
- Package Kotlin (`com.nguyentran.tingting`) **phải trùng** với `namespace` trong `android/app/build.gradle.kts`. Nếu không, app thoát ngay khi mở.

Dữ liệu lưu trong SharedPreferences dạng JSON. Phím tắt (Swift) và Flutter trao đổi qua cùng kho này:

- `flutter.pendingTxs`: hàng chờ giao dịch do Phím tắt gửi sang. App nhập vào sổ khi mở hoặc quay lại app.
- `flutter.openTab`: yêu cầu mở thẳng một tab.
