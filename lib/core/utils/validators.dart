import 'package:corevia_mobile/l10n/app_localizations.dart';

class Validators {
  static final RegExp _emailRegex =
      RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _digitRegex = RegExp(r'\d');
  static final RegExp _specialCharRegex =
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]`~+=;]');

  static String? validateEmail(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.pleaseEnterEmail ?? 'Please enter your email address';
    }

    if (!_emailRegex.hasMatch(value.trim())) {
      return l10n?.pleaseEnterValidEmail ?? 'Please enter a valid email address';
    }

    return null;
  }

  static String? validateRequired(
    String? value, {
    String fieldName = 'This field',
    AppLocalizations? l10n,
  }) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.fieldRequired(fieldName) ?? '$fieldName is required';
    }
    return null;
  }

  static String? validateUsername(
    String? value, {
    String fieldName = 'Username',
    AppLocalizations? l10n,
  }) {
    if (value == null || value.trim().isEmpty) {
      return l10n?.fieldRequired(fieldName) ?? '$fieldName is required';
    }

    final normalized = value.trim();
    if (normalized.length < 2) {
      return l10n?.fieldMustContainAtLeast(fieldName, 2) ??
          '$fieldName must contain at least 2 characters';
    }

    if (normalized.length > 100) {
      return l10n?.fieldCannotExceed(fieldName, 100) ??
          '$fieldName cannot exceed 100 characters';
    }

    return null;
  }

  static String? validatePassword(
    String? value, {
    bool requireStrongRules = false,
    AppLocalizations? l10n,
  }) {
    if (value == null || value.isEmpty) {
      return l10n?.pleaseEnterPassword ?? 'Please enter a password';
    }

    if (value.length < 8) {
      return l10n?.passwordMustBeBetween8And100Characters ??
          'Password must be between 8 and 100 characters long';
    }

    if (value.length > 100) {
      return l10n?.passwordMustBeBetween8And100Characters ??
          'Password must be between 8 and 100 characters long';
    }

    if (requireStrongRules && !_lowercaseRegex.hasMatch(value)) {
      return l10n?.passwordMustContainLowercase ??
          'Password must contain at least one lowercase letter';
    }

    if (requireStrongRules && !_uppercaseRegex.hasMatch(value)) {
      return l10n?.passwordMustContainUppercase ??
          'Password must contain at least one uppercase letter';
    }

    if (requireStrongRules && !_digitRegex.hasMatch(value)) {
      return l10n?.passwordMustContainDigit ??
          'Password must contain at least one digit';
    }

    if (requireStrongRules && !_specialCharRegex.hasMatch(value)) {
      return l10n?.passwordMustContainSpecialCharacter ??
          'Password must contain at least one special character';
    }

    return null;
  }
}
