import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showPasswordResetDialog(BuildContext context) {
  return showGenericDialog<void>(
    context: context,
    title: 'Password Reset',
    content: 
    'We have sent you a password reset link. Please check your email.',
    optionBuilder: () => {
      'OK': null,
    },
  );
}
