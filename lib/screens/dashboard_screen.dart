import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense_model.dart';
import '../widgets/premium_background.dart';

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
    return const _CatConfig('Food & Dining', Icons.restaurant_rounded, Color(0xFFFF6B6B));
  } else if (c.contains('travel') || c.contains('transport') || c.contains('uber') || c.contains('flight')) {
    return const _CatConfig('Travel & Transit', Icons.flight_takeoff_rounded, Color(0xFF8B5CF6));
  } else if (c.contains('medical') || c.contains('health') || c.contains('pharmacy') || c.contains('lab')) {
    return const _CatConfig('Health & Medical', Icons.favorite_rounded, Color(0xFF10B981));
  } else if (c.contains('groceri') || c.contains('supermark') || c.contains('supplies') || c.contains('store')) {
    return const _CatConfig('Groceries & Retail', Icons.local_mall_rounded, Color(0xFFF59E0B));
  } else if (c.contains('entertainment') || c.contains('cinema') || c.contains('movie')) {
    return const _CatConfig('Entertainment', Icons.confirmation_number_rounded, Color(0xFFEC4899));
  } else if (c.contains('utility') || c.contains('electric') || c.contains('internet') || c.contains('gas')) {
    return const _CatConfig('Bills & Utilities', Icons.bolt_rounded, Color(0xFF3B82F6));
  }
  return const _CatConfig('General Expense', Icons.receipt_long_rounded, Color(0xFF06B6D4));
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, double>> segments;
  final List<Color> colors;
  static const double _sw = 22;

  _DonutPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(_sw / 2, _sw / 2, size.width - _sw, size.height - _sw);
    
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _sw
      ..color = const Color(0xFF1E293B);
    canvas.drawOval(rect, trackPaint);

    double start = -math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _sw
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < segments.length; i++) {
      final sweep = segments[i].value * 2 * math.pi;
      if (sweep <= 0.04) continue;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start + 0.05, sweep - 0.1, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllHistory;
  const DashboardScreen({super.key, this.onViewAllHistory});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Minimalist Dark Palette
  static const Color _bg         = Color(0xFF090E17);
  static const Color _cardBg     = Color(0xFF141415);
  static const Color _primary    = Color(0xFF2563EB);
  static const Color _secondary  = Color(0xFF06B6D4);
  static const Color _text       = Color(0xFFFFFFFF);
  static const Color _textMuted  = Color(0xFF94A3B8);
  static const Color _border     = Colors.transparent;

  void _showDetail(BuildContext ctx, Expense exp, String fallbackCurrencySymbol) {
    final sym = exp.currency.isNotEmpty ? exp.currency : fallbackCurrencySymbol;
    final fmt = NumberFormat.currency(symbol: sym);
    final cat = _catFor(exp.category);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cat.color.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(cat.icon, color: cat.color, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(exp.merchantName, style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                  const SizedBox(height: 4),
                  Text(DateFormat('EEE, MMMM d, yyyy  •  hh:mm a').format(exp.date),
                      style: const TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w400)),
                ]),
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
                  color: const Color(0xFF111927),
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

  List<MapEntry<_CatConfig, double>> _categoryBreakdown(List<Expense> expenses) {
    final Map<String, double> totals = {};
    for (final e in expenses) {
      final label = _catFor(e.category).label;
      totals[label] = (totals[label] ?? 0) + e.total;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((entry) {
      final configs = [
        const _CatConfig('Food & Dining', Icons.restaurant_rounded, Color(0xFFFF6B6B)),
        const _CatConfig('Travel & Transit', Icons.flight_takeoff_rounded, Color(0xFF8B5CF6)),
        const _CatConfig('Health & Medical', Icons.favorite_rounded, Color(0xFF10B981)),
        const _CatConfig('Groceries & Retail', Icons.local_mall_rounded, Color(0xFFF59E0B)),
        const _CatConfig('Entertainment', Icons.confirmation_number_rounded, Color(0xFFEC4899)),
        const _CatConfig('Bills & Utilities', Icons.bolt_rounded, Color(0xFF3B82F6)),
        const _CatConfig('General Expense', Icons.receipt_long_rounded, Color(0xFF06B6D4)),
      ];
      final cfg = configs.firstWhere((c) => c.label == entry.key,
          orElse: () => const _CatConfig('General Expense', Icons.receipt_long_rounded, Color(0xFF06B6D4)));
      return MapEntry(cfg, entry.value);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Consumer2<ExpenseProvider, SettingsProvider>(
          builder: (ctx, provider, settings, _) {
            final auth = ctx.read<AuthProvider>();
            final expenses = provider.expenses;
            final currencySymbol = settings.currencySymbol;
            final fmt = NumberFormat.currency(symbol: currencySymbol);

            final now = DateTime.now();
            final thisMonth = expenses.where(
                (e) => e.date.month == now.month && e.date.year == now.year).toList();

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
              color: _secondary,
              backgroundColor: _cardBg,
              onRefresh: () async {
                if (auth.user != null) {
                  await provider.fetchExpenses(auth.user!.uid);
                }
              },
              child: CustomScrollView(slivers: [
                if (provider.isLoading)
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _buildHeader(ctx, userName, photoPath, settings, provider),
                  )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildSpendingCard(fmt, totalThis, changePct),
                )),
                if (expenses.isNotEmpty) ...[
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _buildQuickStats(expenses, fmt),
                  )),
                  SliverToBoxAdapter(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: _buildCategoryCard(catData, grandTotal, fmt),
                  )),
                ],
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildRecentScans(ctx, expenses, currencySymbol, fmt),
                )),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: _buildInsightsBanner(expenses, fmt, currencySymbol),
                )),
              ]),
            );
          },
        ),
      ),
    ));
  }

  Widget _buildHeader(BuildContext ctx, String name, String? photoPath,
      SettingsProvider settings, ExpenseProvider provider) {
    if (!provider.isLoading) return const SizedBox.shrink();

    return const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 14),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: _secondary),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingCard(NumberFormat fmt, double total, int changePct) {
    final isUp = changePct > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF0B1220)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Monthly spend',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            Text(DateFormat('MMMM').format(DateTime.now()),
                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 24),
        Text(fmt.format(total),
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w600, letterSpacing: -1.0, height: 1.1)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isUp ? const Color(0xFFF43F5E).withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: isUp ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7), size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('${changePct.abs()}% vs last month',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: isUp ? const Color(0xFFFDA4AF) : const Color(0xFF6EE7B7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildQuickStats(List<Expense> expenses, NumberFormat fmt) {
    final now = DateTime.now();
    final thisWeek = expenses.where((e) =>
        e.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final avgPerScan = expenses.isEmpty ? 0.0 : expenses.fold(0.0, (s, e) => s + e.total) / expenses.length;

    return Row(children: [
      Expanded(child: _statModule('This week', fmt.format(thisWeek.fold(0.0, (s, e) => s + e.total)), Icons.calendar_today_rounded)),
      const SizedBox(width: 12),
      Expanded(child: _statModule('Avg / scan', fmt.format(avgPerScan), Icons.receipt_long_rounded)),
      const SizedBox(width: 12),
      Expanded(child: _statModule('Receipts', '${expenses.length}', Icons.document_scanner_rounded)),
    ]);
  }

  Widget _statModule(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 22, color: _textMuted),
        const SizedBox(height: 16),
        Text(value, style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.3),
            overflow: TextOverflow.ellipsis, maxLines: 1),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w400),
            overflow: TextOverflow.ellipsis, maxLines: 1),
      ]),
    );
  }

  Widget _buildCategoryCard(List<MapEntry<_CatConfig, double>> catData, double grandTotal, NumberFormat fmt) {
    if (catData.isEmpty) return const SizedBox.shrink();

    final top = catData.take(5).toList();
    final colors = top.map((e) => e.key.color).toList();
    final segments = top.map((e) => MapEntry(e.key.label, grandTotal > 0 ? e.value / grandTotal : 0.0)).toList();
    final topCat = top.first;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Categories', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 32),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(
                size: const Size(120, 120),
                painter: _DonutPainter(segments: segments, colors: colors),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Total', style: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  fmt.format(grandTotal),
                  style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ]),
            ]),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: top.map((entry) {
                final pct = grandTotal > 0 ? (entry.value / grandTotal * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: entry.key.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.key.label,
                        style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                    Text('$pct%', style: const TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                );
              }).toList(),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildRecentScans(BuildContext ctx, List<Expense> expenses,
      String currencySymbol, NumberFormat fmt) {
    final recent = expenses.take(5).toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recent transactions', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w600)),
          if (expenses.isNotEmpty)
            GestureDetector(
              onTap: widget.onViewAllHistory,
              child: const Text('View all', style: TextStyle(color: _secondary, fontSize: 14, fontWeight: FontWeight.w500)),
            ),
        ]),
        const SizedBox(height: 24),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Column(children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  shape: BoxShape.circle,
                  border: Border.all(color: _border),
                ),
                child: const Icon(Icons.receipt_long_rounded, size: 32, color: _textMuted),
              ),
              const SizedBox(height: 16),
              const Text('No transactions yet', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              const Text('Scan a receipt to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textMuted, fontSize: 14)),
            ])),
          )
        else
          ...recent.map((exp) {
            final cat = _catFor(exp.category);
            final expSym = exp.currency.isNotEmpty ? exp.currency : currencySymbol;
            final expFmt = NumberFormat.currency(symbol: expSym);
            return GestureDetector(
              onTap: () => _showDetail(ctx, exp, currencySymbol),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141415),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(exp.merchantName,
                          style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(DateFormat('MMM d, yyyy').format(exp.date), style: const TextStyle(color: _textMuted, fontSize: 13)),
                    ]),
                  ),
                  Text(expFmt.format(exp.total),
                      style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 16)),
                ]),
              ),
            );
          }),
      ]),
    );
  }

  Widget _buildInsightsBanner(List<Expense> expenses, NumberFormat fmt, String currencySymbol) {
    final now = DateTime.now();
    final thisMonth = expenses.where(
        (e) => e.date.month == now.month && e.date.year == now.year).toList();

    String message;
    if (thisMonth.isEmpty) {
      message = 'Start scanning to unlock spending insights and tracking.';
    } else {
      final avg = thisMonth.fold(0.0, (s, e) => s + e.total) / thisMonth.length;
      message = 'You spend an average of ${fmt.format(avg)} per transaction this month.';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _primary.withValues(alpha: 0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lightbulb_outline_rounded, color: _primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Smart insights',
                style: TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 6),
            Text(message,
                style: const TextStyle(color: _textMuted, fontSize: 13, height: 1.4)),
          ]),
        ),
      ]),
    );
  }
}
