import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'task_repository.dart';

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {

    final url = "$baseUrl/todos";

    developer.log(
      "Adres zapytania: $url",
      name: "TaskApiService",
    );

    final response = await http.get(
      Uri.parse(url),
    );

    developer.log(
      "HTTP status: ${response.statusCode}",
      name: "TaskApiService",
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];

      developer.log(
        "Liczba zadań: ${todos.length}",
        name: "TaskApiService",
      );

      final random = Random();

      final priorities = [
        "niski",
        "średni",
        "wysoki",
      ];

      final deadlines = [
        "dziś",
        "jutro",
        "za tydzień",
        "za 2 dni",
      ];

      return todos.map((todo) {
        return Task(
          id: todo["id"], 
          title: todo["todo"],
          deadline:
          deadlines[random.nextInt(deadlines.length)],
          done: todo["completed"],
          priority:
          priorities[random.nextInt(priorities.length)],
        );
      }).toList();
    } else {
      developer.log(
        "Błąd API",
        name: "TaskApiService",
        error: response.statusCode,
      );
    }
  }
}