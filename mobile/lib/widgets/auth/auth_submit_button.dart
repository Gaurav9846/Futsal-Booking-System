import 'package:flutter/material.dart';

class AuthSubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isLogin;
  final VoidCallback onPressed;
  final double? height;
  final double? width;
  final double? fontSize;

  const AuthSubmitButton({
    super.key,
    required this.isLoading,
    required this.isLogin,
    required this.onPressed,
    this.height,
    this.width,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.green.withOpacity(0.5),
          elevation: isLoading ? 0 : 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isLogin ? 'Login' : 'Create Account',
                style: TextStyle(
                  fontSize: fontSize ?? 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}