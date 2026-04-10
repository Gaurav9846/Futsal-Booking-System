import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme
import '../utils/app_theme.dart';

// Custom Widgets
import '../widgets/auth/auth_logo.dart';
import '../widgets/auth/auth_form_fields.dart';
import '../widgets/auth/auth_submit_button.dart';
import '../widgets/auth/forgot_password_view.dart';

// Providers & Screens
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'auth/otp_screen.dart';

class LoginScreenArguments {
  final String? email;
  
  LoginScreenArguments({this.email});
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  bool _isLogin = true;
  String _selectedRole = 'PLAYER';
  bool _loginSubmitting = false;
  bool _forgotPasswordSubmitting = false;
  bool _rememberMe = false;
  bool _showForgotPassword = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _loadRememberedEmail();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is LoginScreenArguments) {
        setState(() {
          if (args.email != null) {
            _emailController.text = args.email!;
          }
        });
      }
    });
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    final isRemembered = prefs.getBool('remember_me_status') ?? false;

    if (isRemembered && savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _forgotEmailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleForgotPassword() {
    setState(() {
      _showForgotPassword = !_showForgotPassword;
      if (_showForgotPassword) {
        _animationController.forward();
        _forgotEmailController.clear();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _handleForgotPassword() async {
    FocusScope.of(context).unfocus();
    
    if (_forgotEmailController.text.isEmpty) {
      _showErrorSnackBar("Please enter your email first");
      return;
    }
    
    setState(() => _forgotPasswordSubmitting = true);
    
    try {
      final email = _forgotEmailController.text.trim();
      final response = await ApiService.forgotPassword(email);
      
      if (!mounted) return;
      setState(() => _forgotPasswordSubmitting = false);
      
      if (response['status'] == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: email, 
              type: OtpScreenType.passwordReset,
            ),
          ),
        );
        _toggleForgotPassword();
      } else {
        _showErrorSnackBar(response['message'] ?? "Something went wrong");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _forgotPasswordSubmitting = false);
        _showErrorSnackBar("Connection error. Please try again.");
      }
    }
  }

  Future<void> _handleRememberMe(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', email);
      await prefs.setBool('remember_me_status', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.setBool('remember_me_status', false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loginSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = _isLogin
          ? await auth.login(
              _emailController.text.trim(), 
              _passwordController.text.trim(),
            )
          : await auth.register({
              'email': _emailController.text.trim(),
              'password': _passwordController.text.trim(),
              'fullName': _nameController.text.trim(),
              'role': _selectedRole,
            });

      if (!mounted) return;
      setState(() => _loginSubmitting = false);

      if (response['status'] == 'success') {
        if (_isLogin) {
          await _handleRememberMe(_emailController.text.trim());
          _passwordController.clear();
          auth.navigateBasedOnRole(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                email: _emailController.text.trim(),
                type: OtpScreenType.emailVerification,
              ),
            ),
          );
        }
      } 
      else if (response['requiresVerification'] == true) {
        _showErrorSnackBar("Email not verified. Redirecting...");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: _emailController.text.trim(),
              type: OtpScreenType.emailVerification,
            ),
          ),
        );
      } 
      else {
        _showErrorSnackBar(response['message'] ?? "Authentication failed");
      }
    } catch (e) {
      setState(() => _loginSubmitting = false);
      _showErrorSnackBar("Server connection failed. Please try again.");
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _rememberMe = false;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF1A1A1A),
              Color(0xFF0D0D0D),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            _buildBackgroundPattern(),
            
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const AuthLogo(),
                        const SizedBox(height: 32),
                        if (_showForgotPassword)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ForgotPasswordView(
                                controller: _forgotEmailController,
                                submitting: _forgotPasswordSubmitting,
                                onBack: _toggleForgotPassword,
                                onSubmit: _handleForgotPassword,
                              ),
                            ),
                          )
                        else
                          _buildMainAuthCard(auth),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _GridPatternPainter(),
      ),
    );
  }

  Widget _buildMainAuthCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header with tabs
            _buildAuthTabs(),
            const SizedBox(height: 28),
            
            AuthFormFields(
              isLogin: _isLogin,
              emailController: _emailController,
              passwordController: _passwordController,
              nameController: _nameController,
              selectedRole: _selectedRole,
              rememberMe: _rememberMe,
              onRememberMeChanged: () => setState(() => _rememberMe = !_rememberMe),
              onForgotPassword: _toggleForgotPassword,
              onRoleChanged: (role) => setState(() => _selectedRole = role),
            ),
            const SizedBox(height: 28),
            
            AuthSubmitButton(
              isLoading: _loginSubmitting || auth.isLoading,
              isLogin: _isLogin,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            
            _buildToggleAuthMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isLogin) _toggleAuthMode();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isLogin ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  boxShadow: _isLogin ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isLogin ? Colors.white : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isLogin) _toggleAuthMode();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_isLogin ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  boxShadow: !_isLogin ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isLogin ? Colors.white : AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        children: [
          TextSpan(
            text: _isLogin ? "Don't have an account? " : "Already have an account? ",
          ),
          TextSpan(
            text: _isLogin ? 'Sign Up' : 'Sign In',
            style: const TextStyle(
              color: AppTheme.primary, 
              fontWeight: FontWeight.w700, 
              fontSize: 15,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = _toggleAuthMode,
          ),
        ],
      ),
    );
  }
}

// Custom painter for background grid pattern
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    
    const spacing = 40.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
