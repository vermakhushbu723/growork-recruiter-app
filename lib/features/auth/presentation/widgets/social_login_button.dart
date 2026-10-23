import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: context.isDark
              ? AppColors.inputBorderDark
              : AppColors.inputBorder,
          width: 1.3,
        ),
        foregroundColor: context.textMainColor,
        backgroundColor: context.surfaceColor,
        minimumSize: const Size.fromHeight(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: context.textSubColor),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}
