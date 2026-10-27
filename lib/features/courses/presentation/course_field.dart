import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../providers/course_provider.dart';

/// Dropdown values that are not course ids.
const _newCourseKey = '\u0000new';
const _addCourseKey = '\u0000add';

/// Course dropdown for the Tugas and Catatan forms (FR-CRS-02), with
/// "+ Tambah mata kuliah baru" (FR-CRS-03).
///
/// [onChanged] gets the course id and name. A new course comes back with a
/// null id and the typed name; the caller creates it on save so a cancelled
/// form leaves no stray course behind.
class CourseField extends StatefulWidget {
  const CourseField({
    super.key,
    this.initialId,
    this.initialName,
    required this.onChanged,
  });

  final String? initialId;

  /// Name of [initialId], shown even before courses load.
  final String? initialName;
  final void Function(String? id, String? name) onChanged;

  @override
  State<CourseField> createState() => _CourseFieldState();
}

class _CourseFieldState extends State<CourseField> {
  /// A course id, [_newCourseKey] for [_newCourseName], or null.
  late String? _value = widget.initialId;

  /// Typed via "+ Tambah mata kuliah baru"; created only on save.
  String? _newCourseName;

  /// Bumped to rebuild the dropdown after its value is changed in code.
  int _version = 0;

  @override
  void initState() {
    super.initState();
    // Courses usually come from Jadwal; load them here too.
    context.read<CourseProvider>().load();
  }

  /// Course id → name, including the initial course and a pending new one,
  /// so the dropdown value is always among its items.
  Map<String, String> _options(CourseProvider courses) {
    final options = {for (final c in courses.courses) c.id: c.name};
    final v = _value;
    if (v != null && v != _newCourseKey && !options.containsKey(v)) {
      options[v] = widget.initialName ?? 'Mata kuliah';
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
    // Rebuild even when cancelled so the dropdown drops the "+ Tambah" item.
    setState(() => _version++);
    if (name == null) return;
    for (final c in courses) {
      if (c.name.toLowerCase() == name.toLowerCase()) {
        setState(() => _value = c.id);
        widget.onChanged(c.id, c.name);
        return;
      }
    }
    setState(() {
      _newCourseName = name;
      _value = _newCourseKey;
    });
    widget.onChanged(null, name);
  }

  @override
  Widget build(BuildContext context) {
    final options = _options(context.watch<CourseProvider>());

    return DropdownButtonFormField<String>(
      key: ValueKey(_version),
      initialValue: _value,
      isExpanded: true,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: 'Mata kuliah',
        helperText: options.isEmpty
            ? 'Mata kuliah dari Jadwal akan muncul di sini.'
            : null,
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (v) =>
          v == null || v == _addCourseKey ? 'Mata kuliah wajib diisi' : null,
      items: [
        for (final e in options.entries)
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
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
      onChanged: (v) {
        if (v == _addCourseKey) {
          _addCourse();
          return;
        }
        setState(() => _value = v);
        widget.onChanged(v == _newCourseKey ? null : v, options[v]);
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
