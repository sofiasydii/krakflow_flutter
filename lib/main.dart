import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'task_repository.dart';
import 'task_api_service.dart';
import 'task_local_database.dart';
import 'task_sync_service.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("tasks");

  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
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
  String selectedFilter = "wszystki";

  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  Future<void> _reload() async {
    await TaskLocalDatabase.deleteAllTasks();

    setState(() {
      _tasksFuture = loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Potwierdzenie"),
                  content: const Text("Usunąć wszystkie zadania?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Anuluj"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await TaskLocalDatabase.deleteAllTasks();

                        setState(() {
                          _tasksFuture = loadTasks();
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Wszystkie zadania usunięte"),
                          ),
                        );
                      },
                      child: const Text("Usuń"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Błąd: ${snapshot.error}"),
            );
          }

          TaskRepository.tasks = snapshot.data ?? [];

          int doneCount =
              TaskRepository.tasks.where((t) => t.done).length;

          List<Task> filteredTasks = TaskRepository.tasks;

          if (selectedFilter == "wykonane") {
            filteredTasks =
                TaskRepository.tasks.where((t) => t.done).toList();
          } else if (selectedFilter == "do zrobienia") {
            filteredTasks =
                TaskRepository.tasks.where((t) => !t.done).toList();
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masz dziś ${TaskRepository.tasks.length} zadan ($doneCount wykonanych)",
                ),
                const SizedBox(height: 10),
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];

                      return Dismissible(
                        key: ValueKey(task.id),
                        onDismissed: (_) async {
                          await TaskLocalDatabase.deleteTask(task.id);

                          setState(() {
                            _tasksFuture = loadTasks();
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text("Usunięto: ${task.title}"),
                            ),
                          );
                        },
                        child: TaskCard(
                          task: task,
                          onChanged: (value) async {
                            final isDone = value ?? false;
                            final wasDone = task.done;

                            final updatedTask = Task(
                              id: task.id,
                              title: task.title,
                              deadline: task.deadline,
                              done: isDone,
                              priority: task.priority,
                            );

                            await TaskLocalDatabase.updateTask(updatedTask);

                            if (!wasDone && isDone) {
                              await NotificationService
                                  .showTaskDoneNotification(task.title);
                            }

                            setState(() {
                              _tasksFuture = loadTasks();
                            });
                          },

                          onTap: () async {
                            final updatedTask =
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditTaskScreen(task: task),
                              ),
                            );

                            if (updatedTask != null) {
                              await TaskLocalDatabase
                                  .updateTask(updatedTask);

                              setState(() {
                                _tasksFuture = loadTasks();
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
          );
        },
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
            await TaskLocalDatabase.addTask(newTask);

            setState(() {
              _tasksFuture = loadTasks();
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
          fontWeight:
          isActive ? FontWeight.bold : FontWeight.normal,
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

  Color _priorityColor(String priority) {
    switch (priority) {
      case "wysoki":
        return Colors.red.shade100;
      case "średni":
        return Colors.orange.shade100;
      case "niski":
        return Colors.green.shade100;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _priorityColor(task.priority),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: task.done,
          onChanged: onChanged,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color:
            task.done ? Colors.grey : Colors.black,
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
      appBar: AppBar(
        title: const Text("Nowe zadanie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final task = Task(
                  id: DateTime.now()
                      .millisecondsSinceEpoch,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                );

                Navigator.pop(context, task);
              },
              child: const Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;

  EditTaskScreen({
    super.key,
    required this.task,
  });

  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    titleController.text = task.title;
    deadlineController.text = task.deadline;
    priorityController.text = task.priority;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edytuj zadanie"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł",
              ),
            ),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
              ),
            ),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final updated = Task(
                  id: task.id,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: task.done,
                  priority: priorityController.text,
                );

                Navigator.pop(context, updated);
              },
              child: const Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}