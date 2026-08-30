import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense_model.dart';
import '../widgets/premium_background.dart';
import 'review_screen.dart';

enum _Filter { all, thisWeek, thisMonth, category }

// ── Category Configuration ──────────────────────────────────────────
class _CatConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _CatConfig(this.label, this.icon, this.color);
}

_CatConfig _catFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('dining') || c.contains('food') || c.contains('restaur')) {
    return const _CatConfig('Food & Dining', Icons.restaurant_rounded, Color(0xFFD87D7D));
  } else if (c.contains('travel') || c.contains('transport') || c.contains('uber') || c.contains('flight')) {
    return const _CatConfig('Travel & Transit', Icons.flight_takeoff_rounded, Color(0xFF9B92C2));
  } else if (c.contains('medical') || c.contains('health') || c.contains('pharmacy') || c.contains('lab')) {
    return const _CatConfig('Health & Medical', Icons.favorite_rounded, Color(0xFF7BB5A5));
  } else if (c.contains('groceri') || c.contains('supermark') || c.contains('supplies') || c.contains('store')) {
    return const _CatConfig('Groceries & Retail', Icons.local_mall_rounded, Color(0xFFD7A775));
  } else if (c.contains('entertainment') || c.contains('cinema') || c.contains('movie')) {
    return const _CatConfig('Entertainment', Icons.confirmation_number_rounded, Color(0xFFCC8FAD));
  } else if (c.contains('utility') || c.contains('electric') || c.contains('internet') || c.contains('gas')) {
    return const _CatConfig('Bills & Utilities', Icons.bolt_rounded, Color(0xFF849DC5));
  }
  return const _CatConfig('General Expense', Icons.receipt_long_rounded, Color(0xFF8EA3B0));
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Minimalist Dark Palette
  static const Color _cardBg     = Color(0xFF222329);
  static const Color _primary    = Color(0xFF2563EB);
  static const Color _secondary  = Color(0xFF06B6D4);
  static const Color _text       = Color(0xFFFFFFFF);
  static const Color _textMuted  = Color(0xFF94A3B8);
  static const Color _border     = Colors.transparent;

  final _searchCtrl = TextEditingController();
  String _query = '';
  _Filter _activeFilter = _Filter.all;
  String? _categoryFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _delete(BuildContext ctx, Expense exp) {
    ctx.read<ExpenseProvider>().deleteExpense(exp.id);
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('Removed "${exp.merchantName}"'),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _pickCategory(List<Expense> all) {
    final cats = all.map((e) => e.category.trim()).where((c) => c.isNotEmpty).toSet().toList()..sort();
    if (cats.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by category', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _textMuted),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(color: _border),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: cats.map((c) {
                final cfg = _catFor(c);
                final selected = _activeFilter == _Filter.category && _categoryFilter == c;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Icon(cfg.icon, color: cfg.color, size: 24),
                  title: Text(c, style: TextStyle(color: _text, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, fontSize: 16)),
                  trailing: selected ? const Icon(Icons.check_circle_rounded, color: _primary) : null,
                  onTap: () {
                    setState(() {
                      _activeFilter = _Filter.category;
                      _categoryFilter = c;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void _showDetail(BuildContext ctx, Expense exp, String currencySymbol) {
    final fmt = NumberFormat.currency(symbol: exp.currency.isNotEmpty ? exp.currency : currencySymbol);
    final cat = _catFor(exp.category);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(children: [
              Icon(cat.icon, color: cat.color, size: 30),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(exp.merchantName, style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                  const SizedBox(height: 4),
                  Text(DateFormat('EEE, MMMM d, yyyy  •  hh:mm a').format(exp.date),
                      style: const TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w400)),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: _primary),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<ExpenseProvider>().updateCurrentExpense(exp);
                  Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ReviewScreen()));
                },
              ),
            ]),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _primary.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total amount', style: TextStyle(color: _secondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Verified', style: TextStyle(color: _secondary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(fmt.format(exp.total),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.8)),
              ]),
            ),
            const SizedBox(height: 28),
            _detailRow('Expense Category', exp.category),
            _detailRow('Verification Mode', exp.status.isNotEmpty ? exp.status : 'AI extraction'),
            if (exp.memo.isNotEmpty) _detailRow('Notes', exp.memo),
            if (exp.items.isNotEmpty) ...[
              const SizedBox(height: 22),
              const Text('Receipt Items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _textMuted)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: exp.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(item.name, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w500))),
                      Text(fmt.format(item.price), style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: _textMuted, fontSize: 14, fontWeight: FontWeight.w400)),
      Text(value, style: const TextStyle(color: _text, fontWeight: FontWeight.w500, fontSize: 14)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Consumer2<ExpenseProvider, SettingsProvider>(
          builder: (ctx, provider, settings, _) {
            final allExpenses = provider.expenses;
            final currencySymbol = settings.currencySymbol;
            final now = DateTime.now();

            List<Expense> filtered = allExpenses.where((e) {
              if (_query.isNotEmpty) {
                final q = _query.toLowerCase();
                final matchName = e.merchantName.toLowerCase().contains(q);
                final matchCat = e.category.toLowerCase().contains(q);
                final matchMemo = e.memo.toLowerCase().contains(q);
                if (!matchName && !matchCat && !matchMemo) return false;
              }
              if (_activeFilter == _Filter.thisWeek) {
                final weekAgo = now.subtract(const Duration(days: 7));
                if (e.date.isBefore(weekAgo)) return false;
              } else if (_activeFilter == _Filter.thisMonth) {
                if (e.date.month != now.month || e.date.year != now.year) return false;
              } else if (_activeFilter == _Filter.category && _categoryFilter != null) {
                if (e.category.toLowerCase() != _categoryFilter!.toLowerCase()) return false;
              }
              return true;
            }).toList();

            final Map<String, List<Expense>> grouped = {};
            for (final e in filtered) {
              final key = DateFormat('yyyy-MM-dd').format(e.date);
              grouped.putIfAbsent(key, () => []).add(e);
            }
            final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
            final totalAll = allExpenses.fold(0.0, (s, e) => s + e.total);

            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('History', style: TextStyle(color: _text, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                    if (allExpenses.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${NumberFormat.currency(symbol: currencySymbol).format(totalAll)} TOTAL',
                          style: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: const TextStyle(color: _textMuted, fontSize: 15, fontWeight: FontWeight.w400),
                      prefixIcon: const Icon(Icons.search_rounded, color: _textMuted, size: 22),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: _textMuted, size: 20),
                              onPressed: () => setState(() {
                                _query = '';
                                _searchCtrl.clear();
                              }),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  _filterChip('All', _activeFilter == _Filter.all, () => setState(() => _activeFilter = _Filter.all)),
                  const SizedBox(width: 8),
                  _filterChip('This week', _activeFilter == _Filter.thisWeek, () => setState(() => _activeFilter = _Filter.thisWeek)),
                  const SizedBox(width: 8),
                  _filterChip('This month', _activeFilter == _Filter.thisMonth, () => setState(() => _activeFilter = _Filter.thisMonth)),
                  const SizedBox(width: 8),
                  _filterChip(
                    _categoryFilter != null && _activeFilter == _Filter.category ? _categoryFilter! : 'Category',
                    _activeFilter == _Filter.category,
                    () => _pickCategory(allExpenses),
                    icon: Icons.keyboard_arrow_down_rounded,
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: provider.isLoading && allExpenses.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: _primary))
                    : filtered.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            color: _primary,
                            backgroundColor: _cardBg,
                            onRefresh: () async {
                              final auth = ctx.read<AuthProvider>();
                              if (auth.user != null) {
                                await provider.fetchExpenses(auth.user!.uid);
                              }
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                              itemCount: sortedKeys.length,
                              itemBuilder: (ctx, i) {
                                final dateKey = sortedKeys[i];
                                final dayExpenses = grouped[dateKey]!;
                                final todayKey = DateFormat('yyyy-MM-dd').format(now);
                                final yestKey = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
                                
                                String label = DateFormat('MMMM d, yyyy').format(DateTime.parse(dateKey));
                                if (dateKey == todayKey) {
                                  label = 'Today';
                                } else if (dateKey == yestKey) {
                                  label = 'Yesterday';
                                }

                                final dayTotal = dayExpenses.fold(0.0, (s, e) => s + e.total);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 32),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
                                            Text(
                                              NumberFormat.currency(symbol: currencySymbol).format(dayTotal),
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...dayExpenses.map((exp) => _ExpenseCard(
                                            expense: exp,
                                            currencySymbol: currencySymbol,
                                            onTap: () => _showDetail(ctx, exp, currencySymbol),
                                            onDelete: () => _delete(ctx, exp),
                                          )),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ]);
          },
        ),
      ),
    ));
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _primary : _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? _primary : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: active ? Colors.white : _textMuted,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w400)),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: active ? Colors.white : _textMuted),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.history_rounded, size: 48, color: _textMuted),

        const SizedBox(height: 24),
        Text(
          _query.isNotEmpty ? 'No matches found' : 'No transactions yet',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text),
        ),
        const SizedBox(height: 8),
        const Text('Your scanned receipts will appear here',
            style: TextStyle(color: _textMuted, fontSize: 15)),
      ]),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.currencySymbol,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cat = _catFor(expense.category);
    final sym = expense.currency.isNotEmpty ? expense.currency : currencySymbol;
    final fmt = NumberFormat.currency(symbol: sym);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 28),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF111A2E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Delete transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              content: Text('Are you sure you want to delete this transaction from ${expense.merchantName}?',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete(),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF222329),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(children: [
              Icon(cat.icon, color: cat.color, size: 26),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.merchantName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(expense.category, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmt.format(expense.total),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

