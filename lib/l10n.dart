import 'package:flutter/widgets.dart';

import 'format.dart';
import 'models.dart';
import 'store.dart';

enum AppLang { vi, en }

/// Chuỗi hiển thị theo ngôn ngữ. Dùng `S.of(context)` trong widget (để tự vẽ lại
/// khi đổi ngôn ngữ) hoặc `S.current` ở chỗ không có context.
class S {
  const S._(this.lang);

  final AppLang lang;

  static S current = const S._(AppLang.vi);
  static void use(AppLang l) => current = S._(l);

  static S of(BuildContext context) {
    StoreScope.of(context);
    return current;
  }

  bool get en => lang == AppLang.en;
  String _(String vi, String en) => this.en ? en : vi;

  // ---- Chung ----
  String get appName => _('Sổ thu chi', 'Money Book');
  String get expense => _('Khoản chi', 'Expense');
  String get income => _('Khoản thu', 'Income');
  String get expenseShort => _('Chi', 'Expense');
  String get incomeShort => _('Thu', 'Income');
  String get cancel => _('Hủy', 'Cancel');
  String get delete => _('Xóa', 'Delete');
  String get edit => _('Sửa', 'Edit');
  String get save => _('Lưu', 'Save');
  String get deleted => _('Đã xóa', 'Deleted');
  String get category => _('Danh mục', 'Category');
  String txCount(int n) => en ? '$n transaction${n == 1 ? '' : 's'}' : '$n giao dịch';

  // ---- Thanh điều hướng ----
  String get tabOverview => _('Tổng quan', 'Overview');
  String get tabHistory => _('Lịch sử', 'History');
  String get tabStats => _('Thống kê', 'Stats');
  String get tabSettings => _('Cài đặt', 'Settings');

  // ---- Ngày giờ / số ----
  String get today => _('Hôm nay', 'Today');
  String get yesterday => _('Hôm qua', 'Yesterday');
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String dayMonth(DateTime d) => en ? '${_months[d.month - 1]} ${d.day}' : '${d.day} thg ${d.month}';
  String dayMonthShort(DateTime d) => en ? '${d.month}/${d.day}' : '${d.day}/${d.month}';
  List<String> get weekdays => en
      ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  String get million => _('tr', 'M');
  String get decimalSep => _(',', '.');
  String greeting(int hour) {
    if (hour < 11) return _('Chào buổi sáng', 'Good morning');
    if (hour < 14) return _('Chào buổi trưa', 'Good afternoon');
    if (hour < 18) return _('Chào buổi chiều', 'Good afternoon');
    return _('Chào buổi tối', 'Good evening');
  }

  // ---- Tổng quan ----
  static const _monthsLong = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  String monthYear(DateTime d) => en ? '${_monthsLong[d.month - 1]} ${d.year}' : 'Tháng ${d.month}, ${d.year}';
  String get backToThisMonth => _('Về tháng này', 'Back to this month');
  String get monthIncome => _('Thu trong tháng', 'Month\'s income');
  String get monthExpense => _('Chi trong tháng', 'Month\'s spending');
  String get yourBook => _('Sổ thu chi của bạn', 'Your money book');
  String get balance => _('Số dư hiện tại', 'Current balance');
  String get spendingOver => _('Chi đang nhiều hơn thu', 'Spending exceeds income');
  String get incomeOver => _('Thu đang nhiều hơn chi', 'Income exceeds spending');
  String get totalIncome => _('Tổng thu', 'Total income');
  String get totalExpense => _('Tổng chi', 'Total spent');
  String get addExpense => _('Ghi chi', 'Expense');
  String get addIncome => _('Ghi thu', 'Income');
  String get byCategory => _('Theo danh mục', 'By category');
  String get noData => _('Chưa có dữ liệu', 'No data yet');
  String pctOfTotal(int pct) => pct < 1 ? _('<1% tổng', '<1% of total') : _('$pct% tổng', '$pct% of total');
  String get recent => _('Gần đây', 'Recent');
  String get seeAll => _('Xem tất cả', 'See all');
  String get noTxYet =>
      _('Chưa có giao dịch. Nhấn + để ghi khoản đầu tiên.', 'No transactions yet. Tap + to add your first one.');

  // ---- Ghi giao dịch ----
  String get newTx => _('Ghi giao dịch', 'New transaction');
  String get editTx => _('Sửa giao dịch', 'Edit transaction');
  String get amount => _('Số tiền', 'Amount');
  String get noteHint => _('Thêm ghi chú (không bắt buộc)', 'Add a note (optional)');
  String get change => _('Đổi', 'Change');
  String get saveExpense => _('Lưu khoản chi', 'Save expense');
  String get saveIncome => _('Lưu khoản thu', 'Save income');

  // ---- Tự ghi từ Apple Pay (Phím tắt) ----
  String get applePayTitle => _('Phím tắt & Apple Pay', 'Shortcuts & Apple Pay');
  String get applePaySub => _('Menu ghi nhanh, tự ghi khi thanh toán', 'Quick menu, auto-log payments');
  String autoRecorded(int n) =>
      _('Đã ghi $n giao dịch từ Phím tắt', 'Added $n transaction${n == 1 ? '' : 's'} from Shortcuts');
  String get menuTitle => _('MENU "SỔ THU CHI"', '"SỔ THU CHI" MENU');
  String get menuIntro => _(
      'Trong app Phím tắt, mục Saving App có sẵn "Sổ thu chi": chọn 💸 Ghi khoản chi, 💰 Ghi khoản thu '
          'hoặc 📈 Xem thống kê chi tiêu (mở thẳng tab Thống kê). Ghi chi/thu không cần mở app.',
      'In the Shortcuts app, under Saving App you\'ll find "Sổ thu chi": pick 💸 log expense, 💰 log income '
          'or 📈 view stats (opens the Stats tab). Logging doesn\'t open the app.');
  List<String> get menuWays => en
      ? const [
          'Siri: say "Menu Saving App".',
          'Home Screen: in Shortcuts, tap and hold "Sổ thu chi" under Saving App → Add to Home Screen.',
          'Action Button (iPhone 15 Pro and later): Settings → Action Button → Shortcut → "Sổ thu chi".',
          'Control Center / Lock Screen (iOS 18): add a control → Shortcuts → "Sổ thu chi".',
        ]
      : const [
          'Siri: nói "Menu Saving App".',
          'Màn hình chính: trong app Phím tắt, chạm giữ "Sổ thu chi" ở mục Saving App → Thêm vào Màn hình chính.',
          'Nút Tác vụ (iPhone 15 Pro trở lên): Cài đặt → Nút Tác vụ → Phím tắt → "Sổ thu chi".',
          'Trung tâm điều khiển / Màn hình khóa (iOS 18): thêm điều khiển → Phím tắt → "Sổ thu chi".',
        ];
  String get autoLogTitle => _('TỰ GHI KHI THANH TOÁN APPLE PAY', 'AUTO-LOG APPLE PAY PAYMENTS');
  String get apIntro => _(
      'Mỗi lần bạn thanh toán bằng thẻ trong Ví, iPhone tự chạy một phím tắt gửi số tiền và nơi thanh toán sang app. '
          'Khoản chi được ghi vào sổ khi bạn mở app.',
      'Each time you pay with a card in Wallet, your iPhone runs a shortcut that sends the amount and merchant to the app. '
          'The expense is added when you open the app.');
  String get apSetupTitle => _('Cài một lần (iOS 17 trở lên):', 'One-time setup (iOS 17+):');
  List<String> get apSteps => en
      ? const [
          'Open the Shortcuts app → Automation tab → tap +.',
          'Choose "Transaction", pick the cards to track (or all), choose "Run Immediately", then tap Next.',
          'Tap "New Blank Automation" / "Add Action", search for "Ghi khoản chi" and pick it.',
          'Tap "Amount" → choose "Shortcut Input" → "Amount". Do the same for "Merchant" → "Merchant".',
          'Tap Done. From now on every Apple Pay payment is logged automatically.',
        ]
      : const [
          'Mở app Phím tắt → tab Tự động hóa → bấm dấu +.',
          'Chọn "Giao dịch", chọn thẻ muốn theo dõi (hoặc tất cả), chọn "Chạy ngay lập tức" rồi bấm Tiếp.',
          'Chọn "Tự động hóa trống mới" / "Thêm tác vụ", tìm "Ghi khoản chi" và chọn.',
          'Chạm ô "Số tiền" → chọn "Đầu vào phím tắt" (Shortcut Input) → "Số tiền" (Amount). '
              'Làm tương tự với ô "Nơi thanh toán" → "Người bán" (Merchant).',
          'Bấm Xong. Từ giờ mỗi lần thanh toán Apple Pay sẽ được ghi tự động.',
        ];
  String get apCategoryTitle => _('DANH MỤC MẶC ĐỊNH', 'DEFAULT CATEGORY');
  String get apCategoryHint => _(
      'Dùng khi chi ở nơi mới. Nơi đã từng chi sẽ tự lấy danh mục của lần gần nhất.',
      'Used for new merchants. Known merchants reuse the category from last time.');
  String get apNotesTitle => _('LƯU Ý', 'GOOD TO KNOW');
  List<String> get apNotes => en
      ? const [
          'Only payments made with a card in Wallet (tap to pay / Apple Pay) are logged. Bank transfers, physical cards and other e-wallets are not.',
          'If a payment is refunded or wrong, edit or delete it in History.',
          'Apple doesn\'t let apps read Wallet transactions directly, so this setup through Shortcuts is required.',
        ]
      : const [
          'Chỉ ghi được thanh toán bằng thẻ trong Ví (chạm điện thoại / Apple Pay). Chuyển khoản, quẹt thẻ vật lý hay ví điện tử khác không được ghi.',
          'Nếu khoản thanh toán bị hoàn tiền hoặc sai, bạn sửa hoặc xóa trong Lịch sử.',
          'Apple không cho app đọc trực tiếp giao dịch trong Ví, nên cần cài qua Phím tắt như trên.',
        ];

  // ---- Ngân sách ----
  String get budgetTitle => _('Ngân sách', 'Budgets');
  String get budgetThisMonth => _('Ngân sách tháng', 'Monthly budget');
  String get budgetHint => _('Hạn mức chi mỗi tháng, áp dụng cho mọi tháng. Thanh chuyển vàng khi dùng từ 80%, đỏ khi vượt.',
      'Monthly spending limits, applied to every month. Bars turn amber at 80% and red when over.');
  String get totalBudget => _('Tổng chi tiêu', 'Total spending');
  String get noBudgetYet => _('Chưa đặt hạn mức', 'No limit set');
  String get withBudget => _('ĐÃ ĐẶT HẠN MỨC', 'WITH A LIMIT');
  String get withoutBudget => _('CHƯA ĐẶT', 'NO LIMIT');
  String get setBudget => _('Đặt hạn mức', 'Set limit');
  String budgetFor(String name) => _('Hạn mức tháng · $name', 'Monthly limit · $name');
  String get removeBudget => _('Bỏ hạn mức', 'Remove limit');
  String spentOf(String spent, String limit) => _('$spent / $limit', '$spent of $limit');
  String leftAmount(String v) => _('Còn $v', '$v left');
  String overAmount(String v) => _('Vượt $v', '$v over');
  String daysLeft(int n) => _('Còn $n ngày', '$n day${n == 1 ? '' : 's'} left');
  String get budgetPrompt => _('Đặt hạn mức chi cho từng danh mục để không tiêu quá tay',
      'Set spending limits per category so you don\'t overspend');
  String budgetWarn(String name, int pct) =>
      _('$name đã dùng $pct% ngân sách tháng', '$name has used $pct% of its monthly budget');
  String budgetOver(String name, String over) =>
      _('$name đã vượt ngân sách tháng $over', '$name is $over over its monthly budget');

  // ---- Giao dịch định kỳ ----
  String get repeat => _('Lặp lại', 'Repeat');
  String freqName(Freq? f) => switch (f) {
        null => _('Không lặp', 'Never'),
        Freq.daily => _('Hằng ngày', 'Daily'),
        Freq.weekly => _('Hằng tuần', 'Weekly'),
        Freq.monthly => _('Hằng tháng', 'Monthly'),
        Freq.yearly => _('Hằng năm', 'Yearly'),
      };

  /// "Hằng tháng · ngày 5", "Hằng tuần · T2", "Hằng năm · 5 thg 10", "Hằng ngày · 21:00".
  String freqDetail(Freq f, DateTime anchor) => '${freqName(f)} · ${switch (f) {
        Freq.daily => hm(anchor),
        Freq.weekly => weekdays[anchor.weekday - 1],
        Freq.monthly => _('ngày ${anchor.day}', 'day ${anchor.day}'),
        Freq.yearly => dayMonth(anchor),
      }}';
  String nextOn(DateTime d) => _('Lần tới: ${dayMonth(d)}, ${d.year}', 'Next: ${dayMonth(d)}, ${d.year}');
  String get startsOn => _('Bắt đầu', 'Starts');
  String get nextLabel => _('Lần tới', 'Next');
  String get paused => _('Đang tạm dừng', 'Paused');
  String get recurringTitle => _('Giao dịch định kỳ', 'Recurring');
  String get recurringBadge => _('Định kỳ', 'Recurring');
  String get editRecurring => _('Sửa định kỳ', 'Edit recurring');
  String get addRecurring => _('Thêm giao dịch định kỳ', 'Add recurring transaction');
  String get recurringEmpty => _('Chưa có giao dịch định kỳ.\nThêm tiền nhà, lương, Netflix… để app tự ghi khi đến hạn.',
      'No recurring transactions yet.\nAdd rent, salary, Netflix… and the app records them when due.');
  String get recurringHint => _('Giao dịch được tự ghi khi đến hạn, mỗi lần bạn mở app. Sửa chỉ áp dụng cho các lần sau.',
      'Transactions are recorded automatically when due, whenever you open the app. Edits apply to future ones only.');
  String get deleteRecurringQ => _('Xóa giao dịch định kỳ?', 'Delete recurring transaction?');
  String get deleteRecurringBody =>
      _('App sẽ ngừng tự ghi. Các giao dịch đã ghi trước đó vẫn được giữ lại.',
          'It will stop recording. Transactions already recorded are kept.');

  // ---- Lịch sử ----
  String txTotal(int n) => en ? '$n transaction${n == 1 ? '' : 's'} in total' : '$n giao dịch tất cả';
  String get searchHint => _('Tìm danh mục hoặc ghi chú', 'Search category or note');
  String get all => _('Tất cả', 'All');
  String get noTx => _('Không có giao dịch nào', 'No transactions');
  String get net => _('Ròng', 'Net');
  String get allTime => _('Mọi thời gian', 'All time');
  String get thisWeek => _('Tuần này', 'This week');
  String get thisMonth => _('Tháng này', 'This month');
  String get lastMonth => _('Tháng trước', 'Last month');
  String get customRange => _('Tự chọn ngày…', 'Custom dates…');
  String get allCategories => _('Tất cả danh mục', 'All categories');
  String categoriesSelected(int n) => en ? '$n categories' : '$n danh mục';
  String matching(int n) => en ? '$n matching transaction${n == 1 ? '' : 's'}' : '$n giao dịch phù hợp';
  String get clearFilters => _('Xóa bộ lọc', 'Clear filters');
  String get done => _('Xong', 'Done');

  // ---- Chi tiết ----
  String get txDetail => _('Chi tiết giao dịch', 'Transaction details');
  String get time => _('Thời gian', 'Time');
  String get note => _('Ghi chú', 'Note');
  String get noNote => _('Không có ghi chú', 'No note');
  String get deleteTxQ => _('Xóa giao dịch?', 'Delete transaction?');
  String get cannotUndo => _('Thao tác này không thể hoàn tác.', 'This can\'t be undone.');

  // ---- Thống kê ----
  String get week => _('Tuần', 'Week');
  String get month => _('Tháng', 'Month');
  String get year => _('Năm', 'Year');
  String get spent => _('Đã chi', 'Spent');
  String get backToNow => _('Về hiện tại', 'Back to now');
  String weekRange(DateTime from, DateTime toInclusive) => '${dayMonthShort(from)} – ${dayMonthShort(toInclusive)}';
  String monthShort(int m) => en ? _months[m - 1] : 'T$m';

  /// [period]: 0 tuần, 1 tháng, 2 năm. [samePoint]: kỳ hiện tại chưa hết nên so với cùng thời điểm kỳ trước.
  String delta(int pct, int period, {bool samePoint = false}) {
    final p = [_('tuần', 'week'), _('tháng', 'month'), _('năm', 'year')][period];
    final vs = samePoint ? _('cùng kỳ $p trước', 'same point last $p') : _('$p trước', 'last $p');
    if (pct == 0) return _('Không đổi so với $vs', 'No change vs $vs');
    final a = pct.abs();
    return pct < 0 ? _('Giảm $a% so với $vs', 'Down $a% vs $vs') : _('Tăng $a% so với $vs', 'Up $a% vs $vs');
  }

  String get newVsPrev => _('Mới', 'New');
  String get monthByMonth => _('So sánh các tháng', 'Month by month');
  String get monthByMonthHint => _('Chạm vào một tháng để xem chi tiết', 'Tap a month to see details');
  String get incomeAndExpense => _('Thu và chi', 'Income & expenses');
  String get unitNote =>
      _('Đơn vị: nghìn / triệu đồng theo số liệu thực tế của bạn.', 'Units: thousands (k) / millions (M) of dong.');
  String get topSpending => _('Chi nhiều nhất', 'Top spending');
  String get noExpenseInPeriod => _('Chưa có khoản chi trong giai đoạn này', 'No expenses in this period');
  String get tipTitle => _('Gợi ý cho bạn', 'Tip for you');
  String otherTip(String name) => _(
      'Khoản chi "$name" đang chiếm hơn một nửa. Thử tách ra các danh mục cụ thể để dễ theo dõi hơn.',
      '"$name" makes up more than half of your spending. Try splitting it into specific categories to track it better.');

  // ---- Danh mục ----
  String get manageCategories => _('Quản lý danh mục', 'Manage categories');
  String get categoriesHint =>
      _('Chạm vào một danh mục để đổi tên, biểu tượng hoặc màu.', 'Tap a category to change its name, icon or color.');
  String get addCategory => _('Thêm danh mục mới', 'Add new category');
  String get newCategory => _('Danh mục mới', 'New category');
  String get editCategory => _('Sửa danh mục', 'Edit category');
  String get categoryName => _('Tên danh mục', 'Category name');
  String get icon => _('Biểu tượng', 'Icon');
  String get color => _('Màu', 'Color');
  String iconGroup(String key) => switch (key) {
        'food' => _('Ăn uống', 'Food & drink'),
        'transport' => _('Di chuyển', 'Transport'),
        'home' => _('Nhà cửa', 'Home'),
        'shopping' => _('Mua sắm', 'Shopping'),
        'fun' => _('Giải trí', 'Entertainment'),
        'health' => _('Sức khỏe & Gia đình', 'Health & family'),
        'finance' => _('Tài chính', 'Finance'),
        _ => key,
      };

  /// Tên danh mục mặc định theo id: (tiếng Việt, tiếng Anh).
  static const defaultNames = {
    'food': ('Ăn uống', 'Food & drink'),
    'move': ('Di chuyển', 'Transport'),
    'coffee': ('Cà phê', 'Coffee'),
    'work': ('Công tác phí', 'Business trips'),
    'health': ('Sức khỏe', 'Health'),
    'other_e': ('Khác', 'Other'),
    'salary': ('Lương', 'Salary'),
    'debt': ('Được trả nợ', 'Debt repaid'),
    'other_i': ('Khác', 'Other'),
  };

  String defaultName(String id) {
    final n = defaultNames[id]!;
    return en ? n.$2 : n.$1;
  }

  /// Danh mục mặc định chưa bị đổi tên thì hiển thị theo ngôn ngữ hiện tại.
  String catName(Category? c) {
    if (c == null) return deleted;
    final n = defaultNames[c.id];
    if (n != null && (c.name == n.$1 || c.name == n.$2)) return en ? n.$2 : n.$1;
    return c.name;
  }

  // ---- Cài đặt ----
  String get appearance => _('GIAO DIỆN', 'APPEARANCE');
  String get light => _('Sáng', 'Light');
  String get dark => _('Tối', 'Dark');
  String get language => _('NGÔN NGỮ', 'LANGUAGE');
  String get general => _('CHUNG', 'GENERAL');
  String get currency => _('Đơn vị tiền tệ', 'Currency');
  String get reminder => _('Nhắc ghi chép', 'Daily reminder');
  String reminderOn(int h, int m) =>
      _('Mỗi ngày lúc ${two(h)}:${two(m)} · chạm để đổi giờ', 'Every day at ${two(h)}:${two(m)} · tap to change');
  String get off => _('Đang tắt', 'Off');
  String get data => _('DỮ LIỆU', 'DATA');
  String get backup => _('Sao lưu dữ liệu', 'Back up data');
  String lastBackupAt(String when) => _('Lần gần nhất: $when', 'Last backup: $when');
  String get neverBackedUp => _('Chưa sao lưu lần nào', 'Never backed up');
  String get backupDone => _('Đã sao lưu. Giữ file này ở nơi an toàn (Tệp, iCloud Drive…)',
      'Backed up. Keep this file somewhere safe (Files, iCloud Drive…)');
  String get backupFailed => _('Không sao lưu được dữ liệu', 'Couldn\'t back up data');
  String get restore => _('Khôi phục từ bản sao lưu', 'Restore from backup');
  String get restoreSub => _('Chọn file .json đã sao lưu', 'Pick a .json backup file');
  String get invalidBackup =>
      _('File này không phải bản sao lưu hợp lệ của app', 'This file isn\'t a valid backup from this app');
  String get restoreQ => _('Khôi phục dữ liệu?', 'Restore data?');
  String restoreBody(String when, int txs, int cats, int currentTxs) => _(
      'Bản sao lưu lúc $when gồm $txs giao dịch và $cats danh mục.\n\nDữ liệu hiện tại ($currentTxs giao dịch) sẽ bị thay thế.',
      'Backup from $when contains $txs transactions and $cats categories.\n\nYour current data ($currentTxs transactions) will be replaced.');
  String get restoreAction => _('Khôi phục', 'Restore');
  String restored(int n) => _('Đã khôi phục $n giao dịch', 'Restored $n transactions');
  String get undo => _('Hoàn tác', 'Undo');
  String get csvSub => _('Để mở bằng Excel, Google Sheets', 'To open in Excel, Google Sheets');
  String get exportCsv => _('Xuất dữ liệu (CSV)', 'Export data (CSV)');
  String get clearAll => _('Xóa toàn bộ dữ liệu', 'Delete all data');
  String get cannotUndoShort => _('Không thể hoàn tác', 'Cannot be undone');
  String get version => _('$appName · phiên bản 1.0', '$appName · version 1.0');
  String get noPermission => _('Chưa được cấp quyền thông báo. Hãy bật trong Cài đặt của điện thoại.',
      'Notification permission not granted. Enable it in your phone\'s Settings.');
  String get reminderTime => _('Giờ nhắc ghi chép', 'Reminder time');
  String get nothingToExport => _('Chưa có giao dịch nào để xuất', 'No transactions to export');
  String get exportFailed => _('Không xuất được dữ liệu', 'Couldn\'t export data');
  String get clearAllQ => _('Xóa toàn bộ dữ liệu?', 'Delete all data?');
  String get clearAllBody => _('Tất cả giao dịch sẽ bị xóa và danh mục trở về mặc định. Không thể hoàn tác.',
      'All transactions will be deleted and categories reset to defaults. This can\'t be undone.');
  String get deleteAll => _('Xóa hết', 'Delete all');

  // ---- Thông báo / xuất file ----
  String get reminderBody => _('Hôm nay bạn đã ghi chép thu chi chưa?', 'Have you logged your spending today?');
  String get reminderChannelDesc => _('Nhắc ghi chép thu chi mỗi ngày', 'Daily reminder to log your spending');
  String get backupSubject => _('Sao lưu Sổ thu chi', 'Money Book backup');
  String get exportSubject => _('Dữ liệu Sổ thu chi', 'Money Book data');
  String get csvHeader =>
      _('Ngày giờ,Loại,Danh mục,Số tiền (đ),Ghi chú', 'Date time,Type,Category,Amount (VND),Note');
}
