import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense_model.dart';

// ── Category metadata ──────────────────────────────────────────────────────
class _Cat {
  final IconData icon;
  final Color color;
  const _Cat(this.icon, this.color);
}

_Cat _catFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('dining') || c.contains('food') || c.contains('restaur')) {
    return const _Cat(Icons.restaurant, Color(0xFFFF6B6B));
  } else if (c.contains('travel') || c.contains('transport') || c.contains('uber')) {
    return const _Cat(Icons.flight_takeoff, Color(0xFF6C63FF));
  } else if (c.contains('medical') || c.contains('health') || c.contains('pharmacy') || c.contains('lab')) {
    return const _Cat(Icons.local_hospital, Color(0xFF0D9488));
  } else if (c.contains('groceri') || c.contains('supermark') || c.contains('supplies')) {
    return const _Cat(Icons.shopping_cart, Color(0xFFF59E0B));
  } else if (c.contains('entertainment') || c.contains('cinema') || c.contains('movie')) {
    return const _Cat(Icons.movie, Color(0xFFEC4899));
  } else if (c.contains('utility') || c.contains('electric') || c.contains('gas') || c.contains('internet')) {
    return const _Cat(Icons.bolt, Color(0xFF3B82F6));
  }
  return const _Cat(Icons.receipt_long, Color(0xFF64748B));
}

// ── Screen ─────────────────────────────────────────────────────────────────
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

enum _Filter { all, thisWeek, thisMonth, category }

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _Filter _activeFilter = _Filter.all;
  String? _categoryFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Filtering logic ────────────────────────────────────────────────────────
  List<Expense> _filtered(List<Expense> all) {
    final now = DateTime.now();
    return all.where((e) {
      // Search
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!e.merchantName.toLowerCase().contains(q) &&
            !e.category.toLowerCase().contains(q)) {
          return false;
        }
      }
      // Time filter
      if (_activeFilter == _Filter.thisWeek) {
        final weekAgo = now.subtract(const Duration(days: 7));
        if (e.date.isBefore(weekAgo)) return false;
      } else if (_activeFilter == _Filter.thisMonth) {
        if (e.date.month != now.month || e.date.year != now.year) return false;
      } else if (_activeFilter == _Filter.category && _categoryFilter != null) {
        if (!e.category.toLowerCase().contains(_categoryFilter!.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ── Category picker ────────────────────────────────────────────────────────
  Future<void> _pickCategory(List<Expense> expenses) async {
    final cats = expenses.map((e) => e.category).toSet().toList()..sort();
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Filter by Category'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('All categories'),
          ),
          ...cats.map((c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, c),
                child: Text(c),
              )),
        ],
      ),
    );
    if (chosen != null) {
      setState(() {
        _activeFilter = _Filter.category;
        _categoryFilter = chosen.isEmpty ? null : chosen;
      });
    }
  }

  // ── Delete with undo ───────────────────────────────────────────────────────
  Future<void> _delete(BuildContext ctx, Expense exp) async {
    final provider = ctx.read<ExpenseProvider>();
    await provider.deleteExpense(exp.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${exp.merchantName} deleted'),
      backgroundColor: const Color(0xFF1A1D1E),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: const Color(0xFF89F5E7),
        onPressed: () => provider.insertExpense(exp),
      ),
    ));
  }

  // ── Detail bottom-sheet ────────────────────────────────────────────────────
  void _showDetail(BuildContext ctx, Expense exp, String currencySymbol) {
    final fmt = NumberFormat.currency(symbol: currencySymbol);
    final cat = _catFor(exp.category);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.all(24), children: [
            // Header
            Row(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icon, color: cat.color, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(exp.merchantName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(DateFormat('EEE, MMM d yyyy  •  hh:mm a').format(exp.date),
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 20),
            // Total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF006A61),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                const Text('Total Amount', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(fmt.format(exp.total),
                    style: const TextStyle(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 20),
            // Info row
            _detailRow('Category', exp.category),
            _detailRow('Status', exp.status.isNotEmpty ? exp.status : 'Captured'),
            if (exp.memo.isNotEmpty) _detailRow('Memo', exp.memo),
            // Items
            if (exp.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              ...exp.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.name,
                        style: const TextStyle(fontSize: 14))),
                    Text(fmt.format(item.price),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 24),
            // Delete button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _delete(ctx, exp);
              },
              icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A)),
              label: const Text('Delete Expense',
                  style: TextStyle(color: Color(0xFFBA1A1A))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFDAD6), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer2<ExpenseProvider, SettingsProvider>(
          builder: (ctx, provider, settings, _) {
            final currencySymbol = settings.currencySymbol;
            final allExpenses = provider.expenses;
            final filtered = _filtered(allExpenses);

            // Group by date
            final Map<String, List<Expense>> grouped = {};
            for (final e in filtered) {
              final key = DateFormat('yyyy-MM-dd').format(e.date);
              grouped.putIfAbsent(key, () => []).add(e);
            }
            final sortedKeys = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a));

            return Column(children: [
              // ── Top bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('History',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    // Total badge
                    if (allExpenses.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006A61).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${NumberFormat.currency(symbol: currencySymbol).format(allExpenses.fold(0.0, (s, e) => s + e.total))} total',
                          style: const TextStyle(
                              color: Color(0xFF006A61),
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E3E5)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search merchant or category...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() {
                                _query = '';
                                _searchCtrl.clear();
                              }),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Filter chips ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  _filterChip('All', _activeFilter == _Filter.all,
                      () => setState(() => _activeFilter = _Filter.all)),
                  const SizedBox(width: 8),
                  _filterChip('This Week', _activeFilter == _Filter.thisWeek,
                      () => setState(() => _activeFilter = _Filter.thisWeek)),
                  const SizedBox(width: 8),
                  _filterChip('This Month', _activeFilter == _Filter.thisMonth,
                      () => setState(() => _activeFilter = _Filter.thisMonth)),
                  const SizedBox(width: 8),
                  _filterChip(
                      _categoryFilter != null ? _categoryFilter! : 'Category',
                      _activeFilter == _Filter.category,
                      () => _pickCategory(allExpenses)),
                ]),
              ),
              const SizedBox(height: 12),

              // ── List ──
              Expanded(
                child: provider.isLoading && allExpenses.isEmpty
                    ? const Center(child: CircularProgressIndicator(
                        color: Color(0xFF006A61)))
                    : filtered.isEmpty
                        ? _emptyState()
                        : RefreshIndicator(
                            color: const Color(0xFF006A61),
                            onRefresh: () async {
                              final auth = ctx.read<AuthProvider>();
                              if (auth.user != null) {
                                await provider.fetchExpenses(auth.user!.uid);
                              }
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                              itemCount: sortedKeys.length,
                              itemBuilder: (ctx, i) {
                                final dateKey = sortedKeys[i];
                                final dayExpenses = grouped[dateKey]!;
                                final now = DateTime.now();
                                final todayKey = DateFormat('yyyy-MM-dd').format(now);
                                final yestKey = DateFormat('yyyy-MM-dd')
                                    .format(now.subtract(const Duration(days: 1)));
                                String label = DateFormat('EEE, MMM d, yyyy')
                                    .format(DateTime.parse(dateKey));
                                if (dateKey == todayKey) {
                                  label = 'Today';
                                } else if (dateKey == yestKey) { label = 'Yesterday'; }

                                final dayTotal = dayExpenses.fold(
                                    0.0, (s, e) => s + e.total);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Date header
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(label.toUpperCase(),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF94A3B8),
                                                    letterSpacing: 1.2)),
                                            Text(
                                              NumberFormat.currency(
                                                      symbol: currencySymbol)
                                                  .format(dayTotal),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Expense cards
                                      ...dayExpenses.map((exp) =>
                                          _ExpenseCard(
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
    );
  }

  Widget _filterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF006A61) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? const Color(0xFF006A61) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined,
            size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          _query.isNotEmpty ? 'No results for "$_query"' : 'No expenses yet',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        const Text('Start scanning receipts to see your history here',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      ]),
    );
  }
}

// ── Expense card widget (swipe-to-delete + tap) ────────────────────────────
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
    final fmt = NumberFormat.currency(symbol: currencySymbol);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(expense.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A)),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete Expense'),
              content: Text(
                  'Delete "${expense.merchantName}"? This cannot be undone.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA1A1A)),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete(),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(children: [
              // Icon
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.merchantName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${expense.category}  •  ${DateFormat('hh:mm a').format(expense.date)}',
                    style: const TextStyle(
                        color: Color(0xFF94A3B8), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )),
              const SizedBox(width: 12),
              // Amount + badge
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmt.format(expense.total),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006A61).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('CAPTURED',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w800,
                          color: Color(0xFF006A61), letterSpacing: 0.5)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
