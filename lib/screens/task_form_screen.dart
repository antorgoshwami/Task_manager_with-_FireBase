import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../services/task_service.dart';
import '../widgets/task_widgets.dart';

/// Used for both adding (task == null) and editing a task.
class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late DateTime _due;
  late String _priority;
  late bool _completed;
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title ?? '');
    _desc = TextEditingController(text: widget.task?.description ?? '');
    _restoreValues();
  }

  void _restoreValues() {
    final task = widget.task;
    _due = task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _priority = task?.priority ?? 'medium';
    _completed = task?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _title.text = widget.task?.title ?? '';
      _desc.text = widget.task?.description ?? '';
      _restoreValues();
    });
    _formKey.currentState?.reset();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: TaskPalette.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await TaskService.instance.updateTask(widget.task!.copyWith(
          title: _title.text.trim(),
          description: _desc.text.trim(),
          dueDate: _due,
          priority: _priority,
          isCompleted: _completed,
        ));
      } else {
        await TaskService.instance.addTask(TaskModel(
          id: '',
          title: _title.text.trim(),
          description: _desc.text.trim(),
          dueDate: _due,
          priority: _priority,
          isCompleted: false,
          createdAt: DateTime.now(),
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save task: $error')));
      }
    }
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, widget.task!.title)) return;
    await TaskService.instance.deleteTask(widget.task!.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _priorityOption(String value) {
    final selected = _priority == value;
    final color = priorityColor(value);
    final label = '${value[0].toUpperCase()}${value.substring(1)}';
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _priority = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 41,
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.09) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? color : const Color(0xFFE4E9F1),
                  width: selected ? 1.2 : 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 6,
                  width: 6,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: selected ? color : TaskPalette.muted,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEdit ? 'Edit Task' : 'New Task',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          if (_isEdit)
            TextButton(
              onPressed: _saving ? null : _reset,
              child: const Text('Reset',
                  style: TextStyle(
                      color: TaskPalette.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          if (_isEdit)
            IconButton(
              tooltip: 'Delete task',
              icon: const Icon(Icons.delete_outline, size: 19),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              fieldLabel('Title'),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    hintText: 'e.g. Complete Flutter Assignment'),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Title is required'
                        : null,
              ),
              const SizedBox(height: 19),
              fieldLabel('Notes'),
              TextFormField(
                controller: _desc,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    hintText: 'Add details, links, or notes...'),
              ),
              const SizedBox(height: 19),
              fieldLabel('Due date'),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE4E9F1)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(formatDate(_due),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.calendar_month_outlined,
                          size: 18, color: TaskPalette.muted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 19),
              fieldLabel('Priority'),
              Row(
                children: [
                  _priorityOption('low'),
                  _priorityOption('medium'),
                  _priorityOption('high'),
                ],
              ),
              if (_isEdit) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE4E9F1)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Completed',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    subtitle: const Text('Mark task as done',
                        style: TextStyle(
                            color: TaskPalette.muted, fontSize: 10)),
                    value: _completed,
                    activeThumbColor: TaskPalette.primary,
                    onChanged: (value) => setState(() => _completed = value),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 47,
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: TaskPalette.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(_isEdit ? 'Save Changes' : 'Save Task'),
                ),
              ),
              TextButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: TaskPalette.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
