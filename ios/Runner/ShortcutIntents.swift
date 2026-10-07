import AppIntents
import Foundation

// Hành động cho app Phím tắt:
//  • "Sổ thu chi" (MenuIntent): menu ghi khoản chi / ghi khoản thu / mở tab Thống kê của app.
//  • "Ghi khoản chi" (AddExpenseIntent): dùng với tự động hóa "Giao dịch" của Ví (Apple Pay).
//
// Ghi giao dịch chạy ngầm (không mở app) và chỉ cất vào hàng chờ; Flutter nhập vào sổ
// ở lần mở / quay lại app kế tiếp (AppStore.importPending).

// MARK: - Dữ liệu dùng chung với Flutter

/// SharedPreferences của Flutter nằm trong UserDefaults.standard với tiền tố "flutter.".
enum AppData {
  static let pendingKey = "flutter.pendingTxs"
  /// Tab Flutter cần mở khi app hiện lên (AppStore.takeOpenTab): 2 = Thống kê.
  static let openTabKey = "flutter.openTab"
  private static let defaults = UserDefaults.standard

  /// Đọc một giá trị JSON mà Flutter lưu dạng chuỗi (danh mục, giao dịch, hàng chờ).
  static func json<T>(_ key: String) -> T? {
    guard let raw = defaults.string(forKey: key), let data = raw.data(using: .utf8) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data)) as? T
  }

  /// Thêm một giao dịch vào hàng chờ (kèm thời điểm hiện tại).
  static func enqueue(_ item: [String: String]) throws {
    var list: [[String: String]] = json(pendingKey) ?? []
    var it = item
    it["date"] = ISO8601DateFormatter().string(from: Date())
    list.append(it)
    let data = try JSONSerialization.data(withJSONObject: list)
    defaults.set(String(data: data, encoding: .utf8), forKey: pendingKey)
  }

  /// Chữ theo ngôn ngữ đang chọn trong app.
  static func t(_ vi: String, _ en: String) -> String {
    defaults.string(forKey: "flutter.lang") == "en" ? en : vi
  }
}

// MARK: - Danh mục

/// Danh mục của app (SharedPreferences "categories"), hiện kèm emoji: "🍚 Ăn uống".
@available(iOS 16.0, *)
struct CategoryEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Danh mục"
  static var defaultQuery = CategoryQuery()

  var id: String
  var name: String
  var isIncome: Bool
  var icon: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(Self.emoji[icon] ?? "🔹") \(name)")
  }

  /// Emoji theo key biểu tượng của app (kIconGroups trong lib/widgets/common.dart).
  static let emoji: [String: String] = [
    "food": "🍚", "coffee": "☕", "fastfood": "🍔", "ramen": "🍜", "bakery": "🥐", "icecream": "🍦",
    "bar": "🍺", "grocery": "🛒", "cake": "🎂",
    "move": "🚌", "car": "🚗", "bike": "🛵", "fuel": "⛽", "taxi": "🚕", "flight": "✈️", "train": "🚆",
    "parking": "🅿️",
    "home": "🏠", "electric": "⚡", "water": "💧", "wifi": "📶", "phone": "📱", "rent": "🔑", "repair": "🔧",
    "laundry": "🧺", "cleaning": "🧹",
    "shop": "🛍️", "cart": "🛒", "clothes": "👕", "beauty": "💄", "devices": "💻", "furniture": "🛋️",
    "gift": "🎁",
    "movie": "🎬", "game": "🎮", "music": "🎵", "travel": "🧳", "sport": "🏋️", "beach": "🏖️",
    "camera": "📷", "party": "🎉",
    "health": "💊", "medicine": "💊", "hospital": "🏥", "spa": "💆", "baby": "🍼", "family": "👨‍👩‍👧",
    "pet": "🐾", "school": "🎓", "book": "📚",
    "wallet": "💰", "work": "💼", "salary": "💵", "trend": "📈", "invest": "📊", "bank": "🏦",
    "savings": "🐷", "card": "💳", "debt": "🔄", "bonus": "🧧", "tax": "🧾", "insurance": "🛡️",
    "charity": "🤲", "more": "🔹",
  ]

  /// Toàn bộ danh mục, giữ thứ tự như trong app.
  static func all() -> [CategoryEntity] {
    let list: [[String: Any]] = AppData.json("flutter.categories") ?? []
    return list.compactMap { c in
      guard let id = c["id"] as? String, let name = c["name"] as? String else { return nil }
      return CategoryEntity(
        id: id, name: name, isIncome: (c["type"] as? String) == "income", icon: c["icon"] as? String ?? "")
    }
  }
}

@available(iOS 16.0, *)
struct CategoryQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
    CategoryEntity.all().filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [CategoryEntity] {
    CategoryEntity.all()
  }
}

// MARK: - Menu "Sổ thu chi"

@available(iOS 16.0, *)
enum MenuChoice: String, AppEnum {
  case expense, income, summary

  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Chức năng"
  static var caseDisplayRepresentations: [MenuChoice: DisplayRepresentation] = [
    .expense: DisplayRepresentation(title: "💸 Ghi khoản chi"),
    .income: DisplayRepresentation(title: "💰 Ghi khoản thu"),
    .summary: DisplayRepresentation(title: "📈 Xem thống kê chi tiêu"),
  ]
}

@available(iOS 16.0, *)
struct MenuIntent: AppIntent {
  static var title: LocalizedStringResource = "Sổ thu chi"
  static var description = IntentDescription("Ghi khoản chi, ghi khoản thu hoặc mở thống kê chi tiêu.")
  static var openAppWhenRun: Bool = false

  /// Mặc định chạy ngầm; riêng "Xem thống kê" thì chuyển sang mở app (iOS 26+).
  @available(iOS 26.0, *)
  static var supportedModes: IntentModes { [.background, .foreground(.dynamic)] }

  @Parameter(title: "Chức năng", requestValueDialog: IntentDialog("Chọn chức năng"))
  var choice: MenuChoice

  /// Ô Double: bàn phím số của iOS có thêm dấu thập phân (","), để gõ "45,32" = 45.320đ.
  /// inclusiveRange chặn số âm / 0 (inputOptions chỉ có cho String).
  @Parameter(title: "Số tiền", controlStyle: .field, inclusiveRange: (0.001, 999_999_999_999))
  var amount: Double?

  @Parameter(title: "Danh mục")
  var category: CategoryEntity?

  /// Không hiện thông báo khi xong: ghi xong là kết thúc, "Xem thống kê" thì mở app.
  func perform() async throws -> some IntentResult {
    if choice == .summary {
      UserDefaults.standard.set(2, forKey: AppData.openTabKey)
      // iOS < 26 không mở app giữa chừng được: tab Thống kê sẽ mở ở lần mở app kế tiếp.
      if #available(iOS 26.0, *) {
        try await continueInForeground(alwaysConfirm: false)
      }
      return .result()
    }
    let isIncome = choice == .income

    // Số tiền. Bàn phím số của iOS không có phím "000", nên số dưới 1.000 được hiểu là
    // nghìn đồng: 45 -> 45.000đ, 45,32 -> 45.320đ; từ 1.000 trở lên giữ nguyên (45320 -> 45.320đ).
    var typed = amount ?? 0
    if typed <= 0 {
      let ask = isIncome ? AppData.t("Số tiền thu? (45 = 45.000đ)", "How much did you receive? (45 = 45,000đ)")
                         : AppData.t("Số tiền chi? (45 = 45.000đ)", "How much did you spend? (45 = 45,000đ)")
      typed = try await $amount.requestValue(IntentDialog(stringLiteral: ask)) ?? 0
    }
    let money = Int((typed < 1000 ? typed * 1000 : typed).rounded())
    guard money > 0 else {
      throw $amount.needsValueError(IntentDialog(stringLiteral: AppData.t("Bao nhiêu tiền?", "How much?")))
    }

    // Danh mục: chỉ hiện danh mục đúng loại (chi hoặc thu).
    var picked = category
    if picked == nil || picked!.isIncome != isIncome {
      let ask = isIncome ? AppData.t("Chọn mục thu:", "Choose an income category:")
                         : AppData.t("Chọn mục chi tiêu:", "Choose a spending category:")
      picked = try await $category.requestDisambiguation(
        among: CategoryEntity.all().filter { $0.isIncome == isIncome }, dialog: IntentDialog(stringLiteral: ask))
    }
    guard let cat = picked else {
      throw $category.needsValueError(IntentDialog(stringLiteral: AppData.t("Danh mục nào?", "Which category?")))
    }

    try AppData.enqueue([
      "amount": String(money),
      "categoryId": cat.id,
      "type": isIncome ? "income" : "expense",
    ])
    return .result()
  }
}

// MARK: - Tự ghi khi thanh toán Apple Pay

/// Dùng trong tự động hóa "Giao dịch" của Ví. Giữ nguyên tên tham số để không hỏng tự động hóa đã tạo.
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
    let place = merchant ?? ""
    try AppData.enqueue(["amount": amount, "merchant": place, "card": card ?? ""])
    let line = "\(AppData.t("Đã ghi", "Logged")) \(amount)\(place.isEmpty ? "" : " · \(place)")"
    return .result(dialog: IntentDialog(stringLiteral: line))
  }
}

// MARK: - Hiện trong app Phím tắt, Spotlight và Siri

@available(iOS 16.0, *)
struct SoThuChiShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: MenuIntent(),
      phrases: [
        "Chọn chức năng trong \(.applicationName)",
        "Menu \(.applicationName)",
        "Open \(.applicationName) menu",
      ],
      shortTitle: "Sổ thu chi",
      systemImageName: "list.bullet.rectangle.portrait"
    )
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
