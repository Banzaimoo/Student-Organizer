import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/page_messages.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/back_or_home.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/picker_field.dart';
import '../../courses/presentation/course_field.dart';
import '../data/task.dart';
import '../providers/task_provider.dart';

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

  /// Null id with a name means a new course, created on save.
  String? _courseId;
  String? _courseName;

  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 23, minute: 59);
  TaskStatus _status = TaskStatus.belum;

  bool get _isEdit => widget.id != null;
  bool _ready = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
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
        _courseId = t.courseId;
        _courseName = t.courseName;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TaskProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final task = Task(
      id: widget.id,
      courseId: _courseId,
      courseName: _courseName,
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
              CourseField(
                initialId: _courseId,
                initialName: _courseName,
                onChanged: (id, name) {
                  _courseId = id;
                  _courseName = name;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: PickerField<DateTime>(
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
                    child: PickerField<TimeOfDay>(
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
