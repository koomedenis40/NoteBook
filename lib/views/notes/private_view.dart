import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Add this import
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart'; // Add this import
import 'package:mynotes/services/auth/bloc/auth_event.dart'; // Add this import
import 'package:mynotes/services/cloud/cloud_note.dart';
import 'package:mynotes/services/cloud/firebase_cloud_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PrivateNotesManager {
  final FirebaseCloudStorage _notesService = FirebaseCloudStorage();
  final _storage = const FlutterSecureStorage();

  String get _passwordKey => 'private_notes_password_${AuthService.firebase().currentUser!.id}';
  String get _recoveryEmailKey => 'private_notes_recovery_email_${AuthService.firebase().currentUser!.id}';

  Future<bool> hasPassword() async {
    try {
      debugPrint('Checking if password exists for user: ${AuthService.firebase().currentUser!.id}');
      final password = await _storage.read(key: _passwordKey);
      final exists = password != null;
      debugPrint('Password exists: $exists');
      return exists;
    } catch (e) {
      debugPrint('Error checking password existence: $e');
      return false;
    }
  }

  Future<bool> setPassword(String password, String confirmPassword, String recoveryEmail) async {
    debugPrint('setPassword called with password: [hidden], confirm: [hidden], email: $recoveryEmail');
    if (password != confirmPassword) {
      debugPrint('Passwords do not match');
      return false;
    }
    if (password.isEmpty) {
      debugPrint('Password is empty');
      return false;
    }
    try {
      debugPrint('Writing password to secure storage for user: ${AuthService.firebase().currentUser!.id}');
      await _storage.write(key: _passwordKey, value: password);
      debugPrint('Writing recovery email to secure storage...');
      await _storage.write(key: _recoveryEmailKey, value: recoveryEmail);
      debugPrint('Password and email set successfully');
      return true;
    } catch (e) {
      debugPrint('Error setting password: $e');
      return false;
    }
  }

  Future<bool> verifyPassword(String inputPassword) async {
    try {
      debugPrint('verifyPassword called with input: [hidden]');
      final storedPassword = await _storage.read(key: _passwordKey);
      debugPrint('Stored password retrieved: ${storedPassword != null ? "[exists]" : "null"}');
      final isValid = storedPassword == inputPassword;
      debugPrint('Password match: $isValid');
      return isValid;
    } catch (e) {
      debugPrint('Error verifying password: $e');
      return false;
    }
  }

  Future<String> recoverPassword(BuildContext context) async { // Add context parameter
    try {
      debugPrint('recoverPassword called');
      final email = await _storage.read(key: _recoveryEmailKey) ?? AuthService.firebase().currentUser!.email;
      await AuthService.firebase().sendPasswordReset(toEmail: email);
      await _clearPassword();
      if (context.mounted) {
        context.read<AuthBloc>().add(const AuthEventLogOut()); // Trigger logout via bloc
      }
      debugPrint('Password reset email sent to: $email and logout event dispatched');
      return 'A password reset link has been sent to $email. Please reset your password and log back in.';
    } catch (e) {
      debugPrint('Error sending reset email: $e');
      return 'Failed to send reset email: $e';
    }
  }

  Future<void> _clearPassword() async {
    try {
      debugPrint('Clearing password for user: ${AuthService.firebase().currentUser!.id}');
      await _storage.delete(key: _passwordKey);
      await _storage.delete(key: _recoveryEmailKey);
      debugPrint('Password and recovery email cleared');
    } catch (e) {
      debugPrint('Error clearing password: $e');
    }
  }

  Future<bool> togglePrivacy({
    required CloudNote note,
    required VoidCallback onSuccess,
    required Future<bool> Function(String, String, String) onSetPassword,
    required Future<bool> Function(String) onVerifyPassword,
    required Future<String> Function(BuildContext) onRecoverPassword, // Update signature
  }) async {
    debugPrint('togglePrivacy called for note: ${note.documentId}, isPrivate: ${note.isPrivate}');
    final hasPass = await hasPassword();
    debugPrint('Has password: $hasPass');

    if (!hasPass && !note.isPrivate) {
      debugPrint('First-time lock: prompting for password');
      final success = await onSetPassword(note.documentId, note.text, note.isPrivate.toString());
      debugPrint('onSetPassword returned: $success');
      if (success) {
        try {
          debugPrint('Updating note to private in Firebase...');
          await _notesService.updateNote(
            documentId: note.documentId,
            text: note.text,
            isPrivate: true,
          );
          debugPrint('Note successfully updated to private');
          onSuccess();
          return true;
        } catch (e) {
          debugPrint('Error updating note to private: $e');
          return false;
        }
      } else {
        debugPrint('Password setting failed, aborting');
        return false;
      }
    } else {
      debugPrint('Verifying password to toggle privacy');
      final isValid = await onVerifyPassword(note.isPrivate ? 'Unlock Note' : 'Lock Note');
      debugPrint('onVerifyPassword returned: $isValid');
      if (isValid) {
        try {
          debugPrint('Toggling note privacy in Firebase...');
          await _notesService.updateNote(
            documentId: note.documentId,
            text: note.text,
            isPrivate: !note.isPrivate,
          );
          debugPrint('Note privacy toggled successfully');
          onSuccess();
          return true;
        } catch (e) {
          debugPrint('Error toggling note privacy: $e');
          return false;
        }
      } else {
        debugPrint('Password verification failed, aborting');
        return false;
      }
    }
  }
}