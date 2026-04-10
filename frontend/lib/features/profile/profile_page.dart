import 'package:flutter/material.dart';

import 'profile_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.onboardingMode,
    required this.onSaved,
  });

  final bool onboardingMode;
  final VoidCallback onSaved;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _phone = TextEditingController();
  final _crea = TextEditingController();
  final _cityUf = TextEditingController(text: 'AM');
  final _logoPath = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileStore.load();
    if (profile != null) {
      _name.text = profile.name;
      _company.text = profile.company;
      _phone.text = profile.phone;
      _crea.text = profile.crea;
      _cityUf.text = profile.cityUf.isEmpty ? 'AM' : profile.cityUf;
      _logoPath.text = profile.logoPath;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ProfileStore.save(
      UserProfile(
        name: _name.text.trim(),
        company: _company.text.trim(),
        phone: _phone.text.trim(),
        crea: _crea.text.trim(),
        cityUf: _cityUf.text.trim().toUpperCase(),
        logoPath: _logoPath.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil salvo no dispositivo.')),
    );
    widget.onSaved();
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _phone.dispose();
    _crea.dispose();
    _cityUf.dispose();
    _logoPath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = widget.onboardingMode ? 'Primeiro acesso' : 'Seu perfil';
    final subtitle = widget.onboardingMode
        ? 'Guarde seus dados para gerar orcamentos com sua marca.'
        : 'Ajuste os dados que vao aparecer no resumo e no PDF.';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: !widget.onboardingMode,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeaderCard(title: title, subtitle: subtitle),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Seu nome'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _company,
                  decoration: const InputDecoration(labelText: 'Empresa / obra'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Telefone / WhatsApp'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _crea,
                  decoration: const InputDecoration(labelText: 'CREA (opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityUf,
                  decoration: const InputDecoration(labelText: 'Cidade / UF'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _logoPath,
                  decoration: const InputDecoration(
                    labelText: 'Caminho da logo (opcional)',
                    hintText: '/storage/emulated/0/Download/logo.png',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(widget.onboardingMode ? 'Comecar' : 'Salvar alteracoes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E5D49), Color(0xFFC77C52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
        ],
      ),
    );
  }
}
