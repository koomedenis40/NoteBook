import 'package:flutter/material.dart';

class ListFormattingUtils {
  static void handleListFormatting(
      String value, TextEditingController textController, TextSelection previousSelection) {
    final lines = value.split('\n');
    final cursorPosition = textController.selection.baseOffset;
   
    int currentLineStart = 0;
    int currentLineIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      if (cursorPosition >= currentLineStart && 
          cursorPosition <= currentLineStart + lines[i].length) {
        currentLineIndex = i;
        break;
      }
      currentLineStart += lines[i].length + 1;
    }

    final currentLine = lines[currentLineIndex];
    final isCursorAtEnd = cursorPosition == currentLineStart + currentLine.length;


    // Only format on Enter: new line added, current line is empty, cursor at end
    if (isCursorAtEnd && 
        currentLineIndex > 0 && 
        lines.length > currentLineIndex && 
        currentLine.trim().isEmpty && 
        value.endsWith('\n')) {
      final previousLine = lines[currentLineIndex - 1].trim();

      String newText = value;
      int newCursorOffset = cursorPosition;

      // Handle numbered list
      if (previousLine.startsWith(RegExp(r'^\d+\.\s'))) {
        final number = int.parse(previousLine.split('.')[0].trim()) + 1;
        final newLine = '$number. ';
        newText = value.replaceRange(cursorPosition, cursorPosition, newLine);
        newCursorOffset = cursorPosition + newLine.length;
      }
      // Handle bullet list
      else if (previousLine.startsWith('- ')) {
        const newLine = '- ';
        newText = value.replaceRange(cursorPosition, cursorPosition, newLine);
        newCursorOffset = cursorPosition + newLine.length;
      }

      if (newText != value) {
        textController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursorOffset),
        );
      }
    } else {
    }
  }
}