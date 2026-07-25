import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense_model.dart';

// ── Category config ────────────────────────────────────────────────────────
class _CatConfig {
  final String label;
  final IconData icon;
  final Color color;
  const _CatConfig(this.label, this.icon, this.color);
}

_CatConfig _catFor(String category) {
  final c = category.toLowerCase();
  if (c.contains('dining') || c.contains('food') || c.contains('restaur')) {
    return const _CatConfig('Food & Drink', Icons.restaurant, Color(0xFFFF6B6B));
  } else if (c.contains('travel') || c.contains('transport') || c.contains('uber')) {
    return const _CatConfig('Travel', Icons.flight_takeoff, Color(0xFF6C63FF));
  } else if (c.contains('medical') || c.contains('health') || c.contains('pharmacy') || c.contains('lab')) {
    return const _CatConfig('Medical', Icons.local_hospital, Color(0xFF0D9488));
  } else if (c.contains('groceri') || c.contains('supermark') || c.contains('supplies')) {
    return const _CatConfig('Groceries', Icons.shopping_cart, Color(0xFFF59E0B));
  } else if (c.contains('entertainment') || c.contains('cinema')) {
    return const _CatConfig('Entertainment', Icons.movie, Color(0xFFEC4899));
  } else if (c.contains('utility') || c.contains('electric') || c.contains('internet')) {
    return const _CatConfig('Utilities', Icons.bolt, Color(0xFF3B82F6));
  }
  return const _CatConfig('Other', Icons.receipt_long, Color(0xFF64748B));
}

// ── Donut Painter ──────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> segments;
  final List<Color> colors;
  static const double _sw = 28;

  _DonutPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(_sw / 2, _sw / 2,
        size.width - _sw, size.height - _sw);
    double start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _sw
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < segments.length; i++) {
      final sweep = segments[i].value * 2 * math.pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start + 0.02, sweep - 0.04, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

// ── Dashboard Screen ───────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllHistory;
  const DashboardScreen({super.key, this.onViewAllHistory});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _primary = Color(0xFF006A61);
  static const _dark = Color(0xFF131B2E);

  // ── Expense detail sheet ───────────────────────────────────────────────
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
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(width: 52, height: 52,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icon, color: cat.color, size: 26)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(exp.merchantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(DateFormat('EEE, MMM d  •  hh:mm a').format(exp.date),
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ])),
            ]),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: _primary, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                const Text('Total Amount', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(fmt.format(exp.total),
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 20),
            _detailRow('Category', exp.category),
            _detailRow('Status', exp.status.isNotEmpty ? exp.status : 'Captured'),
            if (exp.memo.isNotEmpty) _detailRow('Memo', exp.memo),
            if (exp.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              ...exp.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
                  Text(fmt.format(item.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              )),
            ],
          ],
        ),
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

  // ── Build category data from expenses ──────────────────────────────────
  List<MapEntry<_CatConfig, double>> _categoryBreakdown(List<Expense> expenses) {
    final Map<String, double> totals = {};
    for (final e in expenses) {
      final label = _catFor(e.category).label;
      totals[label] = (totals[label] ?? 0) + e.total;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((entry) {
      // Find matching config
      final configs = [
        const _CatConfig('Food & Drink', Icons.restaurant, Color(0xFFFF6B6B)),
        const _CatConfig('Travel', Icons.flight_takeoff, Color(0xFF6C63FF)),
        const _CatConfig('Medical', Icons.local_hospital, Color(0xFF0D9488)),
        const _CatConfig('Groceries', Icons.shopping_cart, Color(0xFFF59E0B)),
        const _CatConfig('Entertainment', Icons.movie, Color(0xFFEC4899)),
        const _CatConfig('Utilities', Icons.bolt, Color(0xFF3B82F6)),
        const _CatConfig('Other', Icons.receipt_long, Color(0xFF64748B)),
      ];
      final cfg = configs.firstWhere((c) => c.label == entry.key,
          orElse: () => const _CatConfig('Other', Icons.receipt_long, Color(0xFF64748B)));
      return MapEntry(cfg, entry.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer2<ExpenseProvider, SettingsProvider>(
          builder: (ctx, provider, settings, _) {
            final auth = ctx.read<AuthProvider>();
            final expenses = provider.expenses;
            final currencySymbol = settings.currencySymbol;
            final fmt = NumberFormat.currency(symbol: currencySymbol);

            // This month's expenses
            final now = DateTime.now();
            final thisMonth = expenses.where(
                (e) => e.date.month == now.month && e.date.year == now.year).toList();

            // Last month — handle January correctly (month 1 → previous month is Dec of prior year)
            final prevMonth = now.month == 1 ? 12 : now.month - 1;
            final prevYear = now.month == 1 ? now.year - 1 : now.year;
            final lastMonth = expenses.where(
                (e) => e.date.month == prevMonth && e.date.year == prevYear).toList();

            final totalThis = thisMonth.fold(0.0, (s, e) => s + e.total);
            final totalLast = lastMonth.fold(0.0, (s, e) => s + e.total);
            final changePct = totalLast > 0
                ? ((totalThis - totalLast) / totalLast * 100).round()
                : 0;

            final catData = _categoryBreakdown(expenses);
            final grandTotal = catData.fold(0.0, (s, e) => s + e.value);

            final userName = auth.user?.name ?? 'User';
            final photoPath = settings.profilePhotoPath;

            return RefreshIndicator(
              color: _primary,
              onRefresh: () async {
                if (auth.user != null) {
                  await provider.fetchExpenses(auth.user!.uid);
                }
              },
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _buildHeader(ctx, userName, photoPath, settings, provider),
                )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _buildSpendingCard(fmt, totalThis, changePct),
                )),
                if (expenses.isNotEmpty) ...[
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: _buildQuickStats(expenses, fmt),
                  )),
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: _buildCategoryCard(catData, grandTotal),
                  )),
                ],
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _buildRecentScans(ctx, expenses, currencySymbol, fmt),
                )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  child: _buildInsightsBanner(expenses, fmt, currencySymbol),
                )),
              ]),
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext ctx, String name, String? photoPath,
      SettingsProvider settings, ExpenseProvider provider) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        GestureDetector(
          onTap: () {
            // Navigate to profile via parent navigator — just show snack
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('Go to Profile tab to manage your account'),
                  duration: Duration(seconds: 2)));
          },
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF89F5E7), width: 2),
              color: _dark,
            ),
            child: ClipOval(child: photoPath != null
                ? Image.file(File(photoPath), fit: BoxFit.cover)
                : Center(child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 18)))),
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back 👋', style: TextStyle(
              color: Colors.grey.shade500, fontSize: 12)),
          Text(name, style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ]),
      Row(children: [
        Icon(settings.notificationsOn
            ? Icons.notifications_outlined
            : Icons.notifications_off_outlined,
            color: settings.notificationsOn ? _primary : Colors.grey),
        const SizedBox(width: 8),
        if (provider.isLoading)
          const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _primary)),
      ]),
    ]);
  }

  // ── Spending card ──────────────────────────────────────────────────────
  Widget _buildSpendingCard(NumberFormat fmt, double total, int changePct) {
    final isUp = changePct > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF131B2E), Color(0xFF1E2D4E)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: const Color(0xFF131B2E).withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(right: -20, top: -20,
          child: Container(width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF89F5E7).withValues(alpha: 0.07)))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('THIS MONTH  •  ${DateFormat('MMM yyyy').format(DateTime.now()).toUpperCase()}',
              style: const TextStyle(color: Color(0xFF7C839B), fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          Text(fmt.format(total),
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUp
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isUp ? Colors.redAccent : Colors.greenAccent, size: 13),
                const SizedBox(width: 4),
                Text('${changePct.abs()}% vs last month',
                    style: TextStyle(
                        color: isUp ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ]),
      ]),
    );
  }

  // ── Quick stats row ─────────────────────────────────────────────────────
  Widget _buildQuickStats(List<Expense> expenses, NumberFormat fmt) {
    final now = DateTime.now();
    final thisWeek = expenses.where((e) =>
        e.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final avgPerScan = expenses.isEmpty ? 0.0 : expenses.fold(0.0, (s, e) => s + e.total) / expenses.length;

    return Row(children: [
      Expanded(child: _statBox('This Week', fmt.format(thisWeek.fold(0.0, (s, e) => s + e.total)), Icons.calendar_today_outlined)),
      const SizedBox(width: 12),
      Expanded(child: _statBox('Avg / Receipt', fmt.format(avgPerScan), Icons.receipt_outlined)),
      const SizedBox(width: 12),
      Expanded(child: _statBox('Total Scans', '${expenses.length}', Icons.document_scanner_outlined)),
    ]);
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: _primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ]),
    );
  }

  // ── Category donut card ─────────────────────────────────────────────────
  Widget _buildCategoryCard(List<MapEntry<_CatConfig, double>> catData, double grandTotal) {
    if (catData.isEmpty) return const SizedBox.shrink();

    final top = catData.take(5).toList();
    final colors = top.map((e) => e.key.color).toList();
    final segments = top.map((e) => MapEntry(e.key.label, grandTotal > 0 ? e.value / grandTotal : 0.0)).toList();
    final topCat = top.first;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Spend Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Donut
          SizedBox(width: 130, height: 130,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(
                  size: const Size(130, 130),
                  painter: _DonutPainter(segments: segments, colors: colors)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(topCat.key.icon, color: topCat.key.color, size: 20),
                const SizedBox(height: 4),
                Text(topCat.key.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
              ]),
            ]),
          ),
          const SizedBox(width: 20),
          // Legend
          Expanded(child: Column(
            children: top.map((entry) {
              final pct = grandTotal > 0 ? (entry.value / grandTotal * 100).round() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: entry.key.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key.label,
                      style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  Text('$pct%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              );
            }).toList(),
          )),
        ]),
      ]),
    );
  }

  // ── Recent scans ────────────────────────────────────────────────────────
  Widget _buildRecentScans(BuildContext ctx, List<Expense> expenses,
      String currencySymbol, NumberFormat fmt) {
    final recent = expenses.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recent Scans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (expenses.length > 5)
            TextButton(
              onPressed: widget.onViewAllHistory,
              style: TextButton.styleFrom(padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0)),
              child: const Text('View All', style: TextStyle(color: _primary, fontSize: 13)),
            ),
        ]),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Column(children: [
              Icon(Icons.receipt_long_outlined, size: 40, color: Color(0xFFCBD5E1)),
              SizedBox(height: 8),
              Text('No scans yet', style: TextStyle(color: Color(0xFF94A3B8))),
            ])),
          )
        else
          ...recent.map((exp) {
            final cat = _catFor(exp.category);
            return GestureDetector(
              onTap: () => _showDetail(ctx, exp, currencySymbol),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(children: [
                  Container(width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(exp.merchantName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                    Text('${exp.category}  •  ${DateFormat('MMM d').format(exp.date)}',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(fmt.format(exp.total),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('CAPTURED',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                              color: _primary, letterSpacing: 0.5)),
                    ),
                  ]),
                ]),
              ),
            );
          }),
      ]),
    );
  }

  // ── Insights banner ─────────────────────────────────────────────────────
  Widget _buildInsightsBanner(List<Expense> expenses, NumberFormat fmt, String currencySymbol) {
    // Find top category this month
    final now = DateTime.now();
    final thisMonth = expenses.where(
        (e) => e.date.month == now.month && e.date.year == now.year).toList();

    String message;
    if (thisMonth.isEmpty) {
      message = 'Start scanning receipts to get AI-powered spending insights.';
    } else {
      final catTotals = <String, double>{};
      for (final e in thisMonth) {
        final label = _catFor(e.category).label;
        catTotals[label] = (catTotals[label] ?? 0) + e.total;
      }
      final topCat = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      final avg = thisMonth.fold(0.0, (s, e) => s + e.total) / thisMonth.length;
      message = 'Your top category is "${topCat.key}" at ${fmt.format(topCat.value)}. '
          'Average receipt: ${fmt.format(avg)}. Scan more to improve accuracy.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, _primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Icon(Icons.insights, color: Colors.white, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Smart Insights',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }
}
