import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/session.dart';
import 'create_exam_screen.dart';
import 'clinical_results_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({required this.api, required this.session, super.key});

  final ApiClient api;
  final Session session;

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final body = await widget.api.getJson(
        '/exams',
        widget.session.accessToken,
      );
      if (mounted) {
        setState(
          () => _items = List<Map<String, dynamic>>.from(body['items'] as List),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No fue posible cargar los exámenes.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createExam() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreateExamScreen(api: widget.api, session: widget.session),
      ),
    );
    if (created == true) await _load();
  }

  Future<void> _deleteExam(Map<String, dynamic> exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.warning_amber_rounded, size: 36, color: Colors.amber),
        title: const Text('¿Eliminar examen?'),
        content: Text(
          'Se eliminará “${exam['name']}” y su archivo asociado. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    try {
      await widget.api.delete(
        '/exams/${exam['id']}',
        widget.session.accessToken,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examen eliminado correctamente.'),
          backgroundColor: Color(0xFF174EA6),
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF174EA6);
    const darkBlue = Color(0xFF102A43);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la pantalla
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exámenes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestión y consulta de documentos clínicos',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _createExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.upload_file_rounded, size: 20),
                    label: const Text(
                      'Subir examen',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: _load,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryBlue,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contenido principal
          Expanded(child: _content(primaryBlue, darkBlue)),
        ],
      ),
    );
  }

  Widget _content(Color primaryBlue, Color darkBlue) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF174EA6)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 48,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay exámenes registrados',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBlue,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sube un documento clínico en PDF, JPG o PNG para comenzar.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _createExam,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Subir primer examen'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final e = _items[i];
        final hasFile = e['hasFile'] == true;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: hasFile ? primaryBlue.withOpacity(0.12) : Colors.orange.shade50,
              child: Icon(
                hasFile ? Icons.description_rounded : Icons.pending_actions_rounded,
                color: hasFile ? primaryBlue : Colors.orange.shade800,
              ),
            ),
            title: Text(
              e['name'] as String,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: darkBlue,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${e['patientName']}  •  ${e['examTypeName']}  •  ${e['examDate']}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Revisar resultados',
                  onPressed: hasFile ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ClinicalResultsScreen(api: widget.api, session: widget.session, exam: e),
                  )) : null,
                  icon: const Icon(Icons.fact_check_outlined, color: Color(0xFF174EA6)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasFile ? const Color(0xFFE6F4EA) : const Color(0xFFFEF7E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasFile ? 'Disponible' : 'Sin archivo',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: hasFile ? const Color(0xFF137333) : const Color(0xFFB06000),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Eliminar examen',
                  onPressed: () => _deleteExam(e),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
