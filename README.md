# saving_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

flutter run --release

# 3. Chạy app

flutter devices                 # xem máy Android có hiện không, lấy ID máy
flutter run -d <ID_máy>         # bản debug: có hot reload (r), đang cắm cáp mới dùng được
flutter run --release -d <ID_máy>   # bản release: chạy nhanh, rút cáp vẫn dùng được
Nếu chỉ cắm một máy Android thì dùng flutter run -d android cho nhanh.

# 4. Tạo file APK để cài hoặc gửi cho người khác

flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
-r nghĩa là cài đè, giữ nguyên dữ liệu. Đừng dùng flutter install, vì lệnh này gỡ app trước khi cài.
File APK nằm ở build/app/outputs/flutter-apk/app-release.apk. Gửi file này qua Zalo hay Drive là người khác cài được.