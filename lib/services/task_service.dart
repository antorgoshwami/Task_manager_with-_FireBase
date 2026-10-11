import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/task_model.dart';

/// Tasks live at: users/{uid}/tasks/{taskId}
class TaskService {
  TaskService._();
  static final instance = TaskService._();

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');
  }

  Stream<List<TaskModel>> watchTasks() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(TaskModel.fromDoc).toList());

  Future<TaskModel?> getTask(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? TaskModel.fromDoc(doc) : null;
  }

  Future<void> addTask(TaskModel task) => _col.add(task.toMap());

  Future<void> updateTask(TaskModel task) =>
      _col.doc(task.id).update(task.toMap());

  Future<void> toggleCompleted(TaskModel task) =>
      _col.doc(task.id).update({'isCompleted': !task.isCompleted});

  Future<void> deleteTask(String id) => _col.doc(id).delete();
}
