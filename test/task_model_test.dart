import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task_model.dart';

void main() {
  final task = TaskModel(
    id: '1',
    title: 'Complete Flutter Assignment',
    description: 'Finish the FCM part',
    dueDate: DateTime(2026, 10, 20),
    priority: 'high',
    isCompleted: false,
    createdAt: DateTime(2026, 10, 11),
  );

  test('toMap contains all required fields', () {
    final map = task.toMap();
    expect(map['title'], 'Complete Flutter Assignment');
    expect(map['priority'], 'high');
    expect(map['isCompleted'], false);
    expect(map.containsKey('dueDate'), true);
    expect(map.containsKey('createdAt'), true);
  });

  test('copyWith changes only the given fields', () {
    final done = task.copyWith(isCompleted: true);
    expect(done.isCompleted, true);
    expect(done.title, task.title);
    expect(done.id, task.id);
  });
}
