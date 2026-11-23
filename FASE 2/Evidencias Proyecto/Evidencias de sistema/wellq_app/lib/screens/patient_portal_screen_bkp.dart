import 'appointment_booking_screen.dart';
import 'dart:async';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api_client.dart';
import '../data/upload_queue_database.dart';
import '../models/session.dart';

class PatientPortalScreen extends StatefulWidget {
  const PatientPortalScreen({
    required this.api,
    required this.session,
    required this.onLogout,
    super.key,
  });
  final ApiClient api;
  final Session session;
  final VoidCallback onLogout;
  @override
  State<PatientPortalScreen> createState() => _PatientPortalScreenState();
}

class _PatientPortalScreenState extends State<PatientPortalScreen>
    with WidgetsBindingObserver {
  static const navy = Color(0xFF17324D),
      blue = Color(0xFF2563EB),
      teal = Color(0xFF0F766E),
      muted = Color(0xFF64748B),
      canvas = Color(0xFFF4F7FB);
  final _title = TextEditingController(),
      _type = TextEditingController(text: 'Laboratorio');
  int _selectedSection = 0;
  bool _loading = true, _sending = false;
  String? _error;
  List<Map<String, dynamic>> _tests = [];
  UploadQueueDatabase? _queueDb;
  Timer? _retryTimer;
  bool _syncingQueue = false;
  List<ClinicalUploadQueueData> _queuedUploads = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _openQueue();
    _retryTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncQueue(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncQueue();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    _queueDb?.close();
    _title.dispose();
    _type.dispose();
    super.dispose();
  }

  String _uuid() {
    final r = Random.secure(),
        b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return h.substring(0, 8) +
        '-' +
        h.substring(8, 12) +
        '-' +
        h.substring(12, 16) +
        '-' +
        h.substring(16, 20) +
        '-' +
        h.substring(20);
  }

  Future<void> _load() async {
    if (mounted) setState(() => {_loading = true, _error = null});
    try {
      final v = await widget.api.listClinicalTests(widget.session.accessToken);
      if (mounted)
        setState(
          () => _tests = List<Map<String, dynamic>>.from(
            v['items'] as List? ?? [],
          ),
        );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted)
        setState(() => _error = 'No fue posible cargar tus exámenes.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openQueue() async {
    final ownerId = widget.session.userId;
    if (ownerId == null) {
      if (mounted)
        setState(() => _error = 'No se pudo verificar la cuenta del paciente.');
      return;
    }
    final db = UploadQueueDatabase();
    await db.allUploads(ownerId: ownerId);
    if (!mounted) {
      await db.close();
      return;
    }
    setState(() => _queueDb = db);
    await _refreshQueue();
    await _syncQueue();
  }

  Future<void> _refreshQueue() async {
    final db = _queueDb;
    final ownerId = widget.session.userId;
    if (db == null || ownerId == null) return;
    final rows = await db.allUploads(ownerId: ownerId);
    if (mounted) {
      setState(
        () => _queuedUploads = rows
            .where((row) => row.status != 'complete')
            .toList(),
      );
    }
  }

  Future<void> _syncQueue() async {
    final db = _queueDb;
    final ownerId = widget.session.userId;
    if (db == null || ownerId == null || _syncingQueue) return;
    _syncingQueue = true;
    try {
      final rows = await db.allUploads(ownerId: ownerId);
      final now = DateTime.now();
      for (final row in rows) {
        if (row.status == 'complete' || row.status == 'rejected') continue;
        if (row.nextAttemptAt != null && row.nextAttemptAt!.isAfter(now))
          continue;
        await _syncUpload(row);
      }
    } finally {
      _syncingQueue = false;
      await _refreshQueue();
    }
  }

  Future<void> _syncUpload(ClinicalUploadQueueData item) async {
    final db = _queueDb!;
    try {
      if (item.uploadId != null) {
        final remote = await widget.api.clinicalTestStatus(
          item.uploadId!,
          widget.session.accessToken,
        );
        final remoteStatus = remote['status'] as String?;
        if (remoteStatus == 'ready_for_review' &&
            remote['local_file_can_be_deleted'] == true) {
          await db.finishUpload(item.clientUploadId);
          await _load();
          return;
        }
        if (remoteStatus == 'processing' || remoteStatus == 'object_uploaded') {
          await db.setStatus(
            item.clientUploadId,
            status: 'processing',
            uploadId: item.uploadId,
            attempts: item.attempts,
          );
          return;
        }
        if (remoteStatus == 'rejected') {
          await db.setStatus(
            item.clientUploadId,
            status: 'rejected',
            uploadId: item.uploadId,
            error: 'El documento no superó la validación de seguridad.',
          );
          return;
        }
      }

      await db.setStatus(
        item.clientUploadId,
        status: 'uploading',
        uploadId: item.uploadId,
        attempts: item.attempts,
      );
      final started = await widget.api.initiateClinicalTest(
        token: widget.session.accessToken,
        clientUploadId: item.clientUploadId,
        fileName: item.fileName,
        mimeType: item.mimeType,
        sizeBytes: item.sizeBytes,
        sha256: item.sha256,
        testType: item.testType,
        title: item.title,
        testDate: item.testDate,
      );
      final uploadId = started['upload_id'] as String;
      await db.setStatus(
        item.clientUploadId,
        status: 'uploading',
        uploadId: uploadId,
        attempts: item.attempts,
      );
      var upload = Map<String, dynamic>.from(started['upload'] as Map);
      try {
        await widget.api.putSignedFile(
          upload['signed_url'] as String,
          Map<String, dynamic>.from(upload['required_headers'] as Map),
          item.fileBytes,
        );
      } catch (_) {
        final refreshed = await widget.api.refreshClinicalTestUploadUrl(
          token: widget.session.accessToken,
          uploadId: uploadId,
          clientUploadId: item.clientUploadId,
          sha256: item.sha256,
        );
        upload = Map<String, dynamic>.from(refreshed['upload'] as Map);
        await widget.api.putSignedFile(
          upload['signed_url'] as String,
          Map<String, dynamic>.from(upload['required_headers'] as Map),
          item.fileBytes,
        );
      }

      await widget.api.completeClinicalTest(
        token: widget.session.accessToken,
        uploadId: uploadId,
        clientUploadId: item.clientUploadId,
        sha256: item.sha256,
        sizeBytes: item.sizeBytes,
      );
      await db.setStatus(
        item.clientUploadId,
        status: 'processing',
        uploadId: uploadId,
        attempts: item.attempts,
      );
      final state = await widget.api.clinicalTestStatus(
        uploadId,
        widget.session.accessToken,
      );
      if (state['status'] == 'ready_for_review' &&
          state['local_file_can_be_deleted'] == true) {
        await db.finishUpload(item.clientUploadId);
        await _load();
      }
    } catch (_) {
      final attempts = item.attempts + 1;
      final delay = min(3600, 15 * (1 << min(attempts, 8)));
      await db.setStatus(
        item.clientUploadId,
        status: 'queued',
        uploadId: item.uploadId,
        error: 'No se pudo sincronizar. Se reintentará automáticamente.',
        attempts: attempts,
        nextAttemptAt: DateTime.now().add(Duration(seconds: delay)),
      );
    }
  }

  Future<void> _retryQueuedUpload(String clientUploadId) async {
    await _queueDb?.retryUpload(clientUploadId);
    await _refreshQueue();
    await _syncQueue();
  }

  String _queuedStatus(ClinicalUploadQueueData item) {
    if (item.status == 'uploading') return 'Enviando de forma segura';
    if (item.status == 'processing') return 'Validando documento';
    if (item.status == 'rejected') return 'No se pudo validar';
    if (item.lastError != null) return 'En espera de conexión para reintentar';
    return 'Guardado en este dispositivo';
  }

  Widget _queueSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Cargas pendientes',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: navy,
        ),
      ),
      const SizedBox(height: 10),
      ..._queuedUploads.map(
        (item) => Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_upload_outlined, color: blue),
            title: Text(item.title),
            subtitle: Text(item.fileName + ' · ' + _queuedStatus(item)),
            trailing: item.status == 'rejected'
                ? const Icon(Icons.error_outline, color: Color(0xFFB45309))
                : item.status == 'queued'
                ? IconButton(
                    tooltip: 'Reintentar ahora',
                    onPressed: () => _retryQueuedUpload(item.clientUploadId),
                    icon: const Icon(Icons.sync_rounded),
                  )
                : const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
        ),
      ),
    ],
  );

  Future<void> _upload() async {
    if (_title.text.trim().isEmpty || _type.text.trim().isEmpty) {
      setState(() => _error = 'Completa el nombre y tipo del examen.');
      return;
    }
    final db = _queueDb;
    final ownerId = widget.session.userId;
    if (db == null || ownerId == null) {
      setState(() => _error = 'La cola local todavía se está preparando.');
      return;
    }
    final picked = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic'],
    );
    if (picked == null || picked.isEmpty) return;
    final file = picked.first;
    final extension = file.name.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      _ => null,
    };
    final bytes = await file.readAsBytes();
    if (mime == null || bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
      setState(() => _error = 'Archivo no válido o supera el límite de 20 MB.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    final checksum = sha256.convert(bytes).toString();
    final clientUploadId = _uuid();
    await db.saveUpload(
      ClinicalUploadQueueCompanion.insert(
        ownerId: ownerId,
        clientUploadId: clientUploadId,
        fileName: file.name,
        mimeType: mime,
        sizeBytes: bytes.length,
        sha256: checksum,
        testType: _type.text.trim(),
        title: _title.text.trim(),
        testDate: DateTime.now().toIso8601String().substring(0, 10),
        fileBytes: bytes,
      ),
    );
    _title.clear();
    await _refreshQueue();
    await _syncQueue();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Examen guardado. Se sincronizará al recuperar la conexión.',
          ),
        ),
      );
      setState(() => _sending = false);
    }
  }

  String _status(String? s) => switch (s) {
    'initiated' => 'Carga iniciada',
    'processing' => 'Validando documento',
    'ready_for_review' => 'Recibido por tu clínica',
    'failed' => 'Necesita revisión',
    'rejected' => 'No se pudo validar',
    _ => 'En revisión',
  };
  Color _statusColor(String? s) => switch (s) {
    'ready_for_review' => teal,
    'failed' || 'rejected' => const Color(0xFFB45309),
    _ => blue,
  };
  Future<void> _preview(Map<String, dynamic> row) async {
    final extension = (row['file_name'] ?? '')
        .toString()
        .split('.')
        .last
        .toLowerCase();

    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vista previa disponible para imágenes JPEG y PNG.'),
        ),
      );
      return;
    }

    try {
      final result = await widget.api.clinicalTestDownloadUrl(
        row['clinical_test_id'].toString(),
        widget.session.accessToken,
      );

      final url = result['url']?.toString();

      if (url == null || url.isEmpty) {
        throw Exception('URL no disponible');
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 950,
              maxHeight: 750,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(row['title']?.toString() ?? 'Radiografía'),
                  trailing: IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 5,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No fue posible visualizar la imagen.',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible abrir la vista previa del examen.'),
        ),
      );
    }
  }
  Future<void> _download(Map<String, dynamic> row) async {
    try {
      final v = await widget.api.clinicalTestDownloadUrl(
        row['clinical_test_id'].toString(),
        widget.session.accessToken,
      );
      await launchUrl(
        Uri.parse(v['url'] as String),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento aún no disponible para descarga.'),
          ),
        );
    }
  }

  void _openAppointmentBooking() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AppointmentBookingScreen(),
      ),
    );
  }
  Widget _navigationMenu() => Container(
    width: 250,
    color: Colors.white,
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'MI WELLQ',
            style: TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Divider(),
        _navigationItem(0, Icons.home_outlined, 'Inicio'),
        ListTile(
          leading: const Icon(
            Icons.calendar_month_outlined,
            color: blue,
          ),
          title: const Text('Reserva de Hora'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: _openAppointmentBooking,
        ),
        _navigationItem(1, Icons.science_outlined, 'Mis exámenes'),
        _navigationItem(2, Icons.upload_file_outlined, 'Compartir documentos'),
        const Spacer(),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: navy),
          title: const Text('Cerrar sesión'),
          onTap: widget.onLogout,
        ),
      ],
    ),
  );

  Widget _navigationItem(int index, IconData icon, String label) {
    final selected = _selectedSection == index;

    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFEAF2FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: Icon(
        icon,
        color: selected ? blue : muted,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? blue : navy,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: () {
        setState(() => _selectedSection = index);
      },
    );
  }
  Widget _brand() => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFE8F0FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.favorite_rounded, color: blue, size: 22),
  );
  Widget _metric(String value, String label, IconData icon, Color color) =>
      Container(
        constraints: const BoxConstraints(minWidth: 158),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6ECF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: navy,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ],
        ),
      );
  Widget _uploadCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE6ECF3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.upload_file_rounded, color: blue),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparte un examen',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: navy,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Lo recibirá tu equipo de salud',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _title,
          style: const TextStyle(color: navy),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            labelStyle: TextStyle(color: muted),
            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
            labelText: 'Nombre del examen',
            hintText: 'Ej. Hemograma completo',
            prefixIcon: Icon(Icons.description_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _type,
          style: const TextStyle(color: navy),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            labelStyle: TextStyle(color: muted),
            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
            labelText: 'Tipo',
            hintText: 'Laboratorio, imagenología…',
            prefixIcon: Icon(Icons.category_outlined),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _sending ? null : _upload,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add_to_drive_outlined),
            label: Text(
              _sending ? 'Enviando de forma segura…' : 'Elegir documento',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: blue,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: muted),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'PDF o imagen · hasta 20 MB · conexión segura',
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  Widget _empty() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 22),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6ECF3)),
    ),
    child: const Column(
      children: [
        Icon(Icons.folder_open_rounded, size: 40, color: Color(0xFF94A3B8)),
        SizedBox(height: 12),
        Text(
          'Tu espacio está listo',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Cuando compartas un examen, podrás seguir aquí su recepción y revisión.',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, height: 1.4),
        ),
      ],
    ),
  );
  Widget _testCard(Map<String, dynamic> row) {
    final s = row['status'] as String?,
        c = _statusColor(s),
        ready = s == 'ready_for_review';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              row['mime_type'] == 'application/pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              color: muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row['title']?.toString() ?? 'Examen',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (row['test_type'] ?? 'Documento').toString() +
                      ' · ' +
                      (row['test_date'] ?? '').toString(),
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ready
                            ? Icons.check_circle_outline
                            : Icons.schedule_rounded,
                        size: 14,
                        color: c,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _status(s),
                        style: TextStyle(
                          fontSize: 11,
                          color: c,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (ready) ...[
            if (['jpg', 'jpeg', 'png'].contains(
                  (row['file_name'] ?? '').toString().split('.').last.toLowerCase()))
              IconButton(
                tooltip: 'Visualizar',
                onPressed: () => _preview(row),
                icon: const Icon(Icons.visibility_outlined, color: teal),
              ),
            IconButton(
              tooltip: 'Descargar',
              onPressed: () => _download(row),
              icon: const Icon(Icons.download_rounded, color: blue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _results() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis exámenes',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: navy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Consulta el avance de tus documentos',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_tests.isNotEmpty)
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.sync_rounded, size: 16),
                label: const Text('Actualizar'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_tests.isEmpty)
          _empty()
        else
          ..._tests.map(_testCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.session.userName.trim().split(RegExp(r'\s+')).first,
        wide = MediaQuery.sizeOf(context).width >= 960;
    final ready = _tests.where((t) => t['status'] == 'ready_for_review').length,
        pending = _tests.length - ready;
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 24,
        title: Row(
          children: [
            _brand(),
            const SizedBox(width: 10),
            const Text(
              'WellQ',
              style: TextStyle(
                color: navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
            const SizedBox(width: 14),
            const Text(
              'Mi espacio de salud',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: muted),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18, left: 4),
            child: PopupMenuButton<String>(
              tooltip: 'Cuenta',
              onSelected: (_) => widget.onLogout(),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE8F0FF),
                child: Text(
                  first.isEmpty ? 'W' : first[0].toUpperCase(),
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (wide) _navigationMenu(),
          Expanded(
            child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 34 : 18,
              vertical: 28,
            ),
            children: [
              Container(
                padding: EdgeInsets.all(wide ? 28 : 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF17324D), Color(0xFF245A78)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18243B53),
                      blurRadius: 24,
                      offset: Offset(0, 9),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'TU SALUD, MÁS CERCA',
                              style: TextStyle(
                                color: Color(0xFFD9F4F0),
                                fontSize: 10,
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Hola, $first',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: wide ? 27 : 23,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Comparte tus exámenes y sigue su estado con tu clínica.',
                            style: TextStyle(
                              color: Color(0xFFD8E4EC),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (wide)
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          size: 39,
                          color: Color(0xFFD9F4F0),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metric(
                    _tests.length.toString(),
                    'Exámenes compartidos',
                    Icons.folder_copy_outlined,
                    blue,
                  ),
                  _metric(
                    pending.toString(),
                    'En revisión',
                    Icons.pending_actions_rounded,
                    const Color(0xFFB7791F),
                  ),
                  _metric(
                    ready.toString(),
                    'Recibidos',
                    Icons.verified_outlined,
                    teal,
                  ),
                ],
              ),
              if (_queuedUploads.isNotEmpty) ...[
                const SizedBox(height: 22),
                _queueSection(),
              ],
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 18),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB42318)),
                  ),
                ),
              SizedBox(height: wide ? 26 : 22),
              if (_selectedSection == 0) ...[
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: _results()),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: _uploadCard()),
                    ],
                  )
                else ...[
                  _uploadCard(),
                  const SizedBox(height: 24),
                  _results(),
                ],
              ] else if (_selectedSection == 1) ...[
                _results(),
              ] else if (_selectedSection == 2) ...[
                _uploadCard(),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 17, color: teal),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Tus documentos se comparten de forma segura con tu clínica. La interpretación la realiza tu equipo de salud.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
            ),
          ],
        ),
    );
  }
}
