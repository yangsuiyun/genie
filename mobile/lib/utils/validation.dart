import 'dart:core';

/// Common validation utilities for the mobile app
class ValidationUtils {
  // Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Strong password regex components
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'\d');
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>/?~`]');

  /// Validates if email format is correct
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim());
  }

  /// Validates password strength
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (password.length > 128) {
      return 'Password must be at most 128 characters';
    }

    if (!_uppercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!_lowercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!_digitRegex.hasMatch(password)) {
      return 'Password must contain at least one digit';
    }

    if (!_specialCharRegex.hasMatch(password)) {
      return 'Password must contain at least one special character';
    }

    return null; // Password is valid
  }

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email is required';
    }

    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validates required string field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates string length
  static String? validateLength(String? value, String fieldName, {int? min, int? max}) {
    if (value == null) return null;

    if (min != null && value.length < min) {
      return '$fieldName must be at least $min characters';
    }

    if (max != null && value.length > max) {
      return '$fieldName must be at most $max characters';
    }

    return null;
  }

  /// Validates that two strings match (e.g., password confirmation)
  static String? validateMatch(String? value1, String? value2, String fieldName) {
    if (value1 != value2) {
      return '$fieldName do not match';
    }
    return null;
  }

  /// Validates positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      return '$fieldName must be a positive number';
    }

    return null;
  }

  /// Validates number range
  static String? validateNumberRange(String? value, String fieldName, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }

    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }

    return null;
  }

  /// Validates that a list is not empty
  static String? validateListNotEmpty<T>(List<T>? list, String fieldName) {
    if (list == null || list.isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }

  /// Validates URL format
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) return null;

    const pattern = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
    final regex = RegExp(pattern);

    if (!regex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Sanitizes string input by trimming and removing control characters
  static String sanitizeString(String input) {
    return input.trim().replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '');
  }

  /// Validates and sanitizes string input
  static String? validateAndSanitizeString(
    String? value,
    String fieldName, {
    bool required = true,
    int? minLength,
    int? maxLength,
  }) {
    if (value == null || value.isEmpty) {
      return required ? '$fieldName is required' : null;
    }

    final sanitized = sanitizeString(value);

    if (required && sanitized.isEmpty) {
      return '$fieldName is required';
    }

    return validateLength(sanitized, fieldName, min: minLength, max: maxLength);
  }
}

/// Validation result that can contain multiple errors
class ValidationResult {
  final Map<String, String> errors;

  ValidationResult() : errors = {};

  ValidationResult.fromErrors(this.errors);

  /// Returns true if validation passed (no errors)
  bool get isValid => errors.isEmpty;

  /// Returns true if validation failed (has errors)
  bool get hasErrors => errors.isNotEmpty;

  /// Adds an error for a specific field
  void addError(String field, String message) {
    errors[field] = message;
  }

  /// Gets error message for a specific field
  String? getError(String field) {
    return errors[field];
  }

  /// Gets all error messages as a list
  List<String> get allErrors => errors.values.toList();

  /// Gets all errors as a formatted string
  String get errorsAsString => errors.values.join('\n');
}

/// Form validation helper that accumulates validation errors
class FormValidator {
  final ValidationResult _result = ValidationResult();

  /// Validates a field and adds any errors to the result
  FormValidator validateField(String field, String? Function() validator) {
    final error = validator();
    if (error != null) {
      _result.addError(field, error);
    }
    return this;
  }

  /// Validates email field
  FormValidator validateEmailField(String field, String? value) {
    return validateField(field, () => ValidationUtils.validateEmail(value ?? ''));
  }

  /// Validates password field
  FormValidator validatePasswordField(String field, String? value) {
    return validateField(field, () => ValidationUtils.validatePassword(value ?? ''));
  }

  /// Validates required field
  FormValidator validateRequiredField(String field, String? value) {
    return validateField(field, () => ValidationUtils.validateRequired(value, field));
  }

  /// Validates password confirmation
  FormValidator validatePasswordConfirmation(String password, String confirmation) {
    return validateField('confirmPassword', () {
      if (confirmation.isEmpty) {
        return 'Password confirmation is required';
      }
      return ValidationUtils.validateMatch(password, confirmation, 'Passwords');
    });
  }

  /// Gets the validation result
  ValidationResult get result => _result;

  /// Returns true if all validations passed
  bool get isValid => _result.isValid;

  /// Returns true if any validations failed
  bool get hasErrors => _result.hasErrors;
}

/// Common form field validators
class FormFieldValidators {
  /// Email field validator
  static String? email(String? value) {
    return ValidationUtils.validateEmail(value ?? '');
  }

  /// Password field validator
  static String? password(String? value) {
    return ValidationUtils.validatePassword(value ?? '');
  }

  /// Required field validator
  static String? Function(String?) required(String fieldName) {
    return (String? value) => ValidationUtils.validateRequired(value, fieldName);
  }

  /// Name field validator (required, 2-50 characters)
  static String? name(String? value) {
    final required = ValidationUtils.validateRequired(value, 'Name');
    if (required != null) return required;

    return ValidationUtils.validateLength(value, 'Name', min: 2, max: 50);
  }

  /// Task title validator (required, 1-200 characters)
  static String? taskTitle(String? value) {
    final required = ValidationUtils.validateRequired(value, 'Task title');
    if (required != null) return required;

    return ValidationUtils.validateLength(value, 'Task title', min: 1, max: 200);
  }

  /// Task description validator (optional, max 1000 characters)
  static String? taskDescription(String? value) {
    if (value == null || value.isEmpty) return null;
    return ValidationUtils.validateLength(value, 'Description', max: 1000);
  }

  /// Pomodoro duration validator (1-480 minutes)
  static String? pomodoroDuration(String? value) {
    return ValidationUtils.validateNumberRange(value, 'Duration', min: 1, max: 480);
  }

  /// Break duration validator (1-60 minutes)
  static String? breakDuration(String? value) {
    return ValidationUtils.validateNumberRange(value, 'Break duration', min: 1, max: 60);
  }
}