import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Tự thêm dấu chấm ngăn cách hàng nghìn khi gõ.
class _MoneyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = groupDigits(int.parse(digits));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.initialType = TxType.expense, this.editing});
  final TxType initialType;
  final Tx? editing;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TxType _type;
  String? _catId;
  late DateTime _date;
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  int get _amount => int.tryParse(_amountCtl.text.replaceAll('.', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.type ?? widget.initialType;
    _date = e?.date ?? DateTime.now();
    if (e != null) {
      _catId = e.categoryId;
      _amountCtl.text = groupDigits(e.amount);
      _noteCtl.text = e.note;
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  void _addQuick(int v) {
    setState(() => _amountCtl.text = groupDigits(_amount + v));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (!mounted) return;
    setState(() => _date = DateTime(d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  void _save(AppStore store) {
    final catId = _catId ?? store.catsOf(_type).first.id;
    final e = widget.editing;
    if (e == null) {
      store.addTx(Tx(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: _amount,
        type: _type,
        categoryId: catId,
        note: _noteCtl.text.trim(),
        date: _date,
      ));
    } else {
      store.updateTx(Tx(
        id: e.id,
        amount: _amount,
        type: _type,
        categoryId: catId,
        note: _noteCtl.text.trim(),
        date: _date,
      ));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final store = StoreScope.of(context);
    final s = S.of(context);
    final cats = store.catsOf(_type);
    final selected = cats.any((x) => x.id == _catId) ? _catId! : (cats.isNotEmpty ? cats.first.id : '');
    final accent = _type == TxType.expense ? c.expense : c.income;
    final canSave = _amount > 0 && cats.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Row(
                    children: [
                      CircleBtn(icon: Icons.close, onTap: () => Navigator.of(context).pop()),
                      Expanded(
                        child: Center(
                          child: Text(widget.editing == null ? s.newTx : s.editTx,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 46),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Segmented(
                    labels: [s.expense, s.income],
                    index: _type == TxType.expense ? 0 : 1,
                    activeColors: [c.expense, c.income],
                    height: 46,
                    onChanged: (i) => setState(() {
                      _type = i == 0 ? TxType.expense : TxType.income;
                      _catId = null;
                    }),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    radius: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.amount, style: TextStyle(color: c.muted, fontSize: 15)),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _amountCtl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_MoneyFormatter()],
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: c.text),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: c.muted.op(0.6)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Text('đ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: c.muted)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            for (final v in [50000, 100000, 200000, 500000])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () => _addQuick(v),
                                    child: Container(
                                      height: 46,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          color: c.chip, borderRadius: BorderRadius.circular(16)),
                                      child: Text('+${compact(v)}',
                                          style: const TextStyle(fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(s.category, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.86,
                    children: [
                      for (final cat in cats)
                        GestureDetector(
                          onTap: () => setState(() => _catId = cat.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: selected == cat.id ? Color(cat.color).op(c.isDark ? 0.2 : 0.14) : c.card,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: selected == cat.id ? Color(cat.color) : Colors.transparent, width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CatIcon(category: cat, size: 46),
                                const SizedBox(height: 8),
                                Text(s.catName(cat),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: c.muted),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: _noteCtl,
                                decoration: InputDecoration(
                                  hintText: s.noteHint,
                                  hintStyle: TextStyle(color: c.muted),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(height: 1, color: c.divider),
                        InkWell(
                          onTap: _pickDate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: c.muted),
                                const SizedBox(width: 14),
                                Expanded(
                                    child: Text('${dayLabel(_date).replaceFirst(' · ', ', ')} · ${hm(_date)}',
                                        style: const TextStyle(fontSize: 16))),
                                Text(s.change, style: TextStyle(color: c.muted, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: canSave ? () => _save(store) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: accent.op(0.35),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(_type == TxType.expense ? s.saveExpense : s.saveIncome,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
