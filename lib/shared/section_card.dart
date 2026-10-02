import 'package:flutter/material.dart';

/// A titled card: the building block of the dashboard.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(title!, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// A label / value line of a results table.
class ValueRow extends StatelessWidget {
  const ValueRow(
    this.label,
    this.value, {
    super.key,
    this.strong = false,
    this.color,
  });

  final String label;
  final String value;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = strong
        ? text.titleSmall
        : text.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(
            value,
            style:
                (strong
                        ? text.titleSmall
                        : text.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ))
                    ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// A label (and an optional second line) with right-aligned value columns.
class ColumnsRow extends StatelessWidget {
  const ColumnsRow(
    this.label,
    this.values, {
    super.key,
    this.note,
    this.strong = false,
    this.trailing,
  }) : header = false;

  const ColumnsRow.header(this.values, {super.key, this.trailing})
    : label = '',
      note = null,
      strong = false,
      header = true;

  final String label;
  final List<String> values;

  /// Second line under the label.
  final String? note;
  final bool strong;
  final bool header;

  /// After the values (an action); same width on every row of a table.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final labelStyle = strong
        ? text.titleSmall
        : text.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
    final valueStyle = header
        ? text.labelMedium
        : strong
        ? text.titleSmall
        : text.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: labelStyle),
                if (note != null) Text(note!, style: text.bodySmall),
              ],
            ),
          ),
          for (final value in values)
            SizedBox(
              width: 84,
              // One line: a wider value shrinks rather than wraps.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(value, style: valueStyle),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}
