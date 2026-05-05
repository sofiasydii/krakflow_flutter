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

  String selectedFilter = "wszystkie";

  @override
  Widget build(BuildContext context) {

    int doneCount = TaskRepository.tasks.where((t) => t.done).length;

    // 🔹 FILTER
    List<Task> filteredTasks = TaskRepository.tasks;

    if (selectedFilter == "wykonane") {
      filteredTasks = TaskRepository.tasks.where((t) => t.done).toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = TaskRepository.tasks.where((t) => !t.done).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: TaskRepository.tasks.isEmpty
                ? null
                : () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Potwierdzenie"),
                    content: const Text("Usunąć wszystkie zadania?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Anuluj"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            TaskRepository.tasks.clear();
                          });
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Wszystkie zadania usunięte")),
                          );
                        },
                        child: const Text("Usuń"),
                      ),
                    ],
                  );
                },
              );
            },
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Masz dziś ${TaskRepository.tasks.length} zadania ($doneCount wykonane)"),

            const SizedBox(height: 10),

            // 🔹 FILTER BUTTONS
            Row(
              children: [
                filterButton("Wszystkie", "wszystkie"),
                filterButton("Do zrobienia", "do zrobienia"),
                filterButton("Wykonane", "wykonane"),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              "Dzisiejsze zadania",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // 🔹 LIST
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {

                  final task = filteredTasks[index];

                  return Dismissible(
                    key: ValueKey(task.title),
                    direction: DismissDirection.endToStart,

                    onDismissed: (_) {
                      setState(() {
                        TaskRepository.tasks.remove(task);
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Usunięto: ${task.title}")),
                      );
                    },

                    child: TaskCard(
                      task: task,

                      onChanged: (value) {
                        setState(() {
                          task.done = value!;
                        });
                      },

                      onTap: () async {
                        final updatedTask = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskScreen(task: task),
                          ),
                        );

                        if (updatedTask != null) {
                          setState(() {
                            int originalIndex = TaskRepository.tasks.indexOf(task);
                            TaskRepository.tasks[originalIndex] = updatedTask;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {

          final Task? newTask = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(),
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

  Widget filterButton(String text, String value) {
    final isActive = selectedFilter == value;

    return TextButton(
      onPressed: () {
        setState(() {
          selectedFilter = value;
        });
      },
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.blue : Colors.grey,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,

        leading: Checkbox(
          value: task.done,
          onChanged: onChanged,
        ),

        title: Text(
          task.title,
          style: TextStyle(
            decoration:
            task.done ? TextDecoration.lineThrough : TextDecoration.none,
            color: task.done ? Colors.grey : Colors.black,
          ),
        ),

        subtitle: Text(
          "termin: ${task.deadline} | priorytet: ${task.priority}",
        ),

        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł")),
            const SizedBox(height: 10),

            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin")),
            const SizedBox(height: 10),

            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet")),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                final task = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                );

                Navigator.pop(context, task);
              },
              child: const Text("Zapisz"),
            )
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;

  EditTaskScreen({super.key, required this.task});

  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    titleController.text = task.title;
    deadlineController.text = task.deadline;
    priorityController.text = task.priority;

    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(controller: titleController),
            TextField(controller: deadlineController),
            TextField(controller: priorityController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                final updated = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: task.done,
                  priority: priorityController.text,
                );

                Navigator.pop(context, updated);
              },
              child: const Text("Zapisz zmiany"),
            )
          ],
        ),
      ),
    );
  }
}