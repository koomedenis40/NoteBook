import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class ListFormattingUtils {
  static void handleListFormatting(
      String value, TextEditingController textController, TextSelection previousSelection) {
    print('Value: "$value"');
    final lines = value.split('\n');
    final cursorPosition = textController.selection.baseOffset;
    print('Cursor: $cursorPosition');

    // Find the current line based on cursor position
    int currentLineStart = 0;
    int currentLineIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      if (cursorPosition >= currentLineStart && 
          cursorPosition <= currentLineStart + lines[i].length) {
        currentLineIndex = i;
        break;
      }
      currentLineStart += lines[i].length + 1; // +1 for the newline
    }

    final currentLine = lines[currentLineIndex];
    print('Current Line: "$currentLine"');
    final isCursorAtEnd = cursorPosition == currentLineStart + currentLine.length;
    print('Is Cursor at End: $isCursorAtEnd');

    // Only trigger when Enter is pressed at the end of a line (new line added)
    if (isCursorAtEnd && currentLineIndex > 0 && lines.length > currentLineIndex) {
      final previousLine = lines[currentLineIndex - 1].trim();
      final currentLineIsEmpty = currentLine.trim().isEmpty;

      // Only continue list if current line is empty (new line from Enter)
      if (!currentLineIsEmpty) return;

      String newText = value;
      int newCursorOffset = cursorPosition;

      // Handle numbered list
      if (previousLine.startsWith(RegExp(r'^\d+\.\s*'))) {
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

      // Apply the change if there’s a new list item
      if (newText != value) {
        print('New Text: "$newText"');
        textController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursorOffset),
        );
      }
    } else {
      print('No list formatting applied (e.g., deletion or mid-line edit)');
    }
  }
}