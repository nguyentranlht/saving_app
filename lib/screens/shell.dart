import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'add_transaction.dart';
import 'history.dart';
import 'overview.dart';
import 'settings.dart';
import 'stats.dart';

/// Mở màn hình ghi giao dịch.
void openAdd(BuildContext context, {TxType type = TxType.expense}) {
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => AddTransactionScreen(initialType: type),
  ));
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _importFromShortcuts());
  }

  /// Nhận dữ liệu từ Phím tắt (menu "Sổ thu chi" / tự ghi Apple Pay):
  /// giao dịch trong hàng chờ và yêu cầu mở tab Thống kê.
  Future<void> _importFromShortcuts() async {
    final store = StoreScope.read(context);
    final n = await store.importPending();
    if (n > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.current.autoRecorded(n))));
    }
    final tab = await store.takeOpenTab();
    if (tab != null && tab >= 0 && tab < 4 && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst); // đang ở màn con thì quay về
      _go(tab);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Quay lại app (ví dụ sang ngày mới) thì ghi các giao dịch định kỳ đã đến hạn.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      StoreScope.read(context).runRecurring();
      _importFromShortcuts();
    }
  }

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = S.of(context);
    final pages = [
      OverviewScreen(onGoTab: _go),
      const HistoryScreen(),
      const StatsScreen(),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Row(
                  children: [
                    _item(0, Icons.home_outlined, Icons.home_rounded, s.tabOverview),
                    _item(1, Icons.schedule, Icons.schedule, s.tabHistory),
                    const Expanded(child: SizedBox()),
                    _item(2, Icons.bar_chart_rounded, Icons.bar_chart_rounded, s.tabStats),
                    _item(3, Icons.settings, Icons.settings, s.tabSettings),
                  ],
                ),
                Positioned(
                  top: -22,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => openAdd(context),
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: c.expense,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.card, width: 4),
                          boxShadow: [
                            BoxShadow(color: c.expense.op(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, IconData activeIcon, String label) {
    final c = AppColors.of(context);
    final sel = _tab == i;
    final col = sel ? c.primary : c.muted;
    return Expanded(
      child: InkWell(
        onTap: () => _go(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sel ? activeIcon : icon, color: col, size: 24),
            const SizedBox(height: 3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    style: TextStyle(
                        color: col, fontSize: 11.5, fontWeight: sel ? FontWeight.w800 : FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
