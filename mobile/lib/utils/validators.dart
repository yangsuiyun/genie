// Validators for form validation
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱地址';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码至少需要6个字符';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return '请确认密码';
    }
    if (value != password) {
      return '密码不匹配';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '请输入$fieldName';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '请输入$fieldName';
    }
    if (value.length < minLength) {
      return '$fieldName至少需要$minLength个字符';
    }
    return null;
  }

  static String? maxLength(String? value, int maxLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '请输入$fieldName';
    }
    if (value.length > maxLength) {
      return '$fieldName不能超过$maxLength个字符';
    }
    return null;
  }
}
