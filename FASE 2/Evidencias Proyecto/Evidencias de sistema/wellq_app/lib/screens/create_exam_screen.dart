import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/session.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({required this.api, required this.session, super.key});

  final ApiClient api;
  final Session session;

  @override
  State<CreateExamScreen> createState() => _CreateExamScreenState();
}

class _CreateExamScreenState extends State<CreateExamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _notes = TextEditingController();
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _patientId;
  String? _examTypeId;
  DateTime _examDate = DateTime.now();
  PlatformFile? _file;
  List<int>? _fileBytes;
  int _fileSize = 0;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _types = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        widget.api.getJson(
          '/patients?pageSize=100',
          widget.session.accessToken,
        ),
        widget.api.getJson('/exams/types', widget.session.accessToken),
      ]);
      if (!mounted) return;
      setState(() {
        _patients = List<Map<String, dynamic>>.from(
          results[0]['items'] as List,
        );
        _types = List<Map<String, dynamic>>.from(results[1]['items'] as List);
        _patientId = _patients.isEmpty ? null : _patients.first['id'] as String;
        _examTypeId = _types.isEmpty ? null : _types.first['id'] as String;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (selected != null && mounted) {
      final size = await selected.length();
      if (size > 10 * 1024 * 1024) {
        setState(() => _error = 'El archivo no puede superar los 10 MB.');
        return;
      }
      final bytes = await selected.readAsBytes();
      if (!mounted) return;
      setState(() {
        _file = selected;
        _fileBytes = bytes;
        _fileSize = size;
        _error = null;
        if (_name.text.trim().isEmpty) {
          _name.text = selected.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
        }
      });
    }
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha del examen',
    );
    if (selected != null && mounted) setState(() => _examDate = selected);
  }

  String get _dateValue =>
      '${_examDate.year.toString().padLeft(4, '0')}-'
      '${_examDate.month.toString().padLeft(2, '0')}-'
      '${_examDate.day.toString().padLeft(2, '0')}';

  String _nameFor(List<Map<String, dynamic>> values, String? id) =>
      values.firstWhere(
            (item) => item['id'] == id,
            orElse: () => <String, dynamic>{'name': 'No seleccionado'},
          )['name']
          as String;

  void _continue() {
    setState(() => _error = null);
    if (_step == 0 && _file == null) {
      setState(() => _error = 'Selecciona un archivo para continuar.');
      return;
    }
    if (_step == 1 && !(_formKey.currentState?.validate() ?? false)) return;
    if (_step < 2) setState(() => _step++);
  }

  Future<void> _submit() async {
    final bytes = _fileBytes;
    if (bytes == null || _patientId == null || _examTypeId == null) {
      setState(() => _error = 'Falta información para crear el examen.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await widget.api.postJson(
        '/exams',
        widget.session.accessToken,
        {
          'patientId': _patientId,
          'examTypeId': _examTypeId,
          'name': _name.text.trim(),
          'examDate': _dateValue,
          'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        },
      );
      final exam = created['exam'] as Map<String, dynamic>;
      await widget.api.uploadExamFile(
        examId: exam['id'] as String,
        token: widget.session.accessToken,
        fileName: _file!.name,
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examen cargado correctamente.'),
          backgroundColor: Color(0xFF174EA6),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF174EA6);
    const darkBlue = Color(0xFF102A43);
    const bgLight = Color(0xFFEEF3F9);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: darkBlue),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Subir examen',
          style: TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: primaryBlue),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: primaryBlue,
                              ),
                        ),
                        child: Stepper(
                          elevation: 0,
                          type: StepperType.vertical,
                          currentStep: _step,
                          onStepCancel: _step == 0
                              ? null
                              : () => setState(() => _step--),
                          onStepContinue: _saving
                              ? null
                              : (_step == 2 ? _submit : _continue),
                          controlsBuilder: (context, details) => Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: details.onStepContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: _saving
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          _step == 2
                                              ? Icons.cloud_upload_rounded
                                              : Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                  label: Text(
                                    _step == 2 ? 'Confirmar y subir' : 'Continuar',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (_step > 0) ...[
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: details.onStepCancel,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: darkBlue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: const Text('Volver'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          steps: [
                            Step(
                              title: Text(
                                'Archivo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              subtitle: const Text(
                                'PDF, JPG o PNG · máximo 10 MB',
                                style: TextStyle(fontSize: 12),
                              ),
                              isActive: _step >= 0,
                              state: _file == null
                                  ? StepState.indexed
                                  : StepState.complete,
                              content: _fileStep(primaryBlue, darkBlue),
                            ),
                            Step(
                              title: Text(
                                'Información',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              subtitle: const Text(
                                'Paciente y datos del examen',
                                style: TextStyle(fontSize: 12),
                              ),
                              isActive: _step >= 1,
                              content: _informationStep(primaryBlue, darkBlue),
                            ),
                            Step(
                              title: Text(
                                'Confirmación',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              subtitle: const Text(
                                'Revisa antes de guardar',
                                style: TextStyle(fontSize: 12),
                              ),
                              isActive: _step >= 2,
                              content: _confirmationStep(primaryBlue, darkBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _fileStep(Color primaryBlue, Color darkBlue) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _file != null
                ? primaryBlue.withOpacity(0.5)
                : Colors.grey.shade300,
            width: _file != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _file == null
                    ? primaryBlue.withOpacity(0.08)
                    : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _file == null
                    ? Icons.cloud_upload_outlined
                    : Icons.check_circle_rounded,
                size: 44,
                color: _file == null ? primaryBlue : Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _file?.name ?? 'Selecciona el archivo del examen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: darkBlue,
              ),
            ),
            if (_file != null) ...[
              const SizedBox(height: 4),
              Text(
                '${(_fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: primaryBlue),
              ),
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: Text(
                _file == null ? 'Elegir archivo' : 'Cambiar archivo',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _informationStep(Color primaryBlue, Color darkBlue) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _patientId,
                decoration: _inputDecoration(
                  labelText: 'Paciente',
                  icon: Icons.person_outline_rounded,
                ),
                items: _patients
                    .map(
                      (item) => DropdownMenuItem(
                        value: item['id'] as String,
                        child: Text(item['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _patientId = value),
                validator: (value) =>
                    value == null ? 'Selecciona un paciente.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _examTypeId,
                decoration: _inputDecoration(
                  labelText: 'Tipo de examen',
                  icon: Icons.science_outlined,
                ),
                items: _types
                    .map(
                      (item) => DropdownMenuItem(
                        value: item['id'] as String,
                        child: Text(item['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _examTypeId = value),
                validator: (value) =>
                    value == null ? 'Selecciona un tipo.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: _inputDecoration(
                  labelText: 'Nombre del examen',
                  icon: Icons.description_outlined,
                ),
                validator: (value) => (value?.trim().length ?? 0) < 3
                    ? 'Ingresa al menos 3 caracteres.'
                    : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _chooseDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputDecoration(
                    labelText: 'Fecha del examen',
                    icon: Icons.calendar_today_rounded,
                  ),
                  child: Text(
                    _dateValue,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: _inputDecoration(
                  labelText: 'Observaciones (opcional)',
                  icon: Icons.notes_rounded,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _confirmationStep(Color primaryBlue, Color darkBlue) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            _summary('Archivo', _file?.name ?? 'Sin archivo', darkBlue),
            const Divider(height: 16),
            _summary('Paciente', _nameFor(_patients, _patientId), darkBlue),
            const Divider(height: 16),
            _summary('Tipo de examen', _nameFor(_types, _examTypeId), darkBlue),
            const Divider(height: 16),
            _summary('Nombre', _name.text.trim(), darkBlue),
            const Divider(height: 16),
            _summary('Fecha', _dateValue, darkBlue),
            if (_notes.text.trim().isNotEmpty) ...[
              const Divider(height: 16),
              _summary('Observaciones', _notes.text.trim(), darkBlue),
            ],
          ],
        ),
      );

  Widget _summary(String label, String value, Color darkBlue) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: darkBlue.withOpacity(0.7),
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: darkBlue,
                ),
              ),
            ),
          ],
        ),
      );

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: const Color(0xFF174EA6), size: 20),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF174EA6), width: 1.5),
      ),
    );
  }
}