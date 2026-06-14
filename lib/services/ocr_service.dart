import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> extractText(File image) async {
    try {
      final inputImage = InputImage.fromFile(image);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error during text extraction: $e');
      return '';
    }
  }

  Future<String> extractTextFromImage(String imagePath) async {
    return extractText(File(imagePath));
  }

  void dispose() {
    _textRecognizer.close();
  }
}
