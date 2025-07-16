// docimage.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

Widget buildDocumentImage(dynamic fileData, {double? width, double? height}) {
  final defaultSize = 100.0;
  final finalWidth = width ?? defaultSize;
  final finalHeight = height ?? defaultSize;

  if (fileData == null || (fileData is String && fileData.isEmpty)) {
    return _buildPlaceholder(Icons.description, finalWidth, finalHeight);
  }

  try {
    // Обработка base64 строки
    if (fileData is String) {
      if (fileData.startsWith('data:image')) {
        final base64Data = fileData.split(',').last;
        return _buildImageFromBase64(base64Data, finalWidth, finalHeight);
      }

      if (fileData.length > 100) {
        return _buildImageFromBase64(fileData, finalWidth, finalHeight);
      }
    }

    // Обработка бинарных данных
    if (fileData is List<int>) {
      return Image.memory(
        Uint8List.fromList(fileData),
        width: finalWidth,
        height: finalHeight,
        fit: BoxFit.contain,
      );
    }

    // Обработка Uint8List
    if (fileData is Uint8List) {
      return Image.memory(
        fileData,
        width: finalWidth,
        height: finalHeight,
        fit: BoxFit.contain,
      );
    }
  } catch (e) {
    print('Ошибка декодирования изображения: $e');
  }

  return _buildPlaceholder(Icons.broken_image, finalWidth, finalHeight);
}

Widget _buildImageFromBase64(String base64Str, double width, double height) {
  try {
    final bytes = base64Decode(base64Str);
    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  } catch (e) {
    return _buildPlaceholder(Icons.error_outline, width, height);
  }
}

Widget _buildPlaceholder(IconData icon, double width, double height) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey[200],
    child: Center(
      child: Icon(icon, size: width * 0.4, color: Colors.grey[400]),
    ),
  );
}
