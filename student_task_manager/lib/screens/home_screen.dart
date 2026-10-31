import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/storage_service.dart';
import '../widgets/task_item.dart';
import 'add_task_screen.dart';
import 'completed_screen.dart';
import 'login_screen.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final String studentName;
  final String studentRoll;

  const HomeScreen({
    super.key,
    required this.studentName,
    required this.studentRoll,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();
  List<Task> _tasks = [];
  String _filterStatus = 'All'; // All | Pending | Overdue
  String _searchQuery = '';
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _loadTasks();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fabAnim.forward();
    });
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final tasks = await _storage.loadTasks();
    setState(() => _tasks = tasks);
  }

  List<Task> get _activeTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  List<Task> get _filteredTasks {
    final now = DateTime.now();
    return _activeTasks.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      switch (_filterStatus) {
        case 'Pending':
          return t.dueDate == null || !t.dueDate!.isBefore(now);
        case 'Overdue':
          return t.dueDate != null && t.dueDate!.isBefore(now);
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
    if (result != null) {
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name'],
        description: result['description'],
        dueDate: result['dueDate'] != null
            ? DateTime.parse(result['dueDate'])
            : null,
        priority: result['priority'] ?? 'medium',
        category: result['category'] ?? 'General',
      );
      setState(() => _tasks.add(newTask));
      await _storage.saveTasks(_tasks);
    }
  }

  Future<void> _toggleTask(int taskIndex, bool? value) async {
    final task = _tasks[taskIndex];
    setState(() {
      task.isCompleted = value ?? false;
      task.completedAt = task.isCompleted ? DateTime.now() : null;
    });
    await _storage.saveTasks(_tasks);
  }

  Future<void> _deleteTask(String id) async {
    setState(() => _tasks.removeWhere((t) => t.id == id));
    await _storage.saveTasks(_tasks);
  }

  Future<void> _editTask(Task original) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(existingTask: original)),
    );
    if (result != null) {
      setState(() {
        final idx = _tasks.indexWhere((t) => t.id == original.id);
        if (idx != -1) {
          _tasks[idx]
            ..name = result['name']
            ..description = result['description']
            ..dueDate = result['dueDate'] != null
                ? DateTime.parse(result['dueDate'])
                : null
            ..priority = result['priority'] ?? original.priority
            ..category = result['category'] ?? original.category;
        }
      });
      await _storage.saveTasks(_tasks);
    }
  }

  void _toggleTheme() async {
    final isDark = themeNotifier.value == ThemeMode.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
    await _storage.saveDarkMode(!isDark);
  }

  // Stats
  int get _totalActive => _activeTasks.length;
  int get _overdueCount => _activeTasks
      .where((t) =>
          t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
      .length;
  int get _completedCount => _tasks.where((t) => t.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredTasks;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primary,
                      cs.primary.withOpacity(0.7),
                      cs.tertiary.withOpacity(0.6),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          'Hello, ${widget.studentName} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Roll: ${widget.studentRoll}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats row
                        Row(
                          children: [
                            _statChip(
                                '$_totalActive', 'Active', Icons.pending_actions),
                            const SizedBox(width: 10),
                            _statChip('$_overdueCount', 'Overdue',
                                Icons.warning_amber_rounded,
                                color: Colors.orangeAccent),
                            const SizedBox(width: 10),
                            _statChip('$_completedCount', 'Done',
                                Icons.check_circle_outline,
                                color: Colors.greenAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(
                'My Tasks',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
            ),
            actions: [
              IconButton(
                icon: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (_, mode, __) => Icon(
                    mode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Colors.white,
                  ),
                ),
                tooltip: 'Toggle Theme',
                onPressed: _toggleTheme,
              ),
              IconButton(
                icon: const Icon(Icons.task_alt, color: Colors.white),
                tooltip: 'Completed Tasks',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompletedScreen(
                      allTasks: _tasks,
                      onDelete: _deleteTask,
                    ),
                  ),
                ).then((_) => _loadTasks()),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
            ],
          ),

          // ── Search & Filter ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Search
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor:
                          cs.surfaceContainerHighest.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter chips
                  Row(
                    children: ['All', 'Pending', 'Overdue'].map((status) {
                      final selected = _filterStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _filterStatus = status),
                          selectedColor: cs.primary.withOpacity(0.22),
                          checkmarkColor: cs.primary,
                          labelStyle: TextStyle(
                            color: selected ? cs.primary : null,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Task List ────────────────────────────────────
          filtered.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.checklist_rounded,
                            size: 72,
                            color: cs.onSurface.withOpacity(0.25)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No tasks match your search.'
                              : 'No tasks yet.\nTap + to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurface.withOpacity(0.45),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final task = filtered[i];
                      final globalIdx =
                          _tasks.indexWhere((t) => t.id == task.id);
                      return TaskItem(
                        key: ValueKey(task.id),
                        task: task,
                        onToggle: (val) => _toggleTask(globalIdx, val),
                        onDelete: () => _deleteTask(task.id),
                        onEdit: () => _editTask(task),
                        animationDelay: Duration(milliseconds: i * 60),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 88)),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut),
        child: FloatingActionButton.extended(
          onPressed: _addTask,
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
    );
  }

  Widget _statChip(String value, String label, IconData icon,
      {Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
