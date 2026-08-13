import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  // Explicit Latin recogniser — covers English, numbers, and most
  // printed receipt fonts. Using the explicit script enum avoids any
  // ambiguity with the default initialiser.
  final TextRecognizer _latinRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts text from a [File]. Returns the raw recognised string.
  Future<String> extractText(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final RecognizedText recognizedText =
          await _latinRecognizer.processImage(inputImage);

      // Sort text blocks top-to-bottom then left-to-right so the
      // resulting string mirrors the natural reading order of the receipt.
      final blocks = recognizedText.blocks.toList()
        ..sort((a, b) {
          final yDiff = a.boundingBox.top.compareTo(b.boundingBox.top);
          if (yDiff.abs() > 20) return yDiff; // significant vertical gap
          return a.boundingBox.left.compareTo(b.boundingBox.left);
        });

      final buffer = StringBuffer();
      for (final block in blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
      }

      final result = buffer.toString().trim();
      debugPrint('OCR extracted ${result.length} chars, '
          '${blocks.length} blocks');
      return result;
    } catch (e) {
      debugPrint('Error during text extraction: $e');
      return '';
    }
  }

  /// Convenience wrapper that accepts a file path string.
  Future<String> extractTextFromImage(String imagePath) async {
    return extractText(File(imagePath));
  }

  void dispose() {
    _latinRecognizer.close();
  }
}
