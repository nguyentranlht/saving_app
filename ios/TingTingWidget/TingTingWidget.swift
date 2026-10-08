import SwiftUI
import WidgetKit

// Widget màn hình chính, giống thẻ số dư ở màn Tổng quan:
// nền xanh, số dư thật to, nhãn thu/chi, hai ô "Thu trong tháng" / "Chi trong tháng".
// Số liệu do app ghi sẵn (đã định dạng) vào App Group qua package home_widget,
// xem lib/home_widget_sync.dart. App gọi reloadTimelines mỗi khi dữ liệu đổi.

private let appGroupId = "group.com.nguyentran.tingting"

struct TingTingEntry: TimelineEntry {
  let date: Date
  let balanceLabel: String
  let balance: String
  let count: String
  let trend: String  // "over" (chi > thu), "ok" (thu ≥ chi), "" (chưa có giao dịch)
  let trendText: String
  let incomeLabel: String
  let income: String
  let spentLabel: String
  let spent: String

  static func load() -> TingTingEntry {
    let d = UserDefaults(suiteName: appGroupId)
    func s(_ key: String, _ fallback: String) -> String { d?.string(forKey: key) ?? fallback }
    return TingTingEntry(
      date: Date(),
      balanceLabel: s("tt_balance_label", "Số dư hiện tại"),
      balance: s("tt_balance", "0đ"),
      count: s("tt_count", ""),
      trend: s("tt_trend", ""),
      trendText: s("tt_trend_text", ""),
      incomeLabel: s("tt_income_label", "Thu trong tháng"),
      income: s("tt_income", "0đ"),
      spentLabel: s("tt_spent_label", "Chi trong tháng"),
      spent: s("tt_spent", "0đ"))
  }

  static let sample = TingTingEntry(
    date: Date(), balanceLabel: "Số dư hiện tại", balance: "11.750.000đ", count: "12 giao dịch",
    trend: "ok", trendText: "Thu đang nhiều hơn chi", incomeLabel: "Thu trong tháng", income: "15.000.000đ",
    spentLabel: "Chi trong tháng", spent: "3.250.000đ")
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

// MARK: - Giao diện (màu giống thẻ số dư: heroStart -> heroEnd trong lib/theme.dart)

private let heroStart = Color(red: 0x0B / 255, green: 0x5D / 255, blue: 0x4B / 255)
private let heroEnd = Color(red: 0x0F / 255, green: 0x6B / 255, blue: 0x55 / 255)

/// Nhãn "Chi đang nhiều hơn thu" (vàng) / "Thu đang nhiều hơn chi" (xanh), như trên thẻ.
private struct TrendPill: View {
  let trend: String
  let text: String
  var body: some View {
    let over = trend == "over"
    let fg = over ? Color(red: 1, green: 0.84, blue: 0.31) : Color(red: 0.73, green: 0.96, blue: 0.79)
    HStack(spacing: 4) {
      Image(systemName: over ? "exclamationmark.triangle" : "checkmark.circle").font(.system(size: 10, weight: .bold))
      Text(text).font(.system(size: 11, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
    }
    .foregroundColor(fg)
    .padding(.horizontal, 8).padding(.vertical, 4)
    .background(Capsule().fill(over ? Color(red: 1, green: 0.76, blue: 0.03).opacity(0.2)
                                    : Color(red: 0.41, green: 0.94, blue: 0.68).opacity(0.13)))
  }
}

/// Ô thu / chi tháng này: mũi tên trong vòng tròn nằm ngang với số tiền, nền trắng mờ.
private struct StatBox: View {
  let icon: String  // arrow.down.left = thu, arrow.up.right = chi (giống app)
  let value: String
  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: icon).font(.system(size: 10, weight: .bold))
        .frame(width: 22, height: 22).background(Circle().fill(Color.white.opacity(0.2)))
      Text(value).font(.system(size: 15, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.5)
    }
    .padding(.horizontal, 10).padding(.vertical, 9)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.15)))
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
    .widgetBackground(LinearGradient(colors: [heroStart, heroEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
  }

  private var balanceText: some View {
    Text(entry.balance).font(.system(size: 30, weight: .heavy)).lineLimit(1).minimumScaleFactor(0.4)
  }

  // Cỡ nhỏ: số dư + ô chi trong tháng.
  private var small: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(entry.balanceLabel).font(.system(size: 12)).lineLimit(1)
      balanceText
      Spacer(minLength: 0)
      StatBox(icon: "arrow.up.right", value: entry.spent)
    }
  }

  // Cỡ vừa: giống thẻ số dư.
  private var medium: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(entry.balanceLabel).font(.system(size: 13)).lineLimit(1)
        Spacer(minLength: 6)
        if entry.trend.isEmpty {
          Text(entry.count).font(.system(size: 12)).opacity(0.7).lineLimit(1)
        } else {
          TrendPill(trend: entry.trend, text: entry.trendText)
        }
      }
      balanceText
      Spacer(minLength: 0)
      HStack(spacing: 10) {
        StatBox(icon: "arrow.down.left", value: entry.income)
        StatBox(icon: "arrow.up.right", value: entry.spent)
      }
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
    .description("Số dư và thu chi tháng này.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
