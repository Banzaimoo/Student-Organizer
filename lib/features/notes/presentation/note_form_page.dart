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
import '../data/note.dart';
import '../providers/note_provider.dart';

/// Add and edit share this page (FR-GEN-05): [id] null means "Tambah".
class NoteFormPage extends StatefulWidget {
  const NoteFormPage({super.key, this.id});

  final String? id;

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();

  /// Null id with a name means a new course, created on save.
  String? _courseId;
  String? _courseName;

  DateTime? _date = DateUtils.dateOnly(DateTime.now());

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
    context.read<NoteProvider>().fetch(widget.id!).then((n) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        if (n == null) {
          _notFound = true;
          return;
        }
        _title.text = n.title;
        _content.text = n.content;
        _courseId = n.courseId;
        _courseName = n.courseName;
        _date = n.noteDate;
      });
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<NoteProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final note = Note(
      id: widget.id,
      courseId: _courseId,
      courseName: _courseName,
      title: _title.text,
      content: _content.text,
      noteDate: _date!,
    );
    final error = await provider.save(note);
    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    closeWithMessage(context, 'Catatan disimpan', '/notes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(fallback: '/notes'),
        title: Text(_isEdit ? 'Edit catatan' : 'Tambah catatan'),
      ),
      body: !_ready
          ? const LoadingView()
          : _notFound
          ? const EmptyState(
              icon: Icons.search_off,
              title: 'Catatan tidak ditemukan',
              message: 'Catatan ini mungkin sudah dihapus.',
            )
          : _form(context),
    );
  }

  Widget _form(BuildContext context) {
    final provider = context.watch<NoteProvider>();

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
                  labelText: 'Judul',
                  hintText: 'Contoh: Normalisasi 1NF–3NF',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => Validators.required(v, 'Judul'),
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
              PickerField<DateTime>(
                label: 'Tanggal catatan',
                value: _date,
                icon: Icons.event_outlined,
                format: (d) => DateFormatter.date(d),
                validator: (v) => v == null ? 'Tanggal wajib diisi' : null,
                pick: (current) => showDatePicker(
                  context: context,
                  initialDate: current ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  helpText: 'Tanggal catatan',
                ),
                onChanged: (d) => setState(() => _date = d),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _content,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                minLines: 8,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Isi catatan',
                  hintText: 'Tulis ringkasan materi, poin penting, atau rumus',
                  alignLabelWithHint: true,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => Validators.required(v, 'Isi catatan'),
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
                    : const Text('Simpan catatan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
