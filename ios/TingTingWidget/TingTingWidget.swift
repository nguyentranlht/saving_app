import SwiftUI
import WidgetKit

// Widget màn hình chính: chi tiêu tháng này và số dư.
// Số liệu do app ghi sẵn (đã định dạng) vào App Group qua package home_widget,
// xem lib/home_widget_sync.dart. App gọi reloadTimelines mỗi khi dữ liệu đổi.

private let appGroupId = "group.com.nguyentran.tingting"

struct TingTingEntry: TimelineEntry {
  let date: Date
  let month: String
  let spentLabel: String
  let spent: String
  let incomeLabel: String
  let income: String
  let balanceLabel: String
  let balance: String
  let budget: String
  let budgetRatio: Double  // < 0: chưa đặt ngân sách tổng

  static func load() -> TingTingEntry {
    let d = UserDefaults(suiteName: appGroupId)
    func s(_ key: String, _ fallback: String) -> String { d?.string(forKey: key) ?? fallback }
    return TingTingEntry(
      date: Date(),
      month: s("tt_month", ""),
      spentLabel: s("tt_spent_label", "Chi trong tháng"),
      spent: s("tt_spent", "0đ"),
      incomeLabel: s("tt_income_label", "Thu trong tháng"),
      income: s("tt_income", "0đ"),
      balanceLabel: s("tt_balance_label", "Số dư hiện tại"),
      balance: s("tt_balance", "0đ"),
      budget: s("tt_budget", ""),
      budgetRatio: (d?.object(forKey: "tt_budget_ratio") as? NSNumber)?.doubleValue ?? -1)
  }

  static let sample = TingTingEntry(
    date: Date(), month: "Tháng 10, 2026", spentLabel: "Chi trong tháng", spent: "3.250.000đ",
    incomeLabel: "Thu trong tháng", income: "+15.000.000đ", balanceLabel: "Số dư hiện tại",
    balance: "11.750.000đ", budget: "Còn 1,8tr", budgetRatio: 0.65)
}

struct TingTingProvider: TimelineProvider {
  func placeholder(in context: Context) -> TingTingEntry { .sample }

  func getSnapshot(in context: Context, completion: @escaping (TingTingEntry) -> Void) {
    completion(context.isPreview ? .sample : .load())
  }

  /// Chỉ vẽ lại khi app báo (reloadTimelines), không tự làm mới theo giờ.
  func getTimeline(in context: Context, completion: @escaping (Timeline<TingTingEntry>) -> Void) {
    completion(Timeline(entries: [.load()], policy: .never))
  }
}

// MARK: - Giao diện

private let green1 = Color(red: 0x0B / 255, green: 0x5D / 255, blue: 0x4B / 255)
private let green2 = Color(red: 0x12 / 255, green: 0x7A / 255, blue: 0x61 / 255)
private let mint = Color(red: 0x8E / 255, green: 0xF0 / 255, blue: 0xB9 / 255)

/// Thanh ngân sách: xanh < 80%, vàng 80–100%, đỏ khi vượt (giống trong app).
private struct BudgetBar: View {
  let ratio: Double
  var body: some View {
    let color: Color = ratio > 1 ? Color(red: 1, green: 0.48, blue: 0.44) : (ratio >= 0.8 ? .yellow : mint)
    GeometryReader { g in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.white.opacity(0.22))
        Capsule().fill(color).frame(width: g.size.width * min(max(ratio, 0), 1))
      }
    }
    .frame(height: 6)
  }
}

struct TingTingWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: TingTingEntry

  var body: some View {
    Group {
      if family == .systemMedium { medium } else { small }
    }
    .foregroundColor(.white)
    .widgetBackground(LinearGradient(colors: [green1, green2], startPoint: .topLeading, endPoint: .bottomTrailing))
  }

  private var header: some View {
    HStack(spacing: 4) {
      Text("Ting Ting").font(.caption2.weight(.heavy))
      Spacer(minLength: 4)
      Text(entry.month).font(.caption2).opacity(0.75).lineLimit(1)
    }
  }

  private var small: some View {
    VStack(alignment: .leading, spacing: 4) {
      header
      Spacer(minLength: 0)
      Text(entry.spentLabel).font(.caption).opacity(0.8).lineLimit(1)
      Text(entry.spent).font(.title3.weight(.bold)).lineLimit(1).minimumScaleFactor(0.5)
      if entry.budgetRatio >= 0 {
        BudgetBar(ratio: entry.budgetRatio)
        Text(entry.budget).font(.caption2).opacity(0.85).lineLimit(1)
      }
      Spacer(minLength: 0)
      Text("\(entry.balanceLabel): \(entry.balance)")
        .font(.caption2).opacity(0.85).lineLimit(1).minimumScaleFactor(0.6)
    }
  }

  private var medium: some View {
    VStack(alignment: .leading, spacing: 8) {
      header
      HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text(entry.spentLabel).font(.caption).opacity(0.8).lineLimit(1)
          Text(entry.spent).font(.title2.weight(.bold)).lineLimit(1).minimumScaleFactor(0.5)
          Text(entry.incomeLabel).font(.caption).opacity(0.8).lineLimit(1).padding(.top, 2)
          Text(entry.income).font(.subheadline.weight(.semibold)).foregroundColor(mint)
            .lineLimit(1).minimumScaleFactor(0.5)
        }
        VStack(alignment: .leading, spacing: 4) {
          Text(entry.balanceLabel).font(.caption).opacity(0.8).lineLimit(1)
          Text(entry.balance).font(.headline.weight(.bold)).lineLimit(1).minimumScaleFactor(0.5)
          if entry.budgetRatio >= 0 {
            Spacer(minLength: 2)
            BudgetBar(ratio: entry.budgetRatio)
            Text(entry.budget).font(.caption2).opacity(0.85).lineLimit(1)
          }
        }
      }
      Spacer(minLength: 0)
    }
  }
}

private extension View {
  /// iOS 17+ cần containerBackground; iOS cũ hơn dùng background thường.
  @ViewBuilder func widgetBackground<B: View>(_ bg: B) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { bg }
    } else {
      padding().background(bg)
    }
  }
}

@main
struct TingTingWidget: Widget {
  let kind = "TingTingWidget"  // trùng với iOSName trong lib/home_widget_sync.dart

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: TingTingProvider()) { entry in
      TingTingWidgetView(entry: entry)
    }
    .configurationDisplayName("Ting Ting")
    .description("Chi tiêu tháng này và số dư.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
