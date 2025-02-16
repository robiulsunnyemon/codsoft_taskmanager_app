import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; // json এনকোড/ডিকোড করার জন্য
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  // সেভ করা থিম লোড করি
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0;
    setState(() {
      _themeMode = ThemeMode.values[themeModeIndex];
    });
  }

  // থিম সেভ করি
  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    setState(() {
      _themeMode = mode;
    });
  }

  void toggleTheme() {
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveThemeMode(newMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: Container(
            color: Colors.red,
            child: Center(
              child: SizedBox(
                width: 400, // মোবাইলের width
                height: 800, // মোবাইলের height
                child: ClipRRect(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: widget!,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      home: MyHomePage(
        title: 'Task Manager',
        themeMode: _themeMode,
        onThemeChanged: toggleTheme,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final ThemeMode themeMode;
  final VoidCallback onThemeChanged;

  const MyHomePage({
    super.key,
    required this.title,
    required this.themeMode,
    required this.onThemeChanged,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Task ক্লাসের আগে এনামটি যোগ করুন
enum SortBy {
  deadline,
  priority,
  title;

  String get label {
    switch (this) {
      case SortBy.deadline:
        return 'ডেডলাইন';
      case SortBy.priority:
        return 'প্রায়োরিটি';
      case SortBy.title:
        return 'নাম';
    }
  }
}

class _MyHomePageState extends State<MyHomePage> {
  List<Task> _tasks = [];
  String _searchQuery = '';
  TaskPriority? _filterPriority;
  TaskCategory? _filterCategory;
  SortBy _sortBy = SortBy.deadline;

  // ফিল্টার এবং সর্ট করা টাস্ক লিস্ট
  List<Task> get _sortedAndFilteredTasks {
    List<Task> tasks = List.from(_tasks);

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      tasks = tasks
          .where((task) =>
              task.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by priority
    if (_filterPriority != null) {
      tasks = tasks.where((task) => task.priority == _filterPriority).toList();
    }

    // Filter by category
    if (_filterCategory != null) {
      tasks = tasks.where((task) => task.category == _filterCategory).toList();
    }

    // Sort tasks
    switch (_sortBy) {
      case SortBy.deadline:
        tasks.sort((a, b) {
          if (a.deadline == null) return 1;
          if (b.deadline == null) return -1;
          return a.deadline!.compareTo(b.deadline!);
        });
      case SortBy.priority:
        tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
      case SortBy.title:
        tasks.sort((a, b) => a.title.compareTo(b.title));
    }

    return tasks;
  }

  // স্ট্যাটিসটিক্স উইজেট
  Widget _buildStatistics() {
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.isCompleted).length;
    final urgent = _tasks.where((t) => t.priority == TaskPriority.high).length;
    final dueToday = _tasks
        .where((t) =>
            t.deadline?.day == DateTime.now().day &&
            t.deadline?.month == DateTime.now().month &&
            t.deadline?.year == DateTime.now().year)
        .length;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 32,
              runSpacing: 24,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _StatItem(
                  label: 'মোট',
                  value: total.toString(),
                  icon: Icons.task,
                ),
                _StatItem(
                  label: 'সম্পন্ন',
                  value: completed.toString(),
                  icon: Icons.done_all,
                  color: Colors.green,
                ),
                _StatItem(
                  label: 'জরুরি',
                  value: urgent.toString(),
                  icon: Icons.priority_high,
                  color: Colors.red,
                ),
                _StatItem(
                  label: 'আজকের',
                  value: dueToday.toString(),
                  icon: Icons.today,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  // শুরুতেই সেইভ করা টাস্কগুলি লোড করি
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  // টাস্কগুলি লোড করার মেথড
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];

    setState(() {
      _tasks =
          tasksJson.map((task) => Task.fromJson(jsonDecode(task))).toList();
    });
  }

  // টাস্কগুলি সেইভ করার মেথড
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
  }

  void _addTask() {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        onSave: (Task task) {
          setState(() {
            _tasks.add(task);
            _saveTasks(); // নতুন টাস্ক যোগ করার পর সেইভ করি
          });
        },
      ),
    );
  }

  void _editTask(int index) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        task: _tasks[index],
        onSave: (Task task) {
          setState(() {
            _tasks[index] = task;
            _saveTasks(); // টাস্ক এডিট করার পর সেইভ করি
          });
        },
      ),
    );
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      _saveTasks(); // টাস্ক ডিলিট করার পর সেইভ করি
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final filteredTasks = _sortedAndFilteredTasks;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          // সর্টিং মেনু
          PopupMenuButton<SortBy>(
            icon: const Icon(Icons.sort),
            tooltip: 'সর্ট করুন',
            onSelected: (SortBy value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => SortBy.values
                .map(
                  (sort) => PopupMenuItem(
                    value: sort,
                    child: Row(
                      children: [
                        Icon(
                          _sortBy == sort
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(sort.label),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          // ফিল্টার মেনু
          PopupMenuButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'ফিল্টার করুন',
            itemBuilder: (context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('প্রায়োরিটি'),
              ),
              ...TaskPriority.values.map((p) => PopupMenuItem(
                    onTap: () => setState(() => _filterPriority = p),
                    child: Row(
                      children: [
                        Icon(
                          _filterPriority == p
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(p.label),
                      ],
                    ),
                  )),
              const PopupMenuItem(
                enabled: false,
                child: Text('ক্যাটাগরি'),
              ),
              ...TaskCategory.values.map((c) => PopupMenuItem(
                    onTap: () => setState(() => _filterCategory = c),
                    child: Row(
                      children: [
                        Icon(
                          _filterCategory == c
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(c.label),
                      ],
                    ),
                  )),
              const PopupMenuItem(
                enabled: false,
                child: Divider(),
              ),
              PopupMenuItem(
                onTap: () => setState(() {
                  _filterPriority = null;
                  _filterCategory = null;
                }),
                child: const Text('ফিল্টার মুছুন'),
              ),
            ],
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onThemeChanged,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'টাস্ক খুঁজুন...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStatistics(),
          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'কোন টাস্ক নেই'
                          : 'কোন টাস্ক পাওয়া যায়নি',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: task.isCompleted,
                              onChanged: (bool? value) {
                                setState(() {
                                  task.isCompleted = value!;
                                  _saveTasks();
                                });
                              },
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.6)
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.label,
                                      color: task.priority.color, size: 16),
                                  Text(' ${task.priority.label}'),
                                  const SizedBox(width: 8),
                                  Text('• ${task.category.label}'),
                                ],
                              ),
                              if (task.deadline != null)
                                Text(
                                  'ডেডলাইন: ${DateFormat('d MMM y').format(task.deadline!)}',
                                  style: TextStyle(
                                    color:
                                        task.deadline!.isBefore(DateTime.now())
                                            ? Colors.red
                                            : null,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editTask(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTask(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _addTask,
          tooltip: 'টাস্ক যোগ করুন',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// স্ট্যাটিসটিক্স আইটেম উইজেট
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class Task {
  String title;
  bool isCompleted;
  DateTime? deadline;
  TaskPriority priority;
  TaskCategory category;

  Task({
    required this.title,
    required this.isCompleted,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.category = TaskCategory.personal,
  });

  // Task অবজেক্টকে Map এ রূপান্তর করে
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
      'deadline': deadline?.toIso8601String(),
      'priority': priority.index,
      'category': category.index,
    };
  }

  // Map থেকে Task অবজেক্ট তৈরি করে
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      isCompleted: json['isCompleted'],
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      priority: TaskPriority.values[json['priority']],
      category: TaskCategory.values[json['category']],
    );
  }
}

enum TaskPriority {
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'কম';
      case TaskPriority.medium:
        return 'মাঝারি';
      case TaskPriority.high:
        return 'বেশি';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}

enum TaskCategory {
  personal,
  work,
  shopping,
  health;

  String get label {
    switch (this) {
      case TaskCategory.personal:
        return 'ব্যক্তিগত';
      case TaskCategory.work:
        return 'কাজ';
      case TaskCategory.shopping:
        return 'কেনাকাটা';
      case TaskCategory.health:
        return 'স্বাস্থ্য';
    }
  }
}

class TaskDialog extends StatefulWidget {
  final Task? task;
  final Function(Task) onSave;

  const TaskDialog({
    super.key,
    this.task,
    required this.onSave,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  late TextEditingController _titleController;
  late DateTime? _deadline;
  late TaskPriority _priority;
  late TaskCategory _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _deadline = widget.task?.deadline;
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _category = widget.task?.category ?? TaskCategory.personal;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.task == null ? 'নতুন টাস্ক' : 'টাস্ক সম্পাদনা',
        style: TextStyle(fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'টাস্কের নাম',
                labelStyle: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Text(_deadline == null
                    ? 'ডেডলাইন সেট করুন'
                    : 'ডেডলাইন: ${DateFormat('d MMM y').format(_deadline!)}'),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _deadline ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _deadline = date);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'প্রায়োরিটি',
              ),
              items: TaskPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _priority = value!);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'ক্যাটাগরি',
              ),
              items: TaskCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _category = value!);
              },
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.all(16),
      actions: [
        TextButton(
          child: Text(
            'বাতিল',
            style: TextStyle(fontSize: 14),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text(
            'সংরক্ষণ',
            style: TextStyle(fontSize: 14),
          ),
          onPressed: () {
            if (_titleController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('টাস্কের নাম দিন')),
              );
              return;
            }
            widget.onSave(Task(
              title: _titleController.text,
              isCompleted: widget.task?.isCompleted ?? false,
              deadline: _deadline,
              priority: _priority,
              category: _category,
            ));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
