import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/page_messages.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/back_or_home.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../courses/providers/course_provider.dart';
import '../data/task.dart';
import '../providers/task_provider.dart';

/// Dropdown values that are not course ids.
const _newCourseKey = '\u0000new';
const _addCourseKey = '\u0000add';

/// Add and edit share this page (FR-GEN-05): [id] null means "Tambah".
class TaskFormPage extends StatefulWidget {
  const TaskFormPage({super.key, this.id});

  final String? id;

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();

  /// A course id, [_newCourseKey] for [_newCourseName], or null.
  String? _courseValue;

  /// Typed via "+ Tambah mata kuliah baru"; created only on save.
  String? _newCourseName;

  /// Name of the edited task's course, shown even before courses load.
  String? _initialCourseName;

  /// Bumped to rebuild the course field after it is changed in code.
  int _courseFieldVersion = 0;

  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 23, minute: 59);
  TaskStatus _status = TaskStatus.belum;

  bool get _isEdit => widget.id != null;
  bool _ready = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    // Courses usually come from Jadwal; load them here too (FR-CRS-02).
    context.read<CourseProvider>().load();
    if (!_isEdit) {
      _ready = true;
      return;
    }
    context.read<TaskProvider>().fetch(widget.id!).then((t) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        if (t == null) {
          _notFound = true;
          return;
        }
        _title.text = t.title;
        _description.text = t.description ?? '';
        _courseValue = t.courseId;
        _initialCourseName = t.courseName;
        _date = DateUtils.dateOnly(t.deadline);
        _time = TimeOfDay.fromDateTime(t.deadline);
        _status = t.status;
      });
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Course id → name, including the edited task's course and a pending new
  /// one, so the dropdown value is always among its items.
  Map<String, String> _courseOptions(CourseProvider courses) {
    final options = {for (final c in courses.courses) c.id: c.name};
    final v = _courseValue;
    if (v != null && v != _newCourseKey && !options.containsKey(v)) {
      options[v] = _initialCourseName ?? 'Mata kuliah';
    }
    if (_newCourseName != null) options[_newCourseKey] = _newCourseName!;
    return options;
  }

  Future<void> _addCourse() async {
    final courses = context.read<CourseProvider>().courses;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewCourseDialog(),
    );
    if (!mounted) return;
    setState(() {
      _courseFieldVersion++;
      if (name == null) return;
      for (final c in courses) {
        if (c.name.toLowerCase() == name.toLowerCase()) {
          _courseValue = c.id;
          return;
        }
      }
      _newCourseName = name;
      _courseValue = _newCourseKey;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final isNew = _courseValue == _newCourseKey;
    final task = Task(
      id: widget.id,
      courseId: isNew ? null : _courseValue,
      courseName: _courseOptions(context.read<CourseProvider>())[_courseValue],
      title: _title.text,
      description: _description.text,
      deadline: DateTime(
        _date!.year,
        _date!.month,
        _date!.day,
        _time.hour,
        _time.minute,
      ),
      status: _status,
    );
    final error = await provider.save(task);
    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    closeWithMessage(context, 'Tugas disimpan', '/tasks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(fallback: '/tasks'),
        title: Text(_isEdit ? 'Edit tugas' : 'Tambah tugas'),
      ),
      body: !_ready
          ? const LoadingView()
          : _notFound
          ? const EmptyState(
              icon: Icons.search_off,
              title: 'Tugas tidak ditemukan',
              message: 'Tugas ini mungkin sudah dihapus.',
            )
          : _form(context),
    );
  }

  Widget _form(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final courseOptions = _courseOptions(context.watch<CourseProvider>());
    final valueStyle = Theme.of(context).textTheme.bodyLarge;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.formMaxWidth),
        // Fields validate individually once touched; a Form-wide autovalidate
        // would flag every untouched field after the first keystroke.
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama tugas',
                  hintText: 'Contoh: Laporan Praktikum 3',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => Validators.required(v, 'Nama tugas'),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                key: ValueKey(_courseFieldVersion),
                initialValue: _courseValue,
                isExpanded: true,
                style: valueStyle,
                decoration: InputDecoration(
                  labelText: 'Mata kuliah',
                  helperText: courseOptions.isEmpty
                      ? 'Mata kuliah dari Jadwal akan muncul di sini.'
                      : null,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => v == null || v == _addCourseKey
                    ? 'Mata kuliah wajib diisi'
                    : null,
                items: [
                  for (final e in courseOptions.entries)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text(
                        e.key == _newCourseKey ? '${e.value} (baru)' : e.value,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  DropdownMenuItem(
                    value: _addCourseKey,
                    child: Text(
                      '+ Tambah mata kuliah baru',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v == _addCourseKey) {
                    _addCourse();
                    return;
                  }
                  setState(() => _courseValue = v);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _PickerField<DateTime>(
                      label: 'Deadline',
                      value: _date,
                      icon: Icons.event_outlined,
                      format: (d) => DateFormatter.date(d),
                      validator: (v) =>
                          v == null ? 'Deadline wajib diisi' : null,
                      pick: (current) => showDatePicker(
                        context: context,
                        initialDate: current ?? DateTime.now(),
                        // Wide range so overdue tasks can still be edited.
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        helpText: 'Tanggal deadline',
                      ),
                      onChanged: (d) => setState(() => _date = d),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: _PickerField<TimeOfDay>(
                      label: 'Jam',
                      value: _time,
                      icon: Icons.schedule,
                      format: DateFormatter.time,
                      pick: (current) => showTimePicker(
                        context: context,
                        initialTime: current ?? _time,
                        helpText: 'Jam deadline',
                        builder: (ctx, child) => MediaQuery(
                          data: MediaQuery.of(ctx)
                              .copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      ),
                      onChanged: (t) => setState(() => _time = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<TaskStatus>(
                initialValue: _status,
                style: valueStyle,
                decoration: const InputDecoration(labelText: 'Status'),
                validator: (v) => v == null ? 'Status wajib diisi' : null,
                items: [
                  for (final s in TaskStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (opsional)',
                  hintText: 'Detail tugas, ketentuan, atau link pengumpulan',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: provider.saving ? null : _save,
                child: provider.saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan tugas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only field that opens a picker and shows the formatted value.
class _PickerField<T> extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.format,
    required this.pick,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final T? value;
  final IconData icon;
  final String Function(T) format;
  final Future<T?> Function(T? current) pick;
  final ValueChanged<T> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        Future<void> open() async {
          final picked = await pick(state.value);
          if (picked == null) return;
          state.didChange(picked);
          state.validate();
          onChanged(picked);
        }

        final v = state.value;
        return InkWell(
          onTap: open,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            isEmpty: v == null,
            decoration: InputDecoration(
              labelText: label,
              errorText: state.errorText,
              errorMaxLines: 2,
              suffixIcon: Icon(icon),
            ),
            child: Text(
              v == null ? '' : format(v),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Asks for a course name not yet in the list (FR-CRS-03).
class _NewCourseDialog extends StatefulWidget {
  const _NewCourseDialog();

  @override
  State<_NewCourseDialog> createState() => _NewCourseDialogState();
}

class _NewCourseDialogState extends State<_NewCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mata kuliah baru'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama mata kuliah',
            hintText: 'Contoh: Basis Data',
          ),
          validator: (v) => Validators.required(v, 'Nama mata kuliah'),
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Tambah')),
      ],
    );
  }
}
