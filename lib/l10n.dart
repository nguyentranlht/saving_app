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
  String spentLast(int days) => _('Chi tiêu $days ngày qua', 'Spent in the last $days days');
  String delta(int pct, bool weekly) {
    final period = weekly ? _('tuần', 'week') : _('tháng', 'month');
    if (pct == 0) return _('Không đổi so với $period trước', 'No change from last $period');
    final p = pct.abs();
    return pct < 0
        ? _('Giảm $p% so với $period trước', 'Down $p% from last $period')
        : _('Tăng $p% so với $period trước', 'Up $p% from last $period');
  }

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
  String get exportSubject => _('Dữ liệu Sổ thu chi', 'Money Book data');
  String get csvHeader =>
      _('Ngày giờ,Loại,Danh mục,Số tiền (đ),Ghi chú', 'Date time,Type,Category,Amount (VND),Note');
}
