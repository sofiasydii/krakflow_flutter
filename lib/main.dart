import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final List<Task> tasks = const [
    Task(
        title: "Zrobić projekt Flutter",
        deadline: "jutro",
        done: false,
        priority: "wysoki"),
    Task(
        title: "Oddać zadanie z AI",
        deadline: "dzisiaj",
        done: true,
        priority: "wysoki"),
    Task(
        title: "Posprzątać pokój",
        deadline: "w piątek",
        done: false,
        priority: "średni"),
    Task(
        title: "Przeczytać notatki",
        deadline: "weekend",
        done: true,
        priority: "niski"),
  ];

  @override
  Widget build(BuildContext context) {
    int doneCount = tasks.where((task) => task.done).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("KrakFlow"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Masz dziś ${tasks.length} zadania ($doneCount wykonane)"),
              const SizedBox(height: 16),
              const Text(
                "Dzisiejsze zadania",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: tasks
                      .map((task) => TaskCard(task: task))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  const Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          task.done
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
        ),
        title: Text(task.title),
        subtitle: Text(
          "termin: ${task.deadline} | priorytet: ${task.priority}",
        ),
      ),
    );
  }
}