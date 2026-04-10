import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Custom Widgets ---
import '../../widgets/auth/auth_logo.dart';
import '../../widgets/auth/auth_form_fields.dart';
import '../../widgets/auth/auth_submit_button.dart';
import '../../widgets/auth/forgot_password_view.dart';

// --- Providers & Screens ---
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../screens/auth/otp_screen.dart';

// Typed arguments for better type safety
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

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _forgotEmailController = TextEditingController();

  // State
  bool _isLogin = true;
  String _selectedRole = 'PLAYER';
  bool _loginSubmitting = false;
  bool _forgotPasswordSubmitting = false;
  bool _rememberMe = false;
  bool _showForgotPassword = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller FIRST
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeInOut,
    );
    
    _loadRememberedEmail();

    // Auto-fill email if passed from OTP or Password Reset screen
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

  // --- Logic Methods ---

  void _toggleForgotPassword() {
    setState(() {
      _showForgotPassword = !_showForgotPassword;
      if (_showForgotPassword) {
        _animationController.forward();
        // Clear forgot email field when opening
        _forgotEmailController.clear();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _handleForgotPassword() async {
    // Dismiss keyboard
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
        // Navigate to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              email: email, 
              type: OtpScreenType.passwordReset,
            ),
          ),
        );
        // Close forgot password view after navigation
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
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    // Client-side Validation Check
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
          
          // Clear sensitive data
          _passwordController.clear();
          
          auth.navigateBasedOnRole(context);
        } else {
          // Redirect to OTP for Registration
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
      // Handle Unverified Email
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
      // Handle Backend Errors
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
      // Clear all form data on mode switch
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _rememberMe = false;
      // Reset validation state
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    const AuthLogo(),
                    const SizedBox(height: 20),
                    if (_showForgotPassword)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ForgotPasswordView(
                          controller: _forgotEmailController,
                          submitting: _forgotPasswordSubmitting,
                          onBack: _toggleForgotPassword,
                          onSubmit: _handleForgotPassword,
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
      ),
    );
  }

  Widget _buildMainAuthCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
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
            const SizedBox(height: 24),
            AuthSubmitButton(
              isLoading: _loginSubmitting || auth.isLoading,
              isLogin: _isLogin,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            _buildToggleAuthMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        children: [
          TextSpan(
            text: _isLogin ? "Don't have an account? " : "Already have an account? ",
          ),
          TextSpan(
            text: _isLogin ? 'Sign Up' : 'Login',
            style: const TextStyle(
              color: Colors.green, 
              fontWeight: FontWeight.bold, 
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