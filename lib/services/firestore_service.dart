import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';

class FirestoreService {
  FirebaseFirestore? _db;
  final List<Expense> _localCache = [];

  FirestoreService() {
    try {
      _db = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not available: $e');
      _db = null;
    }
  }

  /// Returns the current Firebase user's uid, or null if not signed in.
  String? get _uid => fb.FirebaseAuth.instance.currentUser?.uid;

  Future<void> saveExpenseData(Expense expense) async {
    try {
      if (_db != null) {
        final uid = _uid;
        await _db!.collection('expenses').doc(expense.id).set({
          'userId': uid ?? '',
          'merchantName': expense.merchantName,
          'date': expense.date.toIso8601String(),
          'total': expense.total,
          'category': expense.category,
          'items': expense.items.map((i) => i.toJson()).toList(),
          'memo': expense.memo,
          'status': expense.status,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Fallback: store locally
        _localCache.insert(0, expense);
      }
    } catch (e) {
      debugPrint('Error saving expense: $e');
      // Fallback: store locally on error
      _localCache.insert(0, expense);
    }
  }

  Future<List<Expense>> getExpenses(String userId) async {
    try {
      if (_db != null) {
        final snapshot = await _db!
            .collection('expenses')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Expense.fromJson(data);
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
    }
    return List.from(_localCache);
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      if (_db != null) {
        final uid = _uid;
        await _db!.collection('expenses').doc(expense.id).update({
          ...expense.toJson(),
          'userId': uid ?? '',
        });
      } else {
        final index = _localCache.indexWhere((e) => e.id == expense.id);
        if (index != -1) _localCache[index] = expense;
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      if (_db != null) {
        await _db!.collection('expenses').doc(expenseId).delete();
      } else {
        _localCache.removeWhere((e) => e.id == expenseId);
      }
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }
}
