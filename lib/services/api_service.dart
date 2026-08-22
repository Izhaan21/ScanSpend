import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';
import 'token_service.dart';

class ApiService {
  // Production API URL (Render)
  static const String baseUrl = 'https://scanspend-backend.onrender.com/api/expenses';

  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────
  // Create Expense (Replaces saveExpense to Firestore)
  // ─────────────────────────────────────────────
  Future<void> saveExpense(Expense expense) async {
    final headers = await _getHeaders();
    
    // Map Flutter model to our .NET CreateExpenseDto
    final body = json.encode({
      'title': expense.merchantName.isNotEmpty ? expense.merchantName : 'New Expense',
      'category': expense.category,
      'date': expense.date.toIso8601String(),
      'merchantName': expense.merchantName,
      'total': expense.total,
      'subtotal': expense.subtotal,
      'tax': expense.tax,
      'discount': expense.discount,
      'currency': expense.currency,
      'paymentMethod': expense.paymentMethod,
      'address': expense.address,
      'phone': expense.phone,
      'receiptNumber': expense.receiptNumber,
      'memo': expense.memo,
      'status': expense.status,
      'items': expense.items.map((i) => {
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity
      }).toList(),
    });

    final response = await http.post(Uri.parse(baseUrl), headers: headers, body: body);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to save expense: ${response.body}');
    }
  }

  // ─────────────────────────────────────────────
  // Get All Expenses
  // ─────────────────────────────────────────────
  Future<List<Expense>> getExpenses() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) {
        // Our backend returns 'id' as an integer, but Flutter model expects a String
        final stringId = json['id'].toString();
        json['id'] = stringId; // override before passing to fromJson
        return Expense.fromJson(json);
      }).toList();
    } else {
      throw Exception('Failed to load expenses');
    }
  }

  // ─────────────────────────────────────────────
  // Update Expense
  // ─────────────────────────────────────────────
  Future<void> updateExpense(Expense expense) async {
    final headers = await _getHeaders();
    
    // Same payload as create
    final body = json.encode({
      'title': expense.merchantName.isNotEmpty ? expense.merchantName : 'Updated Expense',
      'category': expense.category,
      'date': expense.date.toIso8601String(),
      'merchantName': expense.merchantName,
      'total': expense.total,
      'subtotal': expense.subtotal,
      'tax': expense.tax,
      'discount': expense.discount,
      'currency': expense.currency,
      'paymentMethod': expense.paymentMethod,
      'address': expense.address,
      'phone': expense.phone,
      'receiptNumber': expense.receiptNumber,
      'memo': expense.memo,
      'status': expense.status,
      'items': expense.items.map((i) => {
        'name': i.name,
        'price': i.price,
        'quantity': i.quantity
      }).toList(),
    });

    final response = await http.put(Uri.parse('$baseUrl/${expense.id}'), headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to update expense');
    }
  }

  // ─────────────────────────────────────────────
  // Delete Expense
  // ─────────────────────────────────────────────
  Future<void> deleteExpense(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/$id'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete expense');
    }
  }

  // ─────────────────────────────────────────────
  // Get Summary (Optional - replacing manual calculations)
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getSummary() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/summary'), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load summary');
    }
  }
}
