/**
 * FILE: custom_button.dart (Shared Utility)
 * 
 * DESCRIPTION:
 * A primary action component used project-wide. It handles 3 states: 
 * Ready, Loading (showing a spinner), and Disabled. 
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - 'label': The text to display.
 *    - 'icon': Optional visual anchor.
 *    - 'isLoading': A boolean flag that logic layers use to prevent 
 *      double-submissions during API calls.
 * 2. PROCESSING:
 *    - Logic Gate: If 'isLoading' is true, the button is automatically 
 *      disabled and swaps the text for a 'CircularProgressIndicator'.
 * 3. SENDS DATA TO:
 *    - 'onPressed' Callback: Triggers the parent screen's logic (e.g., login, save).
 * 4. OUTPUTS/GUI:
 *    - A full-width 'ElevatedButton' with brand-consistent sizing and colors.
 */

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // GUI: Buttons are generally set to fill the container width.
      width: double.infinity,
      child: ElevatedButton.icon(
        // SECURITY/UX: Prevent clicks while a transaction is in progress.
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(isLoading ? 'Processing...' : label),
        style: backgroundColor != null
            ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
            : null,
      ),
    );
  }
}
