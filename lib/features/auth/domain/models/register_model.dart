class RegisterModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String confirmPassword;

  RegisterModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  }) {
    final normalizedFirstName = firstName.trim();
    final normalizedLastName = lastName.trim();

    if (normalizedFirstName.length < 2 || normalizedFirstName.length > 100) {
      throw ArgumentError('First name must be between 2 and 100 characters');
    }

    if (normalizedLastName.length < 2 || normalizedLastName.length > 100) {
      throw ArgumentError('Last name must be between 2 and 100 characters');
    }

    if (!_isValidEmail(email)) {
      throw ArgumentError('Invalid email');
    }

    if (password.length < 8 || password.length > 100) {
      throw ArgumentError('Password must be between 8 and 100 characters');
    }

    if (!_hasLowercase(password) ||
        !_hasUppercase(password) ||
        !_hasDigit(password) ||
        !_hasSpecialChar(password)) {
      throw ArgumentError(
        'Password must contain lowercase, uppercase, digit, and special character',
      );
    }

    if (password != confirmPassword) {
      throw ArgumentError('Passwords do not match');
    }
  }

  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      confirmPassword: json['confirmPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegisterModel &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.password == password &&
        other.confirmPassword == confirmPassword;
  }

  @override
  int get hashCode => Object.hash(
        firstName,
        lastName,
        email,
        password,
        confirmPassword,
      );

  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool _hasLowercase(String value) => RegExp(r'[a-z]').hasMatch(value);

  static bool _hasUppercase(String value) => RegExp(r'[A-Z]').hasMatch(value);

  static bool _hasDigit(String value) => RegExp(r'\d').hasMatch(value);

  static bool _hasSpecialChar(String value) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\]`~+=;]').hasMatch(value);
}
