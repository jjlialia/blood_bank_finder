library;

import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData? prefixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    this.prefixIcon,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // GUI: Centralized vertical spacing for all forms.
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          // Note: Border and styling are inherited from the global Theme in main.dart.
        ),
      ),
    );
  }
}

/// FILE: custom_text_field.dart (Shared Utility)
///
/// DESCRIPTION:
/// A standardized input component for the entire app. It wraps the
/// standard 'TextFormField' with project-specific styling and convenience
/// properties (prefix icons, validation hooks).
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - 'controller': External state management from screens.
///    - 'validator': Logic blocks from screens to ensure data integrity.
/// 2. SENDS DATA TO:
///    - Parent State: Via the 'onSaved' or 'onChanged' callbacks when
///      the user interacts with the keyboard.
/// 3. OUTPUTS:
///    - A visually consistent form field with automated padding and
///      standard focus behaviors.
