import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Read-only field that opens a picker and shows the formatted value.
class PickerField<T> extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.format,
    required this.pick,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final T? value;
  final IconData icon;
  final String Function(T) format;
  final Future<T?> Function(T? current) pick;
  final ValueChanged<T> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        Future<void> open() async {
          final picked = await pick(state.value);
          if (picked == null) return;
          state.didChange(picked);
          state.validate();
          onChanged(picked);
        }

        final v = state.value;
        return InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            isEmpty: v == null,
            decoration: InputDecoration(
              labelText: label,
              errorText: state.errorText,
              errorMaxLines: 2,
              suffixIcon: Icon(icon),
            ),
            child: Text(
              v == null ? '' : format(v),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        );
      },
    );
  }
}
