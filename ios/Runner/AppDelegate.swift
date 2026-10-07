import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

// MARK: - Tự ghi khoản chi từ Phím tắt (tự động hóa "Giao dịch" của Ví / Apple Pay)

import AppIntents

/// Hành động "Ghi khoản chi" trong app Phím tắt. Chạy ngầm (không mở app):
/// chỉ cất giao dịch vào hàng chờ trong UserDefaults ("flutter.pendingTxs", chính là
/// SharedPreferences của Flutter); app sẽ nhập vào sổ ở lần mở / quay lại kế tiếp.
@available(iOS 16.0, *)
struct AddExpenseIntent: AppIntent {
  static var title: LocalizedStringResource = "Ghi khoản chi"
  static var description = IntentDescription(
    "Ghi một khoản chi vào sổ. Dùng với tự động hóa \"Giao dịch\" để tự ghi mỗi lần thanh toán Apple Pay.")
  static var openAppWhenRun: Bool = false

  @Parameter(title: "Số tiền")
  var amount: String

  @Parameter(title: "Nơi thanh toán")
  var merchant: String?

  @Parameter(title: "Thẻ")
  var card: String?

  static var parameterSummary: some ParameterSummary {
    Summary("Ghi khoản chi \(\.$amount) tại \(\.$merchant)") {
      \.$card
    }
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let key = "flutter.pendingTxs"
    let defaults = UserDefaults.standard
    var list: [[String: String]] = []
    if let raw = defaults.string(forKey: key),
       let data = raw.data(using: .utf8),
       let old = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] {
      list = old
    }
    list.append([
      "amount": amount,
      "merchant": merchant ?? "",
      "card": card ?? "",
      "date": ISO8601DateFormatter().string(from: Date()),
    ])
    let data = try JSONSerialization.data(withJSONObject: list)
    defaults.set(String(data: data, encoding: .utf8), forKey: key)
    let place = (merchant ?? "").isEmpty ? "" : " · \(merchant!)"
    return .result(dialog: "Đã ghi \(amount)\(place)")
  }
}

/// Đưa app vào danh sách app của Phím tắt (mục "Saving App") và cho gọi bằng Siri,
/// thay vì chỉ tìm được hành động qua ô tìm kiếm.
@available(iOS 16.0, *)
struct SoThuChiShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: AddExpenseIntent(),
      phrases: [
        "Ghi khoản chi trong \(.applicationName)",
        "Add expense in \(.applicationName)",
      ],
      shortTitle: "Ghi khoản chi",
      systemImageName: "creditcard"
    )
  }
}
