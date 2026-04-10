import 'package:flutter/material.dart';

class ForgotPasswordView extends StatefulWidget {
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const ForgotPasswordView({
    super.key,
    required this.controller,
    required this.submitting,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  bool _resetEmailSent = false;
  String? _emailError;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _handleSubmit() {
    // Validate email before submitting
    final email = widget.controller.text.trim();
    final error = _validateEmail(email);
    
    if (error != null) {
      setState(() => _emailError = error);
      return;
    }
    
    // Clear error if valid
    setState(() => _emailError = null);
    
    // Call parent submit
    widget.onSubmit();
  }

  void _handleBack() {
    // Reset state when going back
    setState(() {
      _resetEmailSent = false;
      _emailError = null;
      widget.controller.clear();
    });
    widget.onBack();
  }

  @override
  void didUpdateWidget(covariant ForgotPasswordView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent resets submitting, we can assume email was sent successfully
    if (!widget.submitting && oldWidget.submitting && !_resetEmailSent) {
      // Successfully submitted and not already showing success state
      setState(() {
        _resetEmailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (!_resetEmailSent) 
            _buildResetForm()
          else 
            _buildSuccessView(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: _handleBack,
          tooltip: 'Back to Login',
        ),
        const Expanded(
          child: Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 48), // Balance the back button
      ],
    );
  }

  Widget _buildResetForm() {
    return Column(
      children: [
        // Description text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'Enter your email address and we\'ll send you a verification code to reset your password.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        // Email input field
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onFieldSubmitted: (_) => _handleSubmit(),
          onChanged: (_) {
            // Clear error when user starts typing
            if (_emailError != null) {
              setState(() => _emailError = null);
            }
          },
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.green),
            errorText: _emailError,
            filled: true,
            fillColor: Colors.grey.shade50,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.submitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.green.withOpacity(0.5),
            ),
            child: widget.submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send Reset Link',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        // Success icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 60,
          ),
        ),
        const SizedBox(height: 24),
        // Success message
        const Text(
          'Reset Link Sent!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'We\'ve sent a verification code to your email. Please check your inbox and follow the instructions.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        // Back button
        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton(
            onPressed: _handleBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}