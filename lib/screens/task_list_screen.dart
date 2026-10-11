import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';
import '../widgets/task_widgets.dart';
import 'task_form_screen.dart';

enum TaskFilter { all, pending, completed }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _service = TaskService.instance;
  final _notifications = NotificationService.instance;
  final _searchController = TextEditingController();
  String _query = '';
  TaskFilter _filter = TaskFilter.all;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser!;
    _notifications.saveTokenForUser(user.uid, email: user.email);
    _notifications.tappedTaskId.addListener(_onNotificationTap);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNotificationTap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _notifications.tappedTaskId.removeListener(_onNotificationTap);
    super.dispose();
  }

  Future<void> _onNotificationTap() async {
    final id = _notifications.tappedTaskId.value;
    if (id == null) return;
    _notifications.tappedTaskId.value = null;

    final task = await _service.getTask(id);
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (task == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Task no longer exists')));
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)));
  }

  List<TaskModel> _apply(List<TaskModel> all) => all.where((task) {
        final matchesFilter = switch (_filter) {
          TaskFilter.all => true,
          TaskFilter.pending => !task.isCompleted,
          TaskFilter.completed => task.isCompleted,
        };
        final query = _query.toLowerCase();
        final matchesQuery = query.isEmpty ||
            task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query);
        return matchesFilter && matchesQuery;
      }).toList();

  Future<void> _copyToken() async {
    final token = await _notifications.getToken();
    if (!mounted) return;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FCM token not available')));
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FCM token copied to clipboard')));
    }
  }

  void _openForm([TaskModel? task]) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)));

  Future<void> _delete(TaskModel task) async {
    if (await confirmDelete(context, task.title)) {
      await _service.deleteTask(task.id);
    }
  }

  Widget _filterChip(TaskFilter filter, int count) {
    final selected = _filter == filter;
    final label = switch (filter) {
      TaskFilter.all => 'All',
      TaskFilter.pending => 'Pending',
      TaskFilter.completed => 'Completed',
    };
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 6),
            Text('$count',
                style: TextStyle(
                    fontSize: 10,
                    color: selected ? Colors.white70 : TaskPalette.muted)),
          ],
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF526176),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: TaskPalette.ink,
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selected ? TaskPalette.ink : const Color(0xFFE3E9F1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        visualDensity: VisualDensity.compact,
        onSelected: (_) => setState(() => _filter = filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: TaskPalette.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New Task',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        elevation: 5,
      ),
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: _service.watchTasks(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load tasks.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: TaskPalette.muted)),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2));
            }

            final allTasks = snapshot.data!;
            final tasks = _apply(allTasks);
            final pending = allTasks.where((task) => !task.isCompleted).length;
            final completed = allTasks.length - pending;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 7, 15, 0),
                  child: Row(
                    children: [
                      const Text('Tasks',
                          style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EDF5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${allTasks.length} TOTAL',
                            style: const TextStyle(
                                color: TaskPalette.muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: _showSearch ? 'Hide search' : 'Search tasks',
                        onPressed: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) {
                              _searchController.clear();
                              _query = '';
                            }
                          });
                        },
                        icon: const Icon(Icons.search_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Account options',
                        icon: CircleAvatar(
                          radius: 15,
                          backgroundColor: const Color(0xFFE8E7FF),
                          child: Text(
                            (user?.displayName?.isNotEmpty == true
                                    ? user!.displayName![0]
                                    : user?.email?.isNotEmpty == true
                                        ? user!.email![0]
                                        : 'U')
                                .toUpperCase(),
                            style: const TextStyle(
                                color: TaskPalette.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'token') _copyToken();
                          if (value == 'logout') AuthService.instance.signOut();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'token', child: Text('Copy FCM token')),
                          PopupMenuItem(
                              value: 'logout', child: Text('Sign out')),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(19, 0, 18, 11),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Today • ${DateFormat('EEEE, MMM d').format(DateTime.now())}',
                      style: const TextStyle(
                          color: TaskPalette.muted, fontSize: 11),
                    ),
                  ),
                ),
                if (_showSearch)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Search tasks',
                        prefixIcon: const Icon(Icons.search, size: 19),
                        suffixIcon: IconButton(
                          tooltip: 'Close search',
                          onPressed: () => setState(() {
                            _showSearch = false;
                            _query = '';
                            _searchController.clear();
                          }),
                          icon: const Icon(Icons.close, size: 17),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    children: [
                      _filterChip(TaskFilter.all, allTasks.length),
                      _filterChip(TaskFilter.pending, pending),
                      _filterChip(TaskFilter.completed, completed),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 58,
                                  width: 58,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFFEBEDFF),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.checklist_rounded,
                                      color: TaskPalette.primary, size: 27),
                                ),
                                const SizedBox(height: 14),
                                const Text('No tasks here',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                const SizedBox(height: 5),
                                const Text('Add a task to get your day moving.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: TaskPalette.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 90),
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () => _openForm(task),
                              onToggle: () => _service.toggleCompleted(task),
                              onDelete: () => _delete(task),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
