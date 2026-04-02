import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

enum OtpScreenType { emailVerification, passwordReset }

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
  // 6 separate controllers for each OTP digit
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Password reset fields
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isVerifying = false;
  bool _isResending = false;
  bool _otpEntered = false; // for reset — show password fields after OTP

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

  // ============================================
  // VERIFY EMAIL OTP
  // ============================================
  Future<void> _verifyEmail() async {
    if (_otp.length != 6) {
      _showSnackBar('Please enter all 6 digits', false);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response = await ApiService.verifyEmail(widget.email, _otp);

      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (response['status'] == 'success') {
        // Save token and user — same as login
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.saveAuthData(response['token'], response['user']);

        _showSnackBar('Email verified successfully!', true);

        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        auth.navigateBasedOnRole(context);
      } else {
        _showSnackBar(response['message'] ?? 'Invalid OTP', false);
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      _showSnackBar('Error: $e', false);
    }
  }

  // ============================================
  // VERIFY RESET OTP — show password fields
  // ============================================
  Future<void> _verifyResetOtp() async {
    if (_otp.length != 6) {
      _showSnackBar('Please enter all 6 digits', false);
      return;
    }
    setState(() => _otpEntered = true);
  }

  // ============================================
  // RESET PASSWORD
  // ============================================
  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      _showSnackBar('Password must be at least 6 characters', false);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar('Passwords do not match', false);
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final response =
          await ApiService.resetPassword(widget.email, _otp, newPassword);

      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (response['status'] == 'success') {
        _showSnackBar('Password reset successful! Please login.', true);
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      } else {
        _showSnackBar(response['message'] ?? 'Reset failed', false);
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      _showSnackBar('Error: $e', false);
    }
  }

  // ============================================
  // RESEND OTP
  // ============================================
  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      final response = _isPasswordReset
          ? await ApiService.forgotPassword(widget.email)
          : await ApiService.resendOtp(widget.email);

      if (!mounted) return;
      setState(() => _isResending = false);

      _showSnackBar(
        response['status'] == 'success'
            ? 'OTP resent to ${widget.email}'
            : response['message'] ?? 'Failed to resend OTP',
        response['status'] == 'success',
      );

      // Clear OTP fields
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } catch (e) {
      setState(() => _isResending = false);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.green),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Icon(
                      _isPasswordReset ? Icons.lock_reset : Icons.mark_email_read,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _isPasswordReset ? 'Reset Password' : 'Verify Your Email',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'We sent a 6-digit OTP to',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // OTP Input
                  _buildOtpInput(),

                  const SizedBox(height: 32),

                  // Password fields (reset flow only, after OTP entered)
                  if (_isPasswordReset && _otpEntered) ...[
                    _buildPasswordFields(),
                    const SizedBox(height: 24),
                  ],

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isVerifying
                          ? null
                          : () {
                              if (_isPasswordReset) {
                                _otpEntered
                                    ? _resetPassword()
                                    : _verifyResetOtp();
                              } else {
                                _verifyEmail();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isPasswordReset
                                  ? (_otpEntered
                                      ? 'Reset Password'
                                      : 'Verify OTP')
                                  : 'Verify Email',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Resend OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive OTP? ",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: _resendOtp,
                              child: const Text(
                                'Resend',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // OTP INPUT BOXES
  // ============================================
  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                // Move to next field
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                // Move to previous field on delete
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  // ============================================
  // PASSWORD FIELDS FOR RESET
  // ============================================
  Widget _buildPasswordFields() {
    return Column(
      children: [
        TextFormField(
          controller: _newPasswordController,
          obscureText: _obscureNew,
          decoration: InputDecoration(
            labelText: 'New Password',
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
                _obscureNew ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
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
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}