import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/extensions.dart';
import 'ui_kit.dart';

// Form building blocks for the posting flows. Sizes match [LabeledField]
// (10.5 bold label, 6dp gap, 11pt field text) so every form looks the same.

/// Bold label above a form control.
class FieldLabel extends StatelessWidget {
  const FieldLabel(
    this.label, {
    super.key,
    this.trailing,
    this.required = false,
  });

  final String label;
  final Widget? trailing;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.error),
                    ),
                ],
              ),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: headingColor(context),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Field-looking button that opens a bottom sheet of options.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
    this.hint = 'Select',
    this.required = false,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final String hint;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _open(context),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: icon == null ? null : Icon(icon, size: 17),
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: context.textSubColor,
              ),
            ),
            child: Text(
              hasValue ? value! : hint,
              style: TextStyle(
                fontSize: 11,
                color: hasValue ? context.textMainColor : context.textHintColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: SheetBody(
            title: label,
            children: [
              for (final o in options)
                SheetOption(
                  icon: icon ?? Icons.check_rounded,
                  label: o,
                  selected: o == value,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onChanged(o);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label + single-select wrap of [PillChip]s.
class ChipGroup extends StatelessWidget {
  const ChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in options)
              PillChip(
                label: o,
                height: 25,
                selected: value == o,
                onTap: () => onChanged(o),
              ),
          ],
        ),
      ],
    );
  }
}

/// Label + multi-select wrap of [PillChip]s.
class MultiChipGroup extends StatelessWidget {
  const MultiChipGroup({
    super.key,
    required this.label,
    required this.options,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in options)
              PillChip(
                label: o,
                height: 25,
                icon: values.contains(o) ? Icons.check_rounded : null,
                selected: values.contains(o),
                onTap: () => onChanged(
                  values.contains(o)
                      ? ({...values}..remove(o))
                      : {...values, o},
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Text field that turns typed skills into removable chips, with
/// suggestions underneath.
class SkillsInput extends StatefulWidget {
  const SkillsInput({
    super.key,
    required this.skills,
    required this.onChanged,
    this.label = 'Skills required',
    this.suggestions = const [],
  });

  final List<String> skills;
  final ValueChanged<List<String>> onChanged;
  final String label;
  final List<String> suggestions;

  @override
  State<SkillsInput> createState() => _SkillsInputState();
}

class _SkillsInputState extends State<SkillsInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final skill = raw.trim();
    if (skill.isEmpty) return;
    final exists = widget.skills.any(
      (s) => s.toLowerCase() == skill.toLowerCase(),
    );
    if (!exists) widget.onChanged([...widget.skills, skill]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.suggestions
        .where((s) => !widget.skills.contains(s))
        .take(8)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(
          widget.label,
          required: true,
          trailing: Text(
            '${widget.skills.length} added',
            style: TextStyle(fontSize: 9, color: context.textSubColor),
          ),
        ),
        TextField(
          controller: _controller,
          style: TextStyle(fontSize: 11, color: context.textMainColor),
          textInputAction: TextInputAction.done,
          onSubmitted: _add,
          decoration: InputDecoration(
            hintText: 'Type a skill and press add',
            prefixIcon: const Icon(Icons.bolt_rounded, size: 17),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.add_circle_rounded,
                size: 20,
                color: context.accentColor,
              ),
              onPressed: () => _add(_controller.text),
            ),
          ),
        ),
        if (widget.skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in widget.skills)
                _RemovableChip(
                  label: s,
                  onRemove: () => widget.onChanged(
                    widget.skills.where((x) => x != s).toList(),
                  ),
                ),
            ],
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Suggestions',
            style: TextStyle(fontSize: 9, color: context.textSubColor),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in suggestions)
                PillChip(
                  label: s,
                  icon: Icons.add_rounded,
                  selected: false,
                  onTap: () => _add(s),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 9, right: 4),
      decoration: BoxDecoration(
        color: kButtonBlue,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          InkResponse(
            onTap: onRemove,
            radius: 12,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Step 2 of 4" header with a segmented progress bar.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step, required this.steps});

  /// Zero-based current step.
  final int step;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step ${step + 1} of ${steps.length}',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: context.accentColor,
              ),
            ),
            const SizedBox(width: 6),
            Text('·', style: TextStyle(color: context.textHintColor)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                steps[step],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: headingColor(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? kButtonBlue : context.tagBgColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Label → value row used on review / summary cards.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: context.textSubColor),
            const SizedBox(width: 7),
          ],
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: context.textSubColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? headingColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small coloured status label ("Active", "Shortlisted").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      TintTag(label, color: color, height: 17, fontSize: 8.5);
}

/// Bullet list with green ticks (responsibilities, plan features).
class TickList extends StatelessWidget {
  const TickList(this.items, {super.key, this.color = AppColors.tintGreen});

  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final r in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.4,
                      color: context.textSubColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Primary button that shows a spinner while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const ElevatedButton(
        onPressed: null,
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: Text(label),
      );
    }
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }
}

/// Asks a yes/no question; resolves to true on confirm.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(c).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          onPressed: () => Navigator.of(c).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
