import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';
import '../models/item_model.dart';
import '../services/ocr_service.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final OCRService _ocrService;
  final AIService _aiService;
  final ApiService _apiService;

  List<Expense> _expenses = [];
  Expense? _currentExpense;
  bool _isLoading = false;
  String _loadingMessage = '';
  
  static const String _localStorageKey = 'scanspend_persistent_expenses_vault';

  ExpenseProvider(this._ocrService, this._aiService, this._apiService);

  List<Expense> get expenses => _expenses;
  Expense? get currentExpense => _currentExpense;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  void _setLoading(bool value, {String message = ''}) {
    _isLoading = value;
    _loadingMessage = message;
    notifyListeners();
  }

  // ── Local Disk Persistence (SharedPreferences Vault) ───────────────────────
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_expenses.map((e) => e.toJson()).toList());
      await prefs.setString(_localStorageKey, encoded);
    } catch (e) {
      debugPrint('Error saving expenses to persistent disk storage: $e');
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_localStorageKey);
      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data) as List<dynamic>;
        _expenses = decoded.map((item) => Expense.fromJson(item as Map<String, dynamic>)).toList();
        _expenses.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading expenses from local storage: $e');
    }
  }

  // ── Fetch & Cloud Sync ─────────────────────────────────────────────────────
  Future<void> fetchExpenses(String userId) async {
    try {
      // Step 1: Instantly restore from local disk storage so expenses never vanish after closing app
      await _loadFromDisk();

      _setLoading(true, message: 'Syncing financial vault...');
      // Fetch from our .NET Backend instead of Firestore
      final cloudExpenses = await _apiService.getExpenses();

      if (cloudExpenses.isNotEmpty) {
        // Replace completely with what backend says is true to avoid sync issues
        _expenses = cloudExpenses;
        _expenses.sort((a, b) => b.date.compareTo(a.date));
        await _saveToDisk();
      }
    } catch (e) {
      debugPrint('Error syncing expenses from cloud: $e');
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
      
      // Assign dummy ID (Backend will overwrite this with integer ID)
      parsedJson['id'] = '0';
      
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
    parsedJson['id'] = '0';
    _currentExpense = Expense.fromJson(parsedJson);
    notifyListeners();
  }

  void clearCurrentExpense() {
    _currentExpense = null;
    notifyListeners();
  }

  void updateItemAt(int index, {String? name, double? price, int? quantity}) {
    if (_currentExpense == null || index >= _currentExpense!.items.length) return;
    final updatedItems = List<Item>.from(_currentExpense!.items);
    updatedItems[index] = updatedItems[index].copyWith(name: name, price: price, quantity: quantity);
    _currentExpense = _currentExpense!.copyWith(items: updatedItems);
    notifyListeners();
  }

  void updateTotal(double total) {
    if (_currentExpense == null) return;
    _currentExpense = _currentExpense!.copyWith(total: total);
    notifyListeners();
  }

  void updateCategory(String category) {
    if (_currentExpense == null) return;
    _currentExpense = _currentExpense!.copyWith(category: category);
    notifyListeners();
  }

  void updateCurrency(String currency) {
    if (_currentExpense == null) return;
    _currentExpense = _currentExpense!.copyWith(currency: currency);
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
      _setLoading(true, message: 'Saving expense to vault...');
      
      // Save to .NET Backend
      if (_currentExpense!.id != '0' && _currentExpense!.id.isNotEmpty) {
        await _apiService.updateExpense(_currentExpense!);
      } else {
        await _apiService.saveExpense(_currentExpense!);
      }
      
      // Re-fetch everything to get the correct backend IDs
      // (because the backend generates the actual integer ID for it)
      final cloudExpenses = await _apiService.getExpenses();
      _expenses = cloudExpenses;
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      
      // Save directly to local persistent storage
      await _saveToDisk();
      
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
      await _apiService.deleteExpense(expenseId);
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
    _expenses.removeWhere((e) => e.id == expenseId);
    notifyListeners();
    await _saveToDisk();
  }

  /// Re-inserts a previously deleted expense at the top of the list (undo support).
  /// Note: To fully support undo with a real backend, you would need to call saveExpense again.
  void insertExpense(Expense expense) {
    _expenses.removeWhere((e) => e.id == expense.id);
    _expenses.insert(0, expense);
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
    _saveToDisk();
    // Also save it back to the backend
    _apiService.saveExpense(expense);
  }

  /// Clears all local expense data (called on logout).
  void clearAllExpenses() {
    _expenses = [];
    _currentExpense = null;
    notifyListeners();
    _saveToDisk();
  }
}

