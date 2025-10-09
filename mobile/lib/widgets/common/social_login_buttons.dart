// Social login buttons widget
import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback? onGoogleLogin;
  final VoidCallback? onAppleLogin;
  final VoidCallback? onFacebookLogin;

  const SocialLoginButtons({
    super.key,
    this.onGoogleLogin,
    this.onAppleLogin,
    this.onFacebookLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          '或使用以下方式登录',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'Google',
                Icons.g_mobiledata,
                Colors.red,
                onGoogleLogin,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton(
                'Apple',
                Icons.apple,
                Colors.black,
                onAppleLogin,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton(
                'Facebook',
                Icons.facebook,
                Colors.blue,
                onFacebookLogin,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        foregroundColor: color,
      ),
    );
  }
}
