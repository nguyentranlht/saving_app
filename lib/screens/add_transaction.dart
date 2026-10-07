import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/calculator.dart';
import '../widgets/common.dart';
import 'budget.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen(
      {super.key, this.initialType = TxType.expense, this.editing, this.editingRule, this.initialFreq});
  final TxType initialType;
  final Tx? editing;

  /// Sửa một giao dịch định kỳ (thay vì một giao dịch).
  final Recurring? editingRule;
  final Freq? initialFreq;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late TxType _type;
  String? _catId;
  late DateTime _date;
  Freq? _freq; // null = không lặp
  final _amountCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  int get _amount => int.tryParse(_amountCtl.text.replaceAll('.', '')) ?? 0;

  bool get _ruleMode => widget.editingRule != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final rule = widget.editingRule;
    _type = rule?.type ?? e?.type ?? widget.initialType;
    _date = rule?.next ?? e?.date ?? DateTime.now();
    _freq = rule?.freq ?? widget.initialFreq;
    if (e != null || rule != null) {
      _catId = rule?.categoryId ?? e!.categoryId;
      _amountCtl.text = groupDigits(rule?.amount ?? e!.amount);
      _noteCtl.text = rule?.note ?? e!.note;
    }
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  Future<void> _openCalculator(Color accent) async {
    FocusScope.of(context).unfocus(); // ẩn bàn phím số
    final v = await showAmountCalculator(context, initial: _amount, accent: accent);
    if (v != null && mounted) setState(() => _amountCtl.text = groupDigits(v));
  }

  void _addQuick(int v) {
    setState(() => _amountCtl.text = groupDigits(_amount + v));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: _freq == null ? 365 : 365 * 3)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (!mounted) return;
    setState(() => _date = DateTime(d.year, d.month, d.day, t?.hour ?? _date.hour, t?.minute ?? _date.minute));
  }

  Future<void> _pickFreq(S s) async {
    final c = AppColors.of(context);
    final options = <Freq?>[if (!_ruleMode) null, ...Freq.values];
    final picked = await showModalBottomSheet<(Freq?,)>(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final f in options)
                ListTile(
                  title: Text(f == null ? s.freqName(null) : s.freqDetail(f, _date),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: _freq == f ? Icon(Icons.check, color: c.primary) : null,
                  onTap: () => Navigator.pop(ctx, (f,)),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _freq = picked.$1);
  }

  Future<void> _deleteRule(AppStore store, S s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteRecurringQ),
        content: Text(s.deleteRecurringBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    store.deleteRecurring(widget.editingRule!.id);
    Navigator.of(context).pop();
  }

  void _save(AppStore store) {
    final catId = _catId ?? store.catsOf(_type).first.id;
    final e = widget.editing;
    final rule = widget.editingRule;
    if (rule != null) {
      final scheduleChanged = rule.freq != _freq || _date != rule.next;
      store.updateRecurring(
        Recurring(
          id: rule.id,
          amount: _amount,
          type: _type,
          categoryId: catId,
          note: _noteCtl.text.trim(),
          freq: _freq!,
          anchor: scheduleChanged ? _date : rule.anchor,
          nextIndex: rule.nextIndex,
          lastGenerated: rule.lastGenerated,
          active: rule.active,
        ),
        scheduleChanged: scheduleChanged,
      );
    } else if (e == null && _freq != null) {
      store.addRecurring(Recurring(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: _amount,
        type: _type,
        categoryId: catId,
        note: _noteCtl.text.trim(),
        freq: _freq!,
        anchor: _date,
      ));
    } else if (e == null) {
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
        recurringId: e.recurringId,
      ));
    }
    // Cảnh báo ngân sách (SnackBar nằm ở cấp app nên vẫn hiện sau khi đóng màn này).
    if (_type == TxType.expense) {
      final warn = budgetWarning(store, catId, _date);
      if (warn != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(warn.text),
          backgroundColor: warn.over ? AppColors.of(context).expense : const Color(0xFFB45309),
        ));
      }
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
                          child: Text(_ruleMode ? s.editRecurring : (widget.editing == null ? s.newTx : s.editTx),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                      ),
                      if (_ruleMode)
                        CircleBtn(icon: Icons.delete_outline, fg: c.expense, onTap: () => _deleteRule(store, s))
                      else
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
                                inputFormatters: [MoneyFormatter()],
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
                            const SizedBox(width: 6),
                            // Máy tính: 45.000 + 30.000, 600.000 ÷ 4…
                            IconButton.filledTonal(
                              tooltip: s.calculator,
                              onPressed: () => _openCalculator(accent),
                              icon: const Icon(Icons.calculate_outlined),
                            ),
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
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('+${compact(v)}',
                                            style: const TextStyle(fontWeight: FontWeight.w800)),
                                      ),
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
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      // Ô cao theo cỡ chữ: đệm + viền 16, icon 46, khoảng cách 8, 2 dòng tên.
                      mainAxisExtent: 72 + MediaQuery.textScalerOf(context).scale(13) * 1.5 * 2,
                    ),
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
                                    child: Text(
                                        '${_freq == null ? '' : '${_ruleMode ? s.nextLabel : s.startsOn}: '}'
                                        '${dayLabel(_date).replaceFirst(' · ', ', ')} · ${hm(_date)}',
                                        style: const TextStyle(fontSize: 16))),
                                Text(s.change, style: TextStyle(color: c.muted, fontSize: 15)),
                              ],
                            ),
                          ),
                        ),
                        // Lặp lại: chỉ khi ghi mới hoặc sửa giao dịch định kỳ.
                        if (widget.editing == null) ...[
                          Divider(height: 1, color: c.divider),
                          InkWell(
                            onTap: () => _pickFreq(s),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.repeat, color: _freq == null ? c.muted : c.primary),
                                  const SizedBox(width: 14),
                                  Expanded(child: Text(s.repeat, style: const TextStyle(fontSize: 16))),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(_freq == null ? s.freqName(null) : s.freqDetail(_freq!, _date),
                                        textAlign: TextAlign.right,
                                        maxLines: 2,
                                        style: TextStyle(
                                            color: _freq == null ? c.muted : c.primary,
                                            fontSize: 15,
                                            fontWeight: _freq == null ? FontWeight.w400 : FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
