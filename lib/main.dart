import 'package:flutter/material.dart';
import 'task_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyMainHomeScreen(),
    );
  }
}

class MyMainHomeScreen extends StatefulWidget {
  const MyMainHomeScreen({super.key});

  @override
  State<MyMainHomeScreen> createState() => _MyMainHomeScreenState();
}

class _MyMainHomeScreenState extends State<MyMainHomeScreen> {


  @override
  Widget build(BuildContext context) {
    int doneCount = TaskRepository.tasks.where((task) => task.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Masz dziś ${TaskRepository.tasks.length} zadania ($doneCount wykonane)"),
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
                children: TaskRepository.tasks
                    .map((task) => TaskCard(task: task))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:() async {
          final Task? newTask = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          );

          if (newTask != null) {
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
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


class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nowe zadanie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet (wysoki/średni/niski)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                );

                Navigator.pop(context, newTask);
              },
              child: const Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}