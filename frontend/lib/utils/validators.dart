class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _nameRegex = RegExp(
    r'^[а-яА-ЯёЁa-zA-Z\-]{2,50}$',
  );

  static final RegExp _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d]{8,}$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email обязателен';
    } else if (!_emailRegex.hasMatch(value)) {
      return 'Введите корректный email';
    }
    return null;
  }

  static String? validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName обязателен';
    } else if (!_nameRegex.hasMatch(value)) {
      return '$fieldName должен содержать только буквы (2-50 символов)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль обязателен';
    } else if (value.length < 8) {
      return 'Пароль должен быть не менее 8 символов';
    } else if (!_passwordRegex.hasMatch(value)) {
      return 'Пароль должен содержать заглавные, строчные буквы и цифры';
    }
    return null;
  }
}
