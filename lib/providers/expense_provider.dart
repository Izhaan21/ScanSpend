import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../models/item_model.dart';
import '../services/ocr_service.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final OCRService _ocrService;
  final AIService _aiService;
  final FirestoreService _firestoreService;

  List<Expense> _expenses = [];
  Expense? _currentExpense;
  bool _isLoading = false;
  String _loadingMessage = '';

  ExpenseProvider(this._ocrService, this._aiService, this._firestoreService);

  List<Expense> get expenses => _expenses;
  Expense? get currentExpense => _currentExpense;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  void _setLoading(bool value, {String message = ''}) {
    _isLoading = value;
    _loadingMessage = message;
    notifyListeners();
  }

  Future<void> fetchExpenses(String userId) async {
    try {
      _setLoading(true, message: 'Loading history...');
      _expenses = await _firestoreService.getExpenses(userId);
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> processReceipt(String imagePath) async {
    try {
      _setLoading(true, message: 'Extracting text...');
      
      // Step 1: OCR
      final rawText = await _ocrService.extractTextFromImage(imagePath);
      
      // Step 2: AI Parsing
      _setLoading(true, message: 'Parsing data with AI...');
      final parsedJson = await _aiService.parseReceiptText(rawText);
      
      // Assign ID
      parsedJson['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Update Current Expense
      _currentExpense = Expense.fromJson(parsedJson);
      
    } catch (e) {
      debugPrint('Error processing receipt: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void updateCurrentExpense(Expense updatedExpense) {
    _currentExpense = updatedExpense;
    notifyListeners();
  }

  /// Accepts a parsed JSON map (from AIService) and stores it as the current expense.
  void setCurrentExpenseFromJson(Map<String, dynamic> parsedJson) {
    parsedJson['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    _currentExpense = Expense.fromJson(parsedJson);
    notifyListeners();
  }

  void clearCurrentExpense() {
    _currentExpense = null;
    notifyListeners();
  }

  void updateItemAt(int index, {String? name, double? price}) {
    if (_currentExpense == null || index >= _currentExpense!.items.length) return;
    final updatedItems = List<Item>.from(_currentExpense!.items);
    updatedItems[index] = updatedItems[index].copyWith(name: name, price: price);
    _currentExpense = _currentExpense!.copyWith(items: updatedItems);
    notifyListeners();
  }

  void updateTotal(double total) {
    if (_currentExpense == null) return;
    _currentExpense = _currentExpense!.copyWith(total: total);
    notifyListeners();
  }

  void updateMerchantName(String name) {
    if (_currentExpense == null) return;
    _currentExpense = _currentExpense!.copyWith(merchantName: name);
    notifyListeners();
  }

  Future<void> saveExpense() async {
    if (_currentExpense == null) return;
    
    try {
      _setLoading(true, message: 'Saving expense...');
      
      await _firestoreService.saveExpenseData(_currentExpense!);
      
      // Prepend to local list
      _expenses.insert(0, _currentExpense!);
      
      // Clear current expense
      _currentExpense = null;
      
    } catch (e) {
      debugPrint('Error saving expense: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestoreService.deleteExpense(expenseId);
    } catch (_) {
      // best-effort remote delete
    }
    _expenses.removeWhere((e) => e.id == expenseId);
    notifyListeners();
  }

  /// Re-inserts a previously deleted expense at the top of the list (undo support).
  void insertExpense(Expense expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  /// Clears all local expense data (called on logout).
  void clearAllExpenses() {
    _expenses = [];
    _currentExpense = null;
    notifyListeners();
  }
}
