import 'package:flutter/material.dart';

class AuthFormFields extends StatefulWidget {
  final bool isLogin;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final String selectedRole;
  final bool rememberMe;
  final VoidCallback onRememberMeChanged;
  final VoidCallback onForgotPassword;
  final Function(String) onRoleChanged;

  const AuthFormFields({
    super.key,
    required this.isLogin,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.selectedRole,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
    required this.onRoleChanged,
  });

  @override
  State<AuthFormFields> createState() => _AuthFormFieldsState();
}

class _AuthFormFieldsState extends State<AuthFormFields> {
  bool _obscurePassword = true;

  // --- Validation Logic ---

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
    // RFC 5322 standard regex for email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (!widget.isLogin && v.length < 6) return 'Must be at least 6 characters';
    return null;
  }

  String? _validateName(String? v) {
    if (!widget.isLogin) {
      if (v == null || v.isEmpty) return 'Full Name is required';
      if (v.length < 3) return 'Please enter your full name (min. 3 characters)';
    }
    return null;
  }

  // --- Styling Helpers ---

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.green),
      errorText: errorText,
      filled: true,
      fillColor: Colors.grey.shade50,
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
    );
  }

  InputDecoration _buildPasswordDecoration() {
    return InputDecoration(
      labelText: 'Password',
      hintText: widget.isLogin ? 'Enter password' : 'Min. 6 characters',
      prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isLogin) ...[
          _buildNameField(),
          const SizedBox(height: 16),
        ],
        _buildEmailField(),
        const SizedBox(height: 16),
        _buildPasswordField(),
        if (widget.isLogin) _buildLoginOptions(),
        if (!widget.isLogin) ...[
          const SizedBox(height: 20),
          _buildRoleSelector(),
        ],
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: widget.nameController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _buildInputDecoration(
        label: 'Full Name',
        hint: 'Enter your full name',
        icon: Icons.person_outline,
      ),
      validator: _validateName,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: widget.emailController,
      keyboardType: TextInputType.emailAddress,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _buildInputDecoration(
        label: 'Email Address',
        hint: 'example@gmail.com',
        icon: Icons.email_outlined,
      ),
      validator: _validateEmail,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: widget.passwordController,
      obscureText: _obscurePassword,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: _buildPasswordDecoration(),
      validator: _validatePassword,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildLoginOptions() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: widget.onRememberMeChanged,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: widget.rememberMe,
                    onChanged: (_) => widget.onRememberMeChanged(),
                    activeColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Remember me',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Role",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.selectedRole,
          decoration: _buildInputDecoration(
            label: 'Register as',
            hint: null,
            icon: Icons.supervised_user_circle_outlined,
          ),
          items: const [
            DropdownMenuItem(value: 'PLAYER', child: Text('Player')),
            DropdownMenuItem(value: 'OWNER', child: Text('Futsal Owner')),
          ],
          onChanged: (v) {
            if (v != null) {
              widget.onRoleChanged(v);
            }
          },
          dropdownColor: Colors.white,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.green),
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }
}