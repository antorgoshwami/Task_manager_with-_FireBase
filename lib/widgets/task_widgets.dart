import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';

class TaskPalette {
  static const primary = Color(0xFF5146E5);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF718096);
  static const line = Color(0xFFE8EDF4);
  static const green = Color(0xFF20A878);
  static const amber = Color(0xFFF3A21B);
  static const red = Color(0xFFE5485D);
}

Color priorityColor(String priority) => switch (priority.toLowerCase()) {
      'high' => TaskPalette.red,
      'low' => TaskPalette.green,
      _ => TaskPalette.amber,
    };

String formatDate(DateTime date) => DateFormat('MMM d, y').format(date);

Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: TaskPalette.muted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );

Future<bool> confirmDelete(BuildContext context, String title) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEFF1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: TaskPalette.red),
              ),
              const SizedBox(height: 14),
              const Text('Delete task?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              const Text(
                'Are you sure you want to remove this task? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: TaskPalette.muted, height: 1.45),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TaskPalette.line),
                ),
                child: Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: TaskPalette.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete task'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

class PriorityChip extends StatelessWidget {
  final String priority;
  const PriorityChip(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '${priority[0].toUpperCase()}${priority.substring(1).toLowerCase()}',
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 11, 8, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => onToggle(),
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Color(0xFFC7D2E2)),
                  activeColor: const Color(0xFF687386),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriorityChip(task.priority),
                        if (task.isCompleted)
                          const Text('Done',
                              style: TextStyle(
                                  color: TaskPalette.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: task.isCompleted
                            ? const Color(0xFF98A2B3)
                            : TaskPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: TaskPalette.muted, fontSize: 11, height: 1.4),
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 9),
                      child: Divider(height: 1, color: TaskPalette.line),
                    ),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12,
                            color: overdue ? TaskPalette.red : TaskPalette.muted),
                        const SizedBox(width: 5),
                        Text(
                          'Due ${formatDate(task.dueDate)}',
                          style: TextStyle(
                            color: overdue ? TaskPalette.red : TaskPalette.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Column(
                children: [
                  _SmallAction(
                    icon: Icons.edit_outlined,
                    tooltip: 'Edit task',
                    onPressed: onTap,
                  ),
                  _SmallAction(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete task',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _SmallAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 30,
        height: 30,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: Icon(icon, size: 15, color: const Color(0xFF9AA6B8)),
          visualDensity: VisualDensity.compact,
        ),
      );
}
