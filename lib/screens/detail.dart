import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'add_transaction.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.txId});
  final String txId;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final tx = store.tx(txId);
    if (tx == null) {
      // Đã bị xóa -> tự thoát.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold();
    }
    final cat = store.cat(tx.categoryId);
    final color = tx.type == TxType.expense ? c.expense : c.income;

    return Scaffold(
      body: SafeArea(
        // Cuộn được khi chữ lớn; nội dung ngắn thì nút vẫn nằm ở đáy.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 28),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleBtn(icon: Icons.chevron_left, onTap: () => Navigator.of(context).pop()),
                        Expanded(
                          child: Center(
                            child: Text(s.txDetail, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 46),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      radius: 30,
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            CatIcon(category: cat, size: 76),
                            const SizedBox(height: 12),
                            Text(s.catName(cat),
                                style: TextStyle(color: c.muted, fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(vnd(tx.signed),
                                    style: TextStyle(color: color, fontSize: 44, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(color: color.op(0.14), borderRadius: BorderRadius.circular(20)),
                              child: Text(tx.type == TxType.expense ? s.expense : s.income,
                                  style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                      radius: 28,
                      child: Column(
                        children: [
                          _row(c, s.category, cat == null ? '—' : s.catName(cat), bold: true),
                          Divider(height: 1, color: c.divider),
                          _row(c, s.time, '${hm(tx.date)} · ${dm(tx.date)}, ${tx.date.year}', bold: true),
                          Divider(height: 1, color: c.divider),
                          _row(c, s.note, tx.note.isEmpty ? s.noNote : tx.note),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: _btn(
                            icon: Icons.edit_outlined,
                            label: s.edit,
                            bg: c.card,
                            fg: c.text,
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (_) => AddTransactionScreen(editing: tx),
                            )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _btn(
                            icon: Icons.delete_outline,
                            label: s.delete,
                            bg: c.expense.op(0.15),
                            fg: c.expense,
                            onTap: () => _confirmDelete(context, store, tx),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppStore store, Tx tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.current.deleteTxQ),
        content: Text(S.current.cannotUndo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.current.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(S.current.delete)),
        ],
      ),
    );
    if (ok == true) {
      store.deleteTx(tx.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Widget _row(AppColors c, String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Text(k, style: TextStyle(color: c.muted, fontSize: 16)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                      color: bold ? c.text : c.muted)),
            ),
          ],
        ),
      );

  Widget _btn({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
}
