// ignore_for_file: avoid_print, unused_import
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const apiKey = 'AIzaSyAcB1RFZ0_qnWQM9CIuIoC__dvkfRuGYiI';

  final modelsToTry = [
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash-preview-04-17',
    'gemini-2.5-pro-preview-03-25',
    'gemini-pro',
    'gemini-1.0-pro',
  ];

  for (final modelName in modelsToTry) {
    print('Testing $modelName...');
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final response = await model.generateContent([
        Content.text('Reply with only: {"status":"ok","model":"$modelName"}')
      ]);
      print('✅ $modelName WORKS: ${response.text}');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('quota') || msg.contains('RESOURCE_EXHAUSTED')) {
        print('❌ $modelName — Quota exceeded');
      } else if (msg.contains('not found') || msg.contains('not supported')) {
        print('❌ $modelName — Model not found/supported');
      } else {
        print('❌ $modelName — Error: ${msg.substring(0, msg.length.clamp(0, 120))}');
      }
    }
    print('');
  }
}
