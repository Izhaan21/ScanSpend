import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import '../models/item_model.dart';
import 'scan_screen.dart';
import '../widgets/premium_background.dart';

class ReviewScreen extends StatefulWidget {
  final String? imagePath;

  const ReviewScreen({super.key, this.imagePath});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _memoController = TextEditingController();
  late TextEditingController _totalController;
  final FocusNode _totalFocusNode = FocusNode();
  String? _selectedCategory;

  // Minimalist Premium Dark Palette
  static const Color _bg         = Color(0xFF090E17);
  static const Color _cardBg     = Color(0xFF222329);
  static const Color _cardHeader = Color(0xFF1C1C1E);
  static const Color _primary    = Color(0xFF2563EB);
  static const Color _text       = Color(0xFFFFFFFF);
  static const Color _textSub    = Color(0xFFCBD5E1);
  static const Color _textMuted  = Color(0xFF94A3B8);
  static const Color _border     = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _totalController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expense = context.read<ExpenseProvider>().currentExpense;
      if (expense != null && mounted) {
        _totalController.text = expense.total.toStringAsFixed(2);
        _memoController.text = expense.memo;
        setState(() => _selectedCategory = expense.category);
      }
    });
  }

  @override
  void dispose() {
    _memoController.dispose();
    _totalController.dispose();
    _totalFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onSave(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    if (provider.currentExpense == null) return;

    if (_selectedCategory != null &&
        _selectedCategory != provider.currentExpense!.category) {
      provider.updateCategory(_selectedCategory!);
    }
    provider.updateCurrentExpense(
      provider.currentExpense!.copyWith(memo: _memoController.text),
    );
    try {
      await provider.saveExpense();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Receipt saved successfully',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving expense: $e', style: const TextStyle(fontWeight: FontWeight.w500)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ));
      }
    }
  }

  void _onRetake(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            final expense = provider.currentExpense;
            if (expense == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 64, color: _textMuted),
                    const SizedBox(height: 16),
                    const Text('No expense to review.', style: TextStyle(color: _textSub, fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: _text),
                      child: const Text('Go Back'),
                    )
                  ],
                ),
              );
            }

            _selectedCategory ??= expense.category;

            final providerTotalStr = expense.total.toStringAsFixed(2);
            if (!_totalFocusNode.hasFocus &&
                _totalController.text != providerTotalStr) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_totalFocusNode.hasFocus) {
                  _totalController.text = providerTotalStr;
                }
              });
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: _text, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Review',
                          style: TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewCard(expense),
                        const SizedBox(height: 24),

                        _buildMerchantInfoCard(expense, provider),
                        const SizedBox(height: 24),

                        _sectionLabel('Currency'),
                        const SizedBox(height: 12),
                        _buildCurrencyChips(expense, provider),
                        const SizedBox(height: 24),

                        _sectionLabel('Category'),
                        const SizedBox(height: 12),
                        _buildCategoryChips(provider),
                        const SizedBox(height: 24),

                        _buildLineItemsSection(expense, provider),
                        const SizedBox(height: 24),

                        if (expense.subtotal > 0 || expense.tax > 0 || expense.discount > 0)
                          _buildFinancialSummary(expense),
                        if (expense.subtotal > 0 || expense.tax > 0 || expense.discount > 0)
                          const SizedBox(height: 24),

                        _sectionLabel('Notes'),
                        const SizedBox(height: 12),
                        _buildMemoField(),
                      ],
                    ),
                  ),
                ),

                if (provider.isLoading)
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: const Center(child: CircularProgressIndicator(color: _primary)),
                  )
                else
                  _buildBottomActions(context),
              ],
            );
          },
        ),
      ),
    ));
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(color: _textMuted, fontSize: 14, fontWeight: FontWeight.w500),
  );

  Widget _buildPreviewCard(Expense expense) {
    final dateStr = expense.date.toString().substring(0, 10);
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: widget.imagePath != null && File(widget.imagePath!).existsSync()
                ? Image.file(
                    File(widget.imagePath!),
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.2),
                    colorBlendMode: BlendMode.darken,
                  )
                : Container(
                    color: _cardHeader,
                    child: const Center(
                      child: Icon(Icons.receipt_long_rounded, size: 48, color: _textMuted),
                    ),
                  ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _bg.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(23), bottomRight: Radius.circular(23),
                ),
                border: const Border(top: BorderSide(color: _border, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: _primary, size: 18),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Data extracted',
                            style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${expense.merchantName}  •  $dateStr',
                            style: const TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w400),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantInfoCard(Expense expense, ExpenseProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: _cardHeader,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, size: 20, color: _primary),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: expense.merchantName,
                    style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none, isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Merchant Name',
                      hintStyle: TextStyle(color: _textMuted),
                    ),
                    onChanged: provider.updateMerchantName,
                  ),
                ),
                const Icon(Icons.edit_outlined, size: 18, color: _textMuted),
              ],
            ),
          ),
          _infoRow(Icons.calendar_today_rounded, 'Date',
              '${expense.date.day}/${expense.date.month}/${expense.date.year}'),
          if (expense.address.isNotEmpty)
            _infoRow(Icons.location_on_rounded, 'Address', expense.address),
          if (expense.phone.isNotEmpty)
            _infoRow(Icons.phone_rounded, 'Phone', expense.phone),
          if (expense.receiptNumber.isNotEmpty)
            _infoRow(Icons.receipt_rounded, 'Receipt #', expense.receiptNumber),
          if (expense.paymentMethod.isNotEmpty)
            _infoRow(Icons.payment_rounded, 'Payment', expense.paymentMethod,
                isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textMuted),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChips(Expense expense, ExpenseProvider provider) {
    const currencies = ['\$', 'Rs', '£', '€', 'AED', 'SAR'];
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: currencies.map((curr) {
        final isSelected = expense.currency == curr;
        return GestureDetector(
          onTap: () => provider.updateCurrency(curr),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _primary : _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? _primary : _border),
            ),
            child: Text(
              curr,
              style: TextStyle(
                color: isSelected ? Colors.white : _textSub,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips(ExpenseProvider provider) {
    const categoryIcons = <String, IconData>{
      'Healthcare':   Icons.local_hospital_rounded,
      'Food & Dining': Icons.restaurant_rounded,
      'Groceries':    Icons.shopping_cart_rounded,
      'Transport':    Icons.directions_car_rounded,
      'Electronics':  Icons.devices_rounded,
      'Shopping':     Icons.shopping_bag_rounded,
      'Utilities':    Icons.bolt_rounded,
      'Other':        Icons.category_rounded,
    };
    final normalizedCat = _normaliseCategory(_selectedCategory ?? 'Other');
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: categoryIcons.entries.map((entry) {
        final isSelected = normalizedCat == entry.key;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedCategory = entry.key);
            provider.updateCategory(entry.key);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _primary.withValues(alpha: 0.15) : _cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? _primary : _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entry.value, size: 18, color: isSelected ? _primary : _textMuted),
                const SizedBox(width: 8),
                Text(entry.key,
                    style: TextStyle(
                      color: isSelected ? _text : _textSub,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineItemsSection(Expense expense, ExpenseProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: _cardHeader,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${expense.items.length}',
                      style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Expanded(flex: 4, child: Text('Item', style: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500))),
                const SizedBox(width: 50, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500))),
                SizedBox(width: 90, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...expense.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildEditableItem(item, index, provider),
                if (index < expense.items.length - 1)
                  const Divider(height: 1, color: _border, indent: 20, endIndent: 20),
              ],
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1424),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(23), bottomRight: Radius.circular(23)),
              border: Border(top: BorderSide(color: _border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _totalController,
                    focusNode: _totalFocusNode,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: _primary, fontSize: 20, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixText: '${expense.currency} ',
                      prefixStyle: const TextStyle(color: _textMuted, fontWeight: FontWeight.w500, fontSize: 18),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) provider.updateTotal(parsed);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItem(Item item, int index, ExpenseProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: TextFormField(
              initialValue: item.name,
              style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: 'Item name',
                hintStyle: TextStyle(color: _textMuted),
              ),
              onChanged: (value) => provider.updateItemAt(index, name: value),
            ),
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  'x${item.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: TextFormField(
              initialValue: item.price.toStringAsFixed(2),
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                border: InputBorder.none, isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null) provider.updateItemAt(index, price: parsed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(Expense expense) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: _cardHeader,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(23), topRight: Radius.circular(23)),
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: const Row(children: [
              Icon(Icons.summarize_rounded, size: 18, color: _primary),
              SizedBox(width: 12),
              Text('Summary', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (expense.subtotal > 0)
            _summaryRow('Subtotal', expense.subtotal, expense.currency),
          if (expense.tax > 0)
            _summaryRow('Tax', expense.tax, expense.currency),
          if (expense.discount > 0)
            _summaryRow('Discount', expense.discount, expense.currency, isDiscount: true),
          _summaryRow('Total', expense.total, expense.currency, isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, String currency,
      {bool isTotal = false, bool isDiscount = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: isTotal ? const Border(top: BorderSide(color: _border)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isTotal ? _text : _textMuted,
                  fontSize: isTotal ? 15 : 14,
                  fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500)),
          Text(
            isDiscount
                ? '- $currency ${amount.abs().toStringAsFixed(2)}'
                : '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
                color: isDiscount ? const Color(0xFF10B981) : (isTotal ? _primary : _text),
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoField() {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: _memoController,
        maxLines: 3,
        style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          hintText: 'Add notes...',
          hintStyle: TextStyle(color: _textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => _onRetake(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: _border, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Retake', style: TextStyle(color: _textSub, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _onSave(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _normaliseCategory(String activeCategory) {
    final lower = activeCategory.toLowerCase();
    if (lower.contains('health') || lower.contains('medical') || lower.contains('pharma') || lower.contains('lab')) return 'Healthcare';
    if (lower.contains('food') || lower.contains('dining') || lower.contains('restaurant') || lower.contains('cafe')) return 'Food & Dining';
    if (lower.contains('grocer') || lower.contains('supermark') || lower.contains('mart')) return 'Groceries';
    if (lower.contains('transport') || lower.contains('travel') || lower.contains('uber') || lower.contains('taxi')) return 'Transport';
    if (lower.contains('electr')) return 'Electronics';
    if (lower.contains('shop') || lower.contains('retail') || lower.contains('supplies')) return 'Shopping';
    if (lower.contains('util') || lower.contains('electric') || lower.contains('gas') || lower.contains('water') || lower.contains('internet')) return 'Utilities';
    const validCats = {'Healthcare', 'Food & Dining', 'Groceries', 'Transport', 'Electronics', 'Shopping', 'Utilities', 'Other'};
    return validCats.contains(activeCategory) ? activeCategory : 'Other';
  }
}
