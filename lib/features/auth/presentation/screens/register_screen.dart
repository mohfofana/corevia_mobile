import 'package:corevia_mobile/core/providers/notifiers.dart';
import 'package:corevia_mobile/core/utils/validators.dart';
import 'package:corevia_mobile/features/auth/domain/models/register_model.dart';
import 'package:corevia_mobile/features/account/presentation/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import '../controllers/register_controller.dart';

import 'dart:math' as math;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  late final RegisterController _controller;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final PageController _pageController = PageController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentStep = 0;
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotationController = AnimationController(
      duration: Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller = RegisterController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    return Validators.validateEmail(value, l10n: context.l10n);
  }

  String? _validatePassword(String? value) {
    return Validators.validatePassword(
      value,
      requireStrongRules: true,
      l10n: context.l10n,
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return context.l10n.confirmationRequired;
    if (value != _passwordController.text) return context.l10n.passwordsDifferent;
    return null;
  }

  Future<void> _register() async {
    final firstNameError =
        Validators.validateUsername(
          _firstNameController.text,
          fieldName: context.l10n.firstName,
          l10n: context.l10n,
        );
    if (firstNameError != null) {
      _showValidationError(firstNameError);
      return;
    }

    final lastNameError =
        Validators.validateUsername(
          _lastNameController.text,
          fieldName: context.l10n.lastName,
          l10n: context.l10n,
        );
    if (lastNameError != null) {
      _showValidationError(lastNameError);
      return;
    }

    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      _showValidationError(emailError);
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final registerData = RegisterModel(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      final success = await _controller.register(registerData);

      if (mounted) {
        if (success) {
          final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
          authNotifier.value = true;
          final userProvider = context.read<UserProvider>();
          await userProvider.loadUser();
          if (!mounted) return;
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.registrationFailed),
            backgroundColor: Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
          ),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Register error: $e');
      debugPrintStack(stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pleaseTryAgain),
            backgroundColor: Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      final firstNameError =
          Validators.validateUsername(
            _firstNameController.text,
            fieldName: context.l10n.firstName,
            l10n: context.l10n,
          );
      if (firstNameError != null) {
        _showValidationError(firstNameError);
        return;
      }

      final lastNameError =
          Validators.validateUsername(
            _lastNameController.text,
            fieldName: context.l10n.lastName,
            l10n: context.l10n,
          );
      if (lastNameError != null) {
        _showValidationError(lastNameError);
        return;
      }
    }

    if (_currentStep == 1) {
      final emailError = _validateEmail(_emailController.text);
      if (emailError != null) {
        _showValidationError(emailError);
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF9500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F3),
              Color(0xFFFFFFFF),
              Color(0xFFF0FFF4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              Expanded(
                child: Stack(
                  children: [
                    _buildAnimatedBackground(),
                    PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        _buildPersonalInfoStep(),
                        _buildEmailStep(),
                        _buildPasswordStep(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
              color: Color(0xFF1D1D1F),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                context.l10n.createAccount,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D1D1F),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          bool isCompleted = index < _currentStep;
          bool isCurrent = index == _currentStep;
          
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isCompleted || isCurrent
                    ? Color(0xFF34C759)
                    : Colors.grey[200],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            return Positioned(
              top: 50,
              right: -80,
              child: Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFFF9500).withValues(alpha: 0.15),
                        Color(0xFFFF9500).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: 100,
              left: -50,
              child: Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF5856D6).withValues(alpha: 0.15),
                        Color(0xFF5856D6).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF34C759), Color(0xFF30D158)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF34C759).withValues(alpha: 0.4),
                        blurRadius: 25,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person_add_rounded, size: 50, color: Colors.white),
                ),
              );
            },
          ),
          SizedBox(height: 32),
          Text(
            context.l10n.personalInformation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1D1F),
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            context.l10n.howShouldWeCallYou,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 48),
          _buildStepTextField(
            controller: _firstNameController,
            label: context.l10n.firstName,
            icon: Icons.person_outline,
          ),
          SizedBox(height: 20),
          _buildStepTextField(
            controller: _lastNameController,
            label: context.l10n.lastName,
            icon: Icons.person_outline,
          ),
          SizedBox(height: 40),
          _buildNavigationButtons(showBack: false),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5856D6), Color(0xFF7B79FF)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5856D6).withValues(alpha: 0.4),
                        blurRadius: 25,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(Icons.email_rounded, size: 50, color: Colors.white),
                ),
              );
            },
          ),
          SizedBox(height: 32),
          Text(
            context.l10n.yourEmail,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1D1F),
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            context.l10n.weWillUseItToConnect,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 48),
          _buildStepTextField(
            controller: _emailController,
            label: context.l10n.email,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          SizedBox(height: 40),
          _buildNavigationButtons(showBack: true),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF9500), Color(0xFFFFB340)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF9500).withValues(alpha: 0.4),
                          blurRadius: 25,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(Icons.lock_rounded, size: 50, color: Colors.white),
                  ),
                );
              },
            ),
            SizedBox(height: 32),
            Text(
              context.l10n.secureYourAccount,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1D1F),
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              context.l10n.chooseStrongPassword,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 48),
            _buildStepTextField(
              controller: _passwordController,
              label: context.l10n.password,
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey[400],
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            SizedBox(height: 20),
            _buildStepTextField(
              controller: _confirmPasswordController,
              label: context.l10n.confirmPassword,
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirmPassword,
              validator: _validateConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.grey[400],
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            SizedBox(height: 40),
            _buildFinalButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1D1F),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Color(0xFF34C759), size: 24),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildNavigationButtons({required bool showBack}) {
    return Row(
      children: [
        if (showBack) ...[
          Expanded(
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  context.l10n.back,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
        ],
        Expanded(
          flex: showBack ? 1 : 2,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF34C759), Color(0xFF30D158)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF34C759).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                context.l10n.next,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF34C759), Color(0xFF30D158)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF34C759).withValues(alpha: 0.5),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.createMyAccount,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ],
              ),
      ),
    );
  }
}
