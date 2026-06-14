import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import '../models/item_model.dart';
import 'scan_screen.dart';

class ReviewScreen extends StatefulWidget {
  final String? imagePath;

  const ReviewScreen({super.key, this.imagePath});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final TextEditingController _memoController = TextEditingController();

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    if (provider.currentExpense == null) return;

    provider.updateCurrentExpense(
      provider.currentExpense!.copyWith(memo: _memoController.text),
    );
    try {
      await provider.saveExpense();
      if (context.mounted) {
        // Pop back to the main navigation (past the scan screen)
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Color(0xFF89F5E7), size: 18),
            SizedBox(width: 10),
            Text('Receipt saved successfully!',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF131B2E),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _onRetake(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ScanSpend',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            final expense = provider.currentExpense;

            if (expense == null) {
              return const Center(child: Text('No expense found to review.'));
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Receipt Preview Card
                        _buildPreviewCard(theme, expense.merchantName, expense.date.toString().substring(0, 10), widget.imagePath),
                        const SizedBox(height: 24),

                        // 2. Category & Meta
                        Text(
                          'Expense Category',
                          style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF45464D)),
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryChips(theme, expense.category),
                        const SizedBox(height: 32),

                        // 3. Line Items Section
                        _buildLineItemsSection(theme, expense, provider),
                        const SizedBox(height: 24),

                        // 4. Notes / Memo
                        Text(
                          'Memo (Optional)',
                          style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF45464D)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC6C6CD)), // outline-variant
                          ),
                          child: TextField(
                            controller: _memoController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add details about this expense...',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF76777D)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Bottom Actions Layer
                if (provider.isLoading)
                   const Padding(
                     padding: EdgeInsets.all(24.0),
                     child: Center(child: CircularProgressIndicator()),
                   )
                else
                   _buildBottomActions(theme, context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme, String storeName, String dateStr, String? imagePath) {
    return Container(
      height: 192,
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC6C6CD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Actual receipt image (or placeholder) ──────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePath != null && File(imagePath).existsSync()
                ? Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.darken,
                  )
                : Container(
                    color: const Color(0xFFD0D5DD),
                    child: const Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: Color(0xFF98A2B3),
                    ),
                  ),
          ),
          // ── Overlay badge ───────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF006A61), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Data Extracted Successfully',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$storeName  •  $dateStr',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildCategoryChips(ThemeData theme, String activeCategory) {
    // ── Full category set matching AIService output ───────────────────────────
    const categoryIcons = {
      'Healthcare': Icons.local_hospital_outlined,
      'Food & Dining': Icons.restaurant_outlined,
      'Groceries': Icons.shopping_cart_outlined,
      'Transport': Icons.directions_car_outlined,
      'Electronics': Icons.devices_outlined,
      'Shopping': Icons.shopping_bag_outlined,
      'Utilities': Icons.bolt_outlined,
      'Other': Icons.category_outlined,
    };

    // Normalise the incoming category to match the chip keys
    String normalizedCat = 'Other';
    final lower = activeCategory.toLowerCase();
    if (lower.contains('health') || lower.contains('medical') || lower.contains('pharma') || lower.contains('lab')) {
      normalizedCat = 'Healthcare';
    } else if (lower.contains('food') || lower.contains('dining') || lower.contains('restaurant') || lower.contains('cafe')) {
      normalizedCat = 'Food & Dining';
    } else if (lower.contains('grocer') || lower.contains('supermark') || lower.contains('mart')) {
      normalizedCat = 'Groceries';
    } else if (lower.contains('transport') || lower.contains('travel') || lower.contains('uber') || lower.contains('taxi')) {
      normalizedCat = 'Transport';
    } else if (lower.contains('electr')) {
      normalizedCat = 'Electronics';
    } else if (lower.contains('shop') || lower.contains('retail') || lower.contains('supplies')) {
      normalizedCat = 'Shopping';
    } else if (lower.contains('util') || lower.contains('electric') || lower.contains('gas') || lower.contains('water') || lower.contains('internet')) {
      normalizedCat = 'Utilities';
    } else if (categoryIcons.containsKey(activeCategory)) {
      // Exact match from AI (already in the correct format)
      normalizedCat = activeCategory;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categoryIcons.entries.map((entry) {
        return _buildChip(theme, entry.value, entry.key, normalizedCat == entry.key);
      }).toList(),
    );
  }

  Widget _buildChip(ThemeData theme, IconData icon, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF86F2E4) : Colors.white, // secondary-container or white
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? const Color(0xFF006A61).withValues(alpha: 0.1) : const Color(0xFFC6C6CD),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? const Color(0xFF006F66) : const Color(0xFF45464D)),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? const Color(0xFF006F66) : const Color(0xFF45464D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItemsSection(ThemeData theme, Expense expense, ExpenseProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC6C6CD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4F6), // surface-container-low
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFC6C6CD))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LINE ITEMS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF45464D),
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${expense.items.length} items found',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF006A61), // secondary
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Items
          ...expense.items.asMap().entries.map((entry) {
             final int index = entry.key;
             final Item item = entry.value;
             return Column(
               children: [
                 _buildEditableItem(
                   theme,
                   item.name,
                   item.price.toStringAsFixed(2),
                   false,
                   onNameChanged: (value) {
                     provider.updateItemAt(index, name: value);
                   },
                   onPriceChanged: (value) {
                     final parsed = double.tryParse(value);
                     if (parsed != null) {
                       provider.updateItemAt(index, price: parsed);
                     }
                   },
                 ),
                 if (index < expense.items.length - 1)
                   const Divider(height: 1, thickness: 1, color: Color(0xFFC6C6CD)),
               ],
             );
          }),
          // Total
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF131B2E), // primary-container
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 20,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        initialValue: expense.total.toStringAsFixed(2),
                        textAlign: TextAlign.right,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '\$',
                          prefixStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null) {
                            provider.updateTotal(parsed);
                          }
                        },
                      ),
                    ),
                    Text(
                      'Tax included',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF7C839B), // on-primary-container
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItem(
    ThemeData theme,
    String name,
    String price,
    bool isItalic, {
    ValueChanged<String>? onNameChanged,
    ValueChanged<String>? onPriceChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   'Item Name',
                   style: theme.textTheme.labelMedium?.copyWith(
                     fontSize: 12,
                     color: const Color(0xFF7C839B), // on-primary-container
                   ),
                 ),
                 TextFormField(
                   initialValue: name,
                   style: theme.textTheme.bodyMedium?.copyWith(
                     fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                   ),
                   decoration: const InputDecoration(
                     border: InputBorder.none,
                     isDense: true,
                     contentPadding: EdgeInsets.only(top: 4, bottom: 0),
                   ),
                   onChanged: onNameChanged,
                 ),
               ],
             ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 Text(
                   'Price',
                   style: theme.textTheme.labelMedium?.copyWith(
                     fontSize: 12,
                     color: const Color(0xFF7C839B), // on-primary-container
                   ),
                 ),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     const Text('\$', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                     Expanded(
                       child: TextFormField(
                         initialValue: price,
                         textAlign: TextAlign.right,
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                         style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500),
                         decoration: const InputDecoration(
                           border: InputBorder.none,
                           isDense: true,
                           contentPadding: EdgeInsets.only(top: 4, bottom: 0),
                         ),
                         onChanged: onPriceChanged,
                       ),
                     ),
                   ],
                 ),
               ],
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: Color(0xFFE0E3E5))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => _onRetake(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFF76777D)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Retake',
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _onSave(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Save Expense',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

