import 'package:flutter/material.dart';
import '../colors/colors.dart';
import '../utils/validators.dart';

class RegisterPage extends StatefulWidget {
  final Function(Map<String, String>) onRegister;

  const RegisterPage({super.key, required this.onRegister});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await widget.onRegister({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'firstName': _firstNameController.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kDarkBackgroundColor : kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : kSidebarActiveColor),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                'Регистрация',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kSidebarActiveColor,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: kSidebarActiveColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: kSidebarActiveColor,
                      width: 4.0,
                    ),
                  ),
                  labelText: 'Имя',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: kSidebarActiveColor, width: 1),
                  ),
                  filled: true,
                  fillColor: isDark ? kDarkBackgroundColor : Colors.white,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                validator: (value) => Validators.validateName(value, 'Имя'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: kSidebarActiveColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: kSidebarActiveColor,
                      width: 4.0,
                    ),
                  ),
                  labelText: 'Почта',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: kSidebarActiveColor, width: 1),
                  ),
                  filled: true,
                  fillColor: isDark ? kDarkBackgroundColor : Colors.white,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelStyle: TextStyle(
                    color: Colors.grey,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: kSidebarActiveColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: kSidebarActiveColor,
                      width: 4.0,
                    ),
                  ),
                  labelText: 'Пароль',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: kSidebarActiveColor, width: 1),
                  ),
                  filled: true,
                  fillColor: isDark ? kDarkBackgroundColor : Colors.white,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kSidebarActiveColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Зарегистрироваться',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
