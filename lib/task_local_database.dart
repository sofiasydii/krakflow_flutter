import 'package:hive_ce/hive.dart';
import 'task_repository.dart';
import 'dart:developer' as developer;

class TaskLocalDatabase {

  static Box get _box => Hive.box("tasks");

  static List<Task> getTasks() {

    developer.log(
      "Odczyt zadań",
      name: "TaskLocalDatabase",
    );

    return _box.values.map((item) {
      return Task.fromMap(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  static Future<void> saveTasks(List<Task> tasks) async {

    developer.log(
      "Zapisywanie ${tasks.length} zadań",
      name: "TaskLocalDatabase",
    );

    await _box.clear();

    for (final task in tasks) {
      await _box.put(task.id, task.toMap());
    }
  }

  static Future<void> addTask(Task task) async {
    developer.log(
      "Dodano zadanie: ${task.title}",
      name: "TaskLocalDatabase",
    );

    await _box.put(
      task.id,
      task.toMap(),
    );
  }

  static Future<void> updateTask(Task task) async {
    developer.log(
      "Edycja zadania: ${task.title}",
      name: "TaskLocalDatabase",
    );

    await _box.put(
      task.id,
      task.toMap(),
    );
  }

  static Future<void> deleteTask(int id) async {

    developer.log(
      "Usunięto zadanie id=$id",
      name: "TaskLocalDatabase",
    );

    await _box.delete(id);
  }

  static Future<void> deleteAllTasks() async {

    developer.log(
      "Usunięto wszystkie zadania",
      name: "TaskLocalDatabase",
    );

    await _box.clear();
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}