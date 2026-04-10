import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

enum OtpScreenType { emailVerification, passwordReset }

// Typed arguments for better type safety
class LoginScreenArguments {
  final String? email;
  LoginScreenArguments({this.email});
}

class OtpScreen extends StatefulWidget {
  final String email;
  final OtpScreenType type;

  const OtpScreen({
    super.key,
    required this.email,
    required this.type,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isVerifying = false;
  bool _isResending = false;
  bool _otpEntered = false;
  
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _addOtpListeners();
  }

  void _addOtpListeners() {
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() {
        // Auto-clear error when user starts typing
        if (_passwordError != null || _confirmPasswordError != null) {
          setState(() {
            _passwordError = null;
            _confirmPasswordError = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _isPasswordReset => widget.type == OtpScreenType.passwordReset;

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, false);
  }

  void _showSuccessSnackBar(String message) {
    _showSnackBar(message, true);
  }

  // --- Password Validation ---
  
  String? _validatePassword(String value) {
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  String? _validateConfirmPassword(String value) {
    if (value != _newPasswordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }
  
  bool _validatePasswordFields() {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    
    setState(() {
      _passwordError = _validatePassword(newPass);
      _confirmPasswordError = _validateConfirmPassword(confirmPass);
    });
    
    return _passwordError == null && _confirmPasswordError == null;
  }

  // --- Core Logic Methods ---

  Future<void> _verifyEmail() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    final otp = _otp;
    
    if (otp.length != 6) {
      _showErrorSnackBar('Please enter all 6 digits');
      return;
    }
    
    setState(() => _isVerifying = true);
    
    try {
      final response = await ApiService.verifyEmail(widget.email, otp);
      
      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (response['status'] == 'success') {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        
        // Auto-Login Logic: Save token and user data immediately
        if (response['token'] != null && response['user'] != null) {
          await auth.saveAuthData(response['token'], response['user']);
          _showSuccessSnackBar('Email verified! Logging you in...');
          
          // Small delay to show snackbar before navigation
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              auth.navigateBasedOnRole(context);
            }
          });
        } else {
          // Fallback: If no token, go to login with typed arguments
          _showSuccessSnackBar('Email verified! Please login.');
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/login', 
            (_) => false, 
            arguments: LoginScreenArguments(email: widget.email),
          );
        }
      } else {
        _showErrorSnackBar(response['message'] ?? 'Invalid OTP. Please try again.');
        _clearOtpFields();
      }
    } catch (e) {
      debugPrint('OTP Verification Error: $e');
      if (mounted) {
        setState(() => _isVerifying = false);
        _showErrorSnackBar('Connection error. Please check your internet and try again.');
        _clearOtpFields();
      }
    }
  }

  void _clearOtpFields() {
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // For password reset - just show password fields, OTP will be verified when resetting
  Future<void> _verifyResetOtp() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    final otp = _otp;
    
    if (otp.length != 6) {
      _showErrorSnackBar('Please enter all 6 digits');
      return;
    }
    
    // Just show password fields - OTP will be verified when resetPassword is called
    setState(() => _otpEntered = true);
    _showSuccessSnackBar('OTP verified! Please set your new password.');
  }

  Future<void> _resetPassword() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    if (!_validatePasswordFields()) {
      return;
    }

    final newPass = _newPasswordController.text.trim();
    final otp = _otp;

    setState(() => _isVerifying = true);
    
    try {
      final response = await ApiService.resetPassword(widget.email, otp, newPass);
      
      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (response['status'] == 'success') {
        _showSuccessSnackBar('Password changed successfully! Please login with your new password.');
        
        // Redirect to Login with typed arguments
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/login', 
          (_) => false, 
          arguments: LoginScreenArguments(email: widget.email),
        );
      } else {
        _showErrorSnackBar(response['message'] ?? 'Password reset failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      if (mounted) {
        setState(() => _isVerifying = false);
        _showErrorSnackBar('Connection error. Please try again.');
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    
    try {
      final response = _isPasswordReset
          ? await ApiService.forgotPassword(widget.email)
          : await ApiService.resendOtp(widget.email);
      
      if (!mounted) return;
      setState(() => _isResending = false);
      
      if (response['status'] == 'success') {
        _showSuccessSnackBar('A new OTP has been sent to your email.');
        _clearOtpFields();
        // Reset password fields if they were showing
        if (_otpEntered) {
          setState(() {
            _otpEntered = false;
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            _passwordError = null;
            _confirmPasswordError = null;
          });
        }
      } else {
        _showErrorSnackBar(response['message'] ?? 'Failed to resend OTP. Please try again.');
      }
    } catch (e) {
      debugPrint('Resend OTP Error: $e');
      if (mounted) {
        setState(() => _isResending = false);
        _showErrorSnackBar('Connection error. Please try again.');
      }
    }
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  children: [
                    _buildTopNavigation(),
                    const SizedBox(height: 20),
                    _buildHeaderIcon(),
                    const SizedBox(height: 24),
                    _buildHeaderText(),
                    const SizedBox(height: 32),
                    _buildOtpInputGrid(),
                    const SizedBox(height: 32),
                    if (_isPasswordReset && _otpEntered) ...[
                      _buildPasswordFields(),
                      const SizedBox(height: 24),
                    ],
                    _buildSubmitButton(),
                    const SizedBox(height: 20),
                    _buildResendSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigation() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.green, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(
        _isPasswordReset ? Icons.lock_reset_rounded : Icons.verified_user_rounded,
        size: 60,
        color: Colors.green,
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      children: [
        Text(
          _isPasswordReset ? 'Reset Password' : 'Verify Your Email',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the 6-digit code sent to',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          widget.email,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) => _buildOtpBox(index)),
    );
  }

  Widget _buildOtpBox(int index) {
  return RawKeyboardListener(
    focusNode: FocusNode(),
    onKey: (RawKeyEvent event) {
      // Check if backspace was pressed
      if (event is RawKeyDownEvent && 
          event.logicalKey == LogicalKeyboardKey.backspace) {
        
        final currentText = _controllers[index].text;
        
        // If current field is empty and not the first field
        if (currentText.isEmpty && index > 0) {
          // Move focus to previous field
          _focusNodes[index - 1].requestFocus();
          // Clear the previous field
          _controllers[index - 1].clear();
        }
      }
    },
    child: Container(
      width: MediaQuery.of(context).size.width * 0.12,
      constraints: const BoxConstraints(minWidth: 40, maxWidth: 55),
      height: 60,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
        ),
        onChanged: (value) {
          // Handle forward navigation when digit is entered
          if (value.length == 1 && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
        },
      ),
    ),
  );
}

  Widget _buildSubmitButton() {
    String getButtonText() {
      if (_isPasswordReset) {
        if (_otpEntered) return 'Change Password';
        return 'Verify OTP';
      }
      return 'Verify & Continue';
    }
    
    bool isLoading = _isVerifying;
    
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          disabledBackgroundColor: Colors.green.withOpacity(0.5),
        ),
        onPressed: isLoading ? null : () {
          if (_isPasswordReset) {
            if (_otpEntered) {
              _resetPassword();
            } else {
              _verifyResetOtp();
            }
          } else {
            _verifyEmail();
          }
        },
        child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              getButtonText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          "Didn't receive the code?",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        if (_isResending)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.green,
            ),
          )
        else
          TextButton(
            onPressed: _resendOtp,
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text(
              'Resend Code',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        const Divider(height: 40),
        _buildPasswordField(
          controller: _newPasswordController,
          label: 'New Password',
          hint: 'Minimum 6 characters',
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
          errorText: _passwordError,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hint: 'Re-enter your new password',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          errorText: _confirmPasswordError,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? errorText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) {
        // Clear error when user starts typing
        if (_passwordError != null || _confirmPasswordError != null) {
          setState(() {
            _passwordError = null;
            _confirmPasswordError = null;
          });
        }
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.green),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        errorText: errorText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}