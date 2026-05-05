import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'task_repository.dart';

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/todos"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];

      final random = Random();
      final priorities = ["niski", "średni", "wysoki"];
      final deadlines = [
        "dziś",
        "jutro",
        "pojutrze",
        "za 3 dni",
        "za tydzień",
        "za 2 tygodnie",
      ];

      return todos.map((todo) {
        final priority = priorities[random.nextInt(priorities.length)];
        final deadline = deadlines[random.nextInt(deadlines.length)];

        return Task(
          title: todo["todo"],
          deadline: deadline,
          done: todo["completed"],
          priority: priority,
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych: ${response.statusCode}");
    }
  }
}