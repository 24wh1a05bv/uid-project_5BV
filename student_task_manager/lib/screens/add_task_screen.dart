import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? existingTask;
  const AddTaskScreen({super.key, this.existingTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  DateTime? _dueDate;
  String _priority = 'medium';
  String _category = 'General';

  static const _priorities = ['high', 'medium', 'low'];
  static const _categories = [
    'General',
    'Math',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'English',
    'History',
    'Geography',
    'Other',
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTask;
    _nameController = TextEditingController(text: t?.name ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _dueDate = t?.dueDate;
    _priority = t?.priority ?? 'medium';
    _category = t?.category ?? 'General';

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'dueDate': _dueDate?.toIso8601String(),
        'priority': _priority,
        'category': _category,
      });
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      default:
        return Colors.green;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'high':
        return Icons.keyboard_double_arrow_up;
      case 'medium':
        return Icons.drag_handle;
      default:
        return Icons.keyboard_double_arrow_down;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F0F1A),
                    const Color(0xFF1A1A2E),
                  ]
                : [
                    const Color(0xFFEEF2FF),
                    const Color(0xFFE0E7FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    _isEditing ? 'Edit Task' : 'New Task',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  centerTitle: true,
                  actions: [
                    TextButton(
                      onPressed: _save,
                      child: Text(
                        _isEditing ? 'Update' : 'Save',
                        style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Task name
                          _sectionLabel('Task Name'),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _nameController,
                            label: 'e.g. Complete assignment 1',
                            icon: Icons.edit_note,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Task name cannot be empty'
                                    : null,
                          ),
                          const SizedBox(height: 20),

                          // Description
                          _sectionLabel('Description'),
                          const SizedBox(height: 8),
                          _buildField(
                            controller: _descController,
                            label: 'Add details (optional)',
                            icon: Icons.notes,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),

                          // Category
                          _sectionLabel('Subject / Category'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((cat) {
                              final selected = _category == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _category = cat),
                                selectedColor:
                                    cs.primary.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: selected ? cs.primary : null,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Priority
                          _sectionLabel('Priority'),
                          const SizedBox(height: 10),
                          Row(
                            children: _priorities.map((p) {
                              final selected = _priority == p;
                              final color = _priorityColor(p);
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _priority = p),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? color.withOpacity(0.18)
                                            : cs.surfaceContainerHighest
                                                .withOpacity(0.3),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: selected
                                              ? color
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(_priorityIcon(p),
                                              color: selected
                                                  ? color
                                                  : cs.onSurface
                                                      .withOpacity(0.4),
                                              size: 22),
                                          const SizedBox(height: 4),
                                          Text(
                                            p[0].toUpperCase() +
                                                p.substring(1),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: selected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: selected
                                                  ? color
                                                  : cs.onSurface
                                                      .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Due date
                          _sectionLabel('Due Date'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withOpacity(0.4),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _dueDate != null
                                        ? cs.primary.withOpacity(0.5)
                                        : cs.outline.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_month_outlined,
                                      size: 20,
                                      color: _dueDate != null
                                          ? cs.primary
                                          : cs.onSurface.withOpacity(0.5)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _dueDate == null
                                          ? 'Pick a due date (optional)'
                                          : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _dueDate != null
                                            ? cs.onSurface
                                            : cs.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  if (_dueDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () =>
                                          setState(() => _dueDate = null),
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _save,
                              icon: Icon(
                                  _isEditing ? Icons.update : Icons.save_alt),
                              label: Text(
                                _isEditing ? 'Update Task' : 'Save Task',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: cs.onSurface.withOpacity(0.75),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
