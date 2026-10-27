import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/page_messages.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/back_or_home.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../courses/providers/course_provider.dart';
import '../data/schedule.dart';
import '../providers/schedule_provider.dart';

/// Add and edit share this page (FR-GEN-05): [id] null means "Tambah".
class ScheduleFormPage extends StatefulWidget {
  const ScheduleFormPage({super.key, this.id, this.initialDay});

  final String? id;
  final int? initialDay;

  @override
  State<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends State<ScheduleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _endKey = GlobalKey<FormFieldState<TimeOfDay>>();
  final _course = TextEditingController();
  final _courseFocus = FocusNode();
  final _room = TextEditingController();
  final _lecturer = TextEditingController();

  late int _day = widget.initialDay ?? DateTime.now().weekday;
  TimeOfDay? _start;
  TimeOfDay? _end;

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
    context.read<ScheduleProvider>().fetch(widget.id!).then((s) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        if (s == null) {
          _notFound = true;
          return;
        }
        _course.text = s.courseName;
        _room.text = s.room;
        _lecturer.text = s.lecturer;
        _day = s.dayOfWeek;
        _start = s.startTime;
        _end = s.endTime;
      });
    });
  }

  @override
  void dispose() {
    _course.dispose();
    _courseFocus.dispose();
    _room.dispose();
    _lecturer.dispose();
    super.dispose();
  }

  /// The schedule as currently entered, or null while times are incomplete.
  Schedule? get _draft {
    if (_start == null || _end == null) return null;
    return Schedule(
      id: widget.id,
      courseName: _course.text,
      dayOfWeek: _day,
      startTime: _start!,
      endTime: _end!,
      room: _room.text,
      lecturer: _lecturer.text,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ScheduleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.save(_draft!);
    if (!mounted) return;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    closeWithMessage(context, 'Jadwal disimpan', '/schedules');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHome(fallback: '/schedules'),
        title: Text(_isEdit ? 'Edit jadwal' : 'Tambah jadwal'),
      ),
      body: !_ready
          ? const LoadingView()
          : _notFound
              ? const EmptyState(
                  icon: Icons.search_off,
                  title: 'Jadwal tidak ditemukan',
                  message: 'Jadwal ini mungkin sudah dihapus.',
                )
              : _form(context),
    );
  }

  Widget _form(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final courses = context.watch<CourseProvider>().courses;
    final draft = _draft;
    final clashes = draft != null && draft.endMinutes > draft.startMinutes
        ? provider.clashesWith(draft)
        : const <Schedule>[];

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
              RawAutocomplete<String>(
                textEditingController: _course,
                focusNode: _courseFocus,
                optionsBuilder: (value) {
                  final q = value.text.trim().toLowerCase();
                  if (q.isEmpty) return const [];
                  return courses
                      .map((c) => c.name)
                      .where((n) =>
                          n.toLowerCase().contains(q) && n.toLowerCase() != q);
                },
                fieldViewBuilder: (context, controller, focusNode, onSubmit) =>
                    TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Mata kuliah',
                    hintText: 'Contoh: Basis Data',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => Validators.required(v, 'Mata kuliah'),
                ),
                optionsViewBuilder: (context, onSelected, options) =>
                    _CourseOptions(options: options, onSelected: onSelected),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<int>(
                initialValue: _day,
                // Match the other fields' value weight.
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(labelText: 'Hari'),
                items: [
                  for (var d = 1; d <= 7; d++)
                    DropdownMenuItem(
                        value: d, child: Text(DateFormatter.dayName(d))),
                ],
                onChanged: (v) => setState(() => _day = v ?? _day),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Jam mulai',
                      value: _start,
                      fallback: const TimeOfDay(hour: 7, minute: 0),
                      validator: (v) => v == null ? 'Jam mulai wajib diisi' : null,
                      onChanged: (t) {
                        setState(() => _start = t);
                        // Re-check the end time against the new start.
                        if (_end != null) _endKey.currentState?.validate();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _TimeField(
                      fieldKey: _endKey,
                      label: 'Jam selesai',
                      value: _end,
                      fallback: _start == null
                          ? const TimeOfDay(hour: 8, minute: 40)
                          : TimeOfDay(
                              hour: (_start!.hour + 1) % 24,
                              minute: _start!.minute),
                      validator: (v) => v == null
                          ? 'Jam selesai wajib diisi'
                          : Validators.endAfterStart(_start, v),
                      onChanged: (t) => setState(() => _end = t),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.normal,
                curve: AppMotion.curve,
                alignment: Alignment.topCenter,
                child: clashes.isEmpty
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: _ClashNotice(clashes: clashes),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _room,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ruangan',
                  hintText: 'Contoh: Gedung F 2.3',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => Validators.required(v, 'Ruangan'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _lecturer,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Dosen'),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) => Validators.required(v, 'Dosen'),
                onFieldSubmitted: (_) => provider.saving ? null : _save(),
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
                    : const Text('Simpan jadwal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only field that opens a 24-hour time picker.
class _TimeField extends StatelessWidget {
  const _TimeField({
    this.fieldKey,
    required this.label,
    required this.value,
    required this.fallback,
    required this.validator,
    required this.onChanged,
  });

  final GlobalKey<FormFieldState<TimeOfDay>>? fieldKey;
  final String label;
  final TimeOfDay? value;
  final TimeOfDay fallback;
  final FormFieldValidator<TimeOfDay> validator;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormField<TimeOfDay>(
      key: fieldKey,
      initialValue: value,
      validator: validator,
      builder: (state) {
        Future<void> pick() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: state.value ?? fallback,
            helpText: label,
            builder: (ctx, child) => MediaQuery(
              data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          );
          if (picked == null) return;
          state.didChange(picked);
          state.validate();
          onChanged(picked);
        }

        final v = state.value;
        return InkWell(
          onTap: pick,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            isEmpty: v == null,
            decoration: InputDecoration(
              labelText: label,
              errorText: state.errorText,
              errorMaxLines: 2,
              suffixIcon: const Icon(Icons.schedule),
            ),
            child: Text(
              v == null ? '' : DateFormatter.time(v),
              style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
        );
      },
    );
  }
}

/// Non-blocking warning listing the classes that overlap (FR-SCH-09).
class _ClashNotice extends StatelessWidget {
  const _ClashNotice({required this.clashes});

  final List<Schedule> clashes;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final names =
        clashes.map((c) => '${c.courseName} (${c.timeRange})').join(', ');
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.warningContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.onWarningContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Bentrok dengan $names. Jadwal tetap bisa disimpan.',
                style: text.bodyMedium
                    ?.copyWith(color: colors.onWarningContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseOptions extends StatelessWidget {
  const _CourseOptions({required this.options, required this.onSelected});

  final Iterable<String> options;
  final AutocompleteOnSelected<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 3,
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240, maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            shrinkWrap: true,
            children: [
              for (final o in options)
                ListTile(
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(o, style: Theme.of(context).textTheme.bodyLarge),
                  onTap: () => onSelected(o),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
