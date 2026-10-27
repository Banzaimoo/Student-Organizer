import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nim = TextEditingController();
  final _prodi = TextEditingController();
  bool _initialLoad = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    await auth.loadProfile();
    final p = auth.profile;
    if (p != null) {
      _name.text = p.fullName;
      _nim.text = p.nim ?? '';
      _prodi.text = p.studyProgram ?? '';
    }
    if (mounted) setState(() => _initialLoad = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _nim.dispose();
    _prodi.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.saveProfile(
      fullName: _name.text,
      nim: _nim.text,
      studyProgram: _prodi.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Profil berhasil disimpan' : auth.error ?? 'Gagal menyimpan'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _initialLoad
          ? const LoadingView()
          : auth.profile == null
              ? ErrorView(
                  message: auth.error ?? 'Gagal memuat profil',
                  onRetry: () {
                    setState(() => _initialLoad = true);
                    _load();
                  },
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _name,
                              decoration:
                                  const InputDecoration(labelText: 'Nama lengkap'),
                              validator: (v) => Validators.required(v, 'Nama lengkap'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nim,
                              decoration: const InputDecoration(labelText: 'NIM'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _prodi,
                              decoration:
                                  const InputDecoration(labelText: 'Program studi'),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: auth.loading ? null : _save,
                              child: auth.loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Simpan'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: auth.loading ? null : auth.signOut,
                              icon: const Icon(Icons.logout),
                              label: const Text('Keluar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
