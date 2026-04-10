import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

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

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'Email is required';
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

  InputDecoration _buildInputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppTheme.surfaceLight,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
      errorStyle: const TextStyle(color: AppTheme.error, fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.isLogin) ...[
          _buildNameField(),
          const SizedBox(height: 20),
        ],
        _buildEmailField(),
        const SizedBox(height: 20),
        _buildPasswordField(),
        if (widget.isLogin) _buildLoginOptions(),
        if (!widget.isLogin) ...[
          const SizedBox(height: 24),
          _buildRoleSelector(),
        ],
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: widget.nameController,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(color: AppTheme.textPrimary),
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
      style: const TextStyle(color: AppTheme.textPrimary),
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
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: _buildInputDecoration(
        label: 'Password',
        hint: widget.isLogin ? 'Enter password' : 'Min. 6 characters',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textMuted,
            size: 22,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: _validatePassword,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildLoginOptions() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
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
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: widget.rememberMe 
                          ? AppTheme.primary 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.rememberMe 
                            ? AppTheme.primary 
                            : AppTheme.surfaceBorder,
                        width: 2,
                      ),
                    ),
                    child: widget.rememberMe
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Remember me',
                    style: TextStyle(
                      color: AppTheme.textSecondary, 
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(
                title: 'Player',
                subtitle: 'Book courts',
                icon: Icons.sports_soccer,
                value: 'PLAYER',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleOption(
                title: 'Owner',
                subtitle: 'Manage venue',
                icon: Icons.business,
                value: 'OWNER',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = widget.selectedRole == value;
    
    return GestureDetector(
      onTap: () => widget.onRoleChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primary.withOpacity(0.1) 
              : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppTheme.primary.withOpacity(0.2) 
                    : AppTheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
