import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/session.dart';

class ClinicalResultsScreen extends StatefulWidget {
  const ClinicalResultsScreen({
    required this.api,
    required this.session,
    required this.exam,
    super.key,
  });

  final ApiClient api;
  final Session session;
  final Map<String, dynamic> exam;

  @override
  State<ClinicalResultsScreen> createState() => _ClinicalResultsScreenState();
}

class _ClinicalResultsScreenState extends State<ClinicalResultsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _status = 'not_started';
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final body = await widget.api.getJson(
        '/exams/${widget.exam['id']}/results', widget.session.accessToken,
      );
      final results = Map<String, dynamic>.from(body['results'] as Map);
      if (!mounted) return;
      setState(() {
        _entries = List<Map<String, dynamic>>.from(results['entries'] as List? ?? []);
        _status = results['status'] as String? ?? 'not_started';
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No fue posible cargar la revisión.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addEntry() async {
    final fields = List.generate(5, (_) => TextEditingController());
    final formKey = GlobalKey<FormState>();
    final entry = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Transcribir resultado'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(fields[0], 'Código del marcador', required: true),
                _field(fields[1], 'Nombre tal como aparece', required: true),
                _field(fields[2], 'Valor tal como aparece', required: true),
                _field(fields[3], 'Unidad', required: false),
                _field(fields[4], 'Rango de referencia', required: false),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(dialogContext, {
                'markerCode': fields[0].text.trim(),
                'markerName': fields[1].text.trim(),
                'rawValue': fields[2].text.trim(),
                'rawUnit': fields[3].text.trim().isEmpty ? null : fields[3].text.trim(),
                'referenceRange': fields[4].text.trim().isEmpty ? null : fields[4].text.trim(),
              });
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
    for (final field in fields) { field.dispose(); }
    if (entry == null) return;
    setState(() => _entries = [..._entries, entry]);
  }

  Widget _field(TextEditingController controller, String label, {required bool required}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: required ? (value) => (value?.trim().isEmpty ?? true) ? 'Completa este campo.' : null : null,
    ),
  );

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final body = await widget.api.putJson(
        '/exams/${widget.exam['id']}/results', widget.session.accessToken,
        {'entries': _entries},
      );
      final results = Map<String, dynamic>.from(body['results'] as Map);
      if (!mounted) return;
      setState(() {
        _entries = List<Map<String, dynamic>>.from(results['entries'] as List? ?? []);
        _status = results['status'] as String? ?? 'awaiting_patient_confirmation';
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transcripción guardada.')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'No fue posible guardar la transcripción.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFEEF3F9),
    appBar: AppBar(
      title: const Text('Revisión de resultados'),
      backgroundColor: Colors.white,
      actions: [
        TextButton.icon(onPressed: _loading || _saving ? null : _addEntry, icon: const Icon(Icons.add), label: const Text('Agregar marcador')),
        const SizedBox(width: 8),
        FilledButton.icon(onPressed: _saving || _loading ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('Guardar')),
        const SizedBox(width: 16),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(24), children: [
            Text('${widget.exam['patientName']} · ${widget.exam['name']}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFFFF7E6),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Transcripción manual. Los datos quedan pendientes de confirmación del paciente y validación clínica. No se calcula ni se muestra un puntaje clínico.'),
              ),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 8),
            Text('Estado: ${_status == 'not_started' ? 'Sin transcripción' : _status == 'awaiting_patient_confirmation' ? 'Pendiente de confirmación del paciente' : _status}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_entries.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Aún no hay marcadores transcritos. Agrega los valores exactamente como aparecen en el documento.')))
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(columns: const [
                    DataColumn(label: Text('Código')), DataColumn(label: Text('Marcador')),
                    DataColumn(label: Text('Valor original')), DataColumn(label: Text('Unidad')),
                    DataColumn(label: Text('Rango de referencia')),
                  ], rows: _entries.map((item) => DataRow(cells: [
                    DataCell(Text('${item['markerCode'] ?? ''}')),
                    DataCell(Text('${item['markerName'] ?? ''}')),
                    DataCell(Text('${item['rawValue'] ?? ''}')),
                    DataCell(Text('${item['rawUnit'] ?? '—'}')),
                    DataCell(Text('${item['referenceRange'] ?? '—'}')),
                  ])).toList()),
                ),
              ),
          ]),
  );
}
