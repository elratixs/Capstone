import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'clinical_results_screen.dart';
import 'exam_document_screen.dart';

import '../core/api_client.dart';
import '../models/session.dart';

class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({
    required this.patient,
    required this.api,
    required this.session,
    super.key,
  });

  final Map<String, dynamic> patient;
  final ApiClient api;
  final Session session;

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  static const primaryBlue = Color(0xFF174EA6);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _exams = [];

  bool _clinicalLoading = false;
  String? _clinicalError;
  List<Map<String, dynamic>> _clinicalTests = [];

  @override
  void initState() {
    super.initState();
    _loadExams();
    _loadClinicalTests();
  }

  Future<void> _loadExams() async {
    final patientId = widget.patient['id']?.toString();

    if (patientId == null || patientId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No se encontró el identificador interno del paciente.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final body = await widget.api.getJson(
        '/exams?patientId=${Uri.encodeQueryComponent(patientId)}&pageSize=100',
        widget.session.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _exams = List<Map<String, dynamic>>.from(
          body['items'] as List? ?? [],
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No fue posible consultar los exámenes.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadClinicalTests() async {
    final patientId = widget.patient['id']?.toString();

    if (patientId == null || patientId.isEmpty) {
      setState(() {
        _clinicalLoading = false;
        _clinicalError = 'No se encontró el identificador del paciente.';
      });
      return;
    }

    setState(() {
      _clinicalLoading = true;
      _clinicalError = null;
    });

    try {
      final body = await widget.api.getJson(
        '/clinical-tests/patients/${Uri.encodeComponent(patientId)}/clinical-tests',
        widget.session.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _clinicalTests = List<Map<String, dynamic>>.from(
          body['items'] as List? ?? [],
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _clinicalError = e.statusCode == 403
            ? 'No tienes autorización clínica para consultar este paciente.'
            : e.message;
        _clinicalTests = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clinicalError = 'No fue posible consultar los documentos clínicos.';
        _clinicalTests = [];
      });
    } finally {
      if (mounted) {
        setState(() => _clinicalLoading = false);
      }
    }
  }
  Widget _field(String label, String key) {
    final value = widget.patient[key]?.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            value == null || value.isEmpty
                ? 'No registrado'
                : value,
          ),
        ],
      ),
    );
  }

  Widget _examsSection() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadExams,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_exams.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Este paciente aún no tiene exámenes registrados.',
        ),
      );
    }

    return Column(
      children: _exams.map((exam) {
        final name = exam['name']?.toString() ?? 'Examen sin nombre';
        final type = exam['examTypeName']?.toString() ?? 'Sin tipo';
        final date = exam['examDate']?.toString() ?? 'Sin fecha';

        final hasFile = exam['hasFile'] == true;

        return ListTile(
          leading: const Icon(
            Icons.description_outlined,
            color: primaryBlue,
          ),
          title: Text(name),
          subtitle: Text('$type · $date'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: hasFile ? 'Ver documento' : 'Examen sin archivo',
                icon: const Icon(Icons.visibility_outlined),
                onPressed: hasFile
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ExamDocumentScreen(
                              api: widget.api,
                              session: widget.session,
                              exam: exam,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
              IconButton(
            tooltip: hasFile
                ? 'Revisar resultados'
                : 'Examen sin archivo',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: hasFile
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClinicalResultsScreen(
                          api: widget.api,
                          session: widget.session,
                          exam: exam,
                        ),
                      ),
                    );
                  }
                : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _openClinicalDocument(
    Map<String, dynamic> test, {
    required bool download,
  }) async {
    if (test['status']?.toString() != 'ready_for_review') return;

    final id = test['clinical_test_id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      final result = await widget.api.clinicalTestDownloadUrl(
        id,
        widget.session.accessToken,
        disposition: download ? 'attachment' : 'inline',
      );

      final url = result['url']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('URL del documento no disponible.');
      }

      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('No fue posible abrir el documento.');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            download
                ? 'No fue posible descargar el documento.'
                : 'No fue posible abrir el documento.',
          ),
        ),
      );
    }
  }

  Widget _clinicalSection() {
    if (_clinicalLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_clinicalError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _clinicalError!,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loadClinicalTests,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_clinicalTests.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No hay documentos clínicos registrados.'),
      );
    }

    return Column(
      children: _clinicalTests.map((test) {
        final title = test['title']?.toString() ?? 'Documento sin nombre';
        final type = test['test_type']?.toString() ?? 'Sin tipo';
        final status = test['status']?.toString() ?? 'Sin estado';

        return ListTile(
          leading: const Icon(
            Icons.medical_information_outlined,
            color: primaryBlue,
          ),
          title: Text(title),
          subtitle: Text(
            '$type · ${status == 'ready_for_review' ? 'Listo para revisión' : 'Pendiente'}',
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Visualizar documento',
                icon: const Icon(Icons.visibility_outlined),
                onPressed: status == 'ready_for_review'
                    ? () => _openClinicalDocument(test, download: false)
                    : null,
              ),
              IconButton(
                tooltip: 'Descargar documento',
                icon: const Icon(Icons.download_outlined),
                onPressed: status == 'ready_for_review'
                    ? () => _openClinicalDocument(test, download: true)
                    : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  @override
  Widget build(BuildContext context) {
    final name = widget.patient['name']?.toString() ?? 'Sin nombre';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha del paciente'),
        foregroundColor: Colors.white,
        backgroundColor: primaryBlue,
      ),
      backgroundColor: const Color(0xFFF4F7FB),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 48,
                        color: primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(height: 32),
                      _field('Identificador / RUT', 'identifier'),
                      _field('Correo electrónico', 'email'),
                      _field('Teléfono', 'phone'),
                      _field('Fecha de nacimiento', 'birthDate'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Exámenes del paciente',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Actualizar exámenes',
                            onPressed: _loading ? null : _loadExams,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _examsSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Documentos enviados por el paciente',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Actualizar documentos clínicos',
                            onPressed: _clinicalLoading
                                ? null
                                : _loadClinicalTests,
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _clinicalSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}







