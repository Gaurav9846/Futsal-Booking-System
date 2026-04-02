import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/otp_screen.dart';
import '../../services/api_service.dart';

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
  bool _submitting = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  // For forgot password
  bool _showForgotPassword = false;
  bool _resetEmailSent = false;

  // Animation controller for forgot password
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Check for saved email (remember me)
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    // You can implement shared_preferences to load saved email
    // For now, we'll leave it empty
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      // Save email to shared_preferences
      // You can implement this later
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_submitting) return;

    setState(() => _submitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    Map<String, dynamic> response;

    if (_isLogin) {
      response = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Save credentials if remember me is checked
      if (response['status'] == 'success') {
        await _saveCredentials();
      }
    } else {
      response = await auth.register({
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'fullName': _nameController.text.trim(),
        'role': _selectedRole,
      });
    }

    setState(() => _submitting = false);
    if (!mounted) return;

    String message = response['message'] ?? 'Operation completed';
    bool isSuccess = response['status'] == 'success';

    // Show message
    _showSnackBar(message, isSuccess);

    if (isSuccess) {
      if (_isLogin) {
        debugPrint('✅ Login successful, navigating based on role');
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;
        auth.navigateBasedOnRole(context);
      } else {
        // Registration success - go to OTP verification
        if (response['requiresVerification'] == true) {
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
    }
  }

Future<void> _handleForgotPassword() async {
  if (_forgotEmailController.text.isEmpty) {
    _showSnackBar('Please enter your email', false);
    return;
  }

  setState(() => _submitting = true);

  try {
    // ✅ Save email before clearing
    final email = _forgotEmailController.text.trim();
    
    final response = await ApiService.forgotPassword(email);

    setState(() => _submitting = false);

    if (!mounted) return;

    _toggleForgotPassword(); // clears controller — but email is already saved
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          email: email, // ✅ uses saved variable
          type: OtpScreenType.passwordReset,
        ),
      ),
    );
  } catch (e) {
    setState(() => _submitting = false);
    _showSnackBar('Error: $e', false);
  }
}

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleForgotPassword() {
    setState(() {
      _showForgotPassword = !_showForgotPassword;
      if (_showForgotPassword) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _resetEmailSent = false;
        _forgotEmailController.clear();
      }
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
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and App Name
                  _buildLogo(),

                  const SizedBox(height: 20),

                  // Forgot Password View
                  if (_showForgotPassword)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildForgotPasswordView(),
                    )
                  else
                    // Main Login/Register Form
                    _buildAuthForm(auth),

                  // Terms and Privacy
                  const SizedBox(height: 30),
                  _buildTermsAndPrivacy(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer,
            size: 60,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Futsal Booking',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Welcome Back!' : 'Create New Account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            /// NAME FIELD (REGISTER ONLY)
            if (!_isLogin) _buildNameField(),
            if (!_isLogin) const SizedBox(height: 16),

            /// EMAIL FIELD
            _buildEmailField(),

            const SizedBox(height: 16),

            /// PASSWORD FIELD
            _buildPasswordField(),

            /// REMEMBER ME & FORGOT PASSWORD (LOGIN ONLY)
            if (_isLogin) _buildLoginOptions(),

            /// ROLE SELECTOR (REGISTER ONLY)
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              _buildRoleSelector(),
            ],

            const SizedBox(height: 24),

            /// SUBMIT BUTTON
            _buildSubmitButton(auth),

            const SizedBox(height: 16),

            /// TOGGLE BETWEEN LOGIN AND REGISTER
            _buildToggleAuthMode(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        prefixIcon: const Icon(Icons.person_outline, color: Colors.green),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.green),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter email';
        if (!v.contains('@') || !v.contains('.')) return 'Enter valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: _isLogin ? 'Enter your password' : 'Minimum 6 characters',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter password';
        if (!_isLogin && v.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildLoginOptions() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            // Remember Me
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Text(
                  'Remember me',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            // Forgot Password
            TextButton(
              onPressed: _toggleForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
              ),
              child: const Text('Forgot Password?'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Register as',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        prefixIcon: const Icon(Icons.person_outline, color: Colors.green),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: const [
        DropdownMenuItem(value: 'PLAYER', child: Text('Player')),
        DropdownMenuItem(value: 'OWNER', child: Text('Futsal Owner')),
      ],
      onChanged: (v) => setState(() => _selectedRole = v!),
    );
  }

  Widget _buildSubmitButton(AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: auth.isLoading || _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: auth.isLoading || _submitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isLogin ? 'Login' : 'Create Account',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isLogin = !_isLogin;
              // Clear fields when switching
              _emailController.clear();
              _passwordController.clear();
              _nameController.clear();
            });
          },
          child: Text(
            _isLogin ? 'Sign Up' : 'Login',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.green),
                onPressed: _toggleForgotPassword,
              ),
              const Expanded(
                child: Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40), // Balance the row
            ],
          ),

          const SizedBox(height: 24),

          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.email_outlined,
              size: 40,
              color: Colors.green.shade700,
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Text(
            _resetEmailSent
                ? 'Check your email!'
                : 'Enter your email to receive password reset link',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Email Field
          if (!_resetEmailSent) ...[
            TextFormField(
              controller: _forgotEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Colors.green),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 16),

            // Send Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _handleForgotPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ] else ...[
            // Success Message
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Reset link sent to\n${_forgotEmailController.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _toggleForgotPassword,
              child: const Text('Back to Login'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      children: [
        Text(
          'By continuing, you agree to our',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                // Show Terms of Service
                _showTermsDialog();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Terms of Service',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              ' and ',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            TextButton(
              onPressed: () {
                // Show Privacy Policy
                _showPrivacyDialog();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a demo app. By using this app, you agree to:\n\n'
            '1. You will not misuse the app\n'
            '2. You will provide accurate information\n'
            '3. You are responsible for your bookings\n'
            '4. We may update these terms at any time\n\n'
            'For full terms, please contact support.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We value your privacy. Here\'s what you should know:\n\n'
            '1. We collect basic information for account creation\n'
            '2. Your data is stored securely\n'
            '3. We don\'t share your data with third parties\n'
            '4. You can request data deletion anytime\n\n'
            'For full privacy policy, please contact support.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
