import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/session.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({required this.api, required this.session, super.key});

  final ApiClient api;
  final Session session;

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  late Future<List<Map<String, dynamic>>> _events;

  @override
  void initState() {
    super.initState();
    _events = _loadEvents();
  }

  Future<List<Map<String, dynamic>>> _loadEvents() async {
    final result = await widget.api.getJson(
      '/audit?page=1&pageSize=50',
      widget.session.accessToken,
    );
    return (result['items'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void _refresh() => setState(() => _events = _loadEvents());

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Fecha no disponible';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} · $hour:$minute';
  }

  String _actionLabel(String action) => switch (action) {
    'LOGIN' => 'Inicio de sesión',
    'VIEW_EXAM' => 'Consulta de examen',
    'UPLOAD_EXAM' => 'Carga de examen',
    'DOWNLOAD_EXAM' => 'Descarga de examen',
    'DELETE_EXAM' => 'Eliminación de examen',
    'UPDATE_EXAM' => 'Actualización de examen',
    'CREATE_EXAM' => 'Creación de examen',
    _ => action.replaceAll('.', ' '),
  };

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auditoría', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
                    SizedBox(height: 6),
                    Text('Actividad reciente registrada para tu clínica.', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              IconButton(onPressed: _refresh, tooltip: 'Actualizar', icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _events,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                final message = snapshot.error is ApiException && (snapshot.error as ApiException).statusCode == 403
                    ? 'Tu usuario no tiene permiso para consultar la auditoría.'
                    : 'No se pudo cargar la auditoría. Intenta nuevamente.';
                return _MessageCard(message: message, onRetry: _refresh);
              }
              final events = snapshot.data ?? const [];
              if (events.isEmpty) return const _MessageCard(message: 'Todavía no hay eventos registrados.');
              return Column(
                children: events.map((event) {
                  final successful = event['success'] == true;
                  final action = event['action']?.toString() ?? 'Evento';
                  final resource = event['resource_type']?.toString() ?? 'recurso';
                  final resourceId = event['resource_id']?.toString();
                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: successful ? const Color(0xFFE8F5EE) : const Color(0xFFFFECEC),
                        child: Icon(successful ? Icons.verified_user_outlined : Icons.warning_amber_rounded, color: successful ? const Color(0xFF16804A) : const Color(0xFFB42318)),
                      ),
                      title: Text(_actionLabel(action), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF102A43))),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text('${_dateLabel(event['occurred_at'])}  ·  $resource${resourceId == null ? '' : ' · ${resourceId.substring(0, 8)}'}', style: const TextStyle(color: Color(0xFF64748B))),
                      ),
                      trailing: Text('${event['status_code'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ],
      ),
    ),
  );
}
