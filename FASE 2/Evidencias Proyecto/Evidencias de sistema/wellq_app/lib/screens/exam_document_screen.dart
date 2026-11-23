import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_saver/file_saver.dart';

import '../core/api_client.dart';
import '../models/session.dart';

class ExamDocumentScreen extends StatefulWidget {
  const ExamDocumentScreen({
    super.key,
    required this.api,
    required this.session,
    required this.exam,
  });

  final ApiClient api;
  final Session session;
  final Map<String, dynamic> exam;

  @override
  State<ExamDocumentScreen> createState() => _ExamDocumentScreenState();
}

class _ExamDocumentScreenState extends State<ExamDocumentScreen> {
  Uint8List? _bytes;
  String? _mimeType;
  String? _error;
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final examId = widget.exam['id']?.toString();

      if (examId == null || examId.isEmpty) {
        throw const ApiException('Identificador del examen no disponible.');
      }

      final response = await widget.api.getExamFile(
        examId,
        widget.session.accessToken,
      );

      if (!mounted) return;

      setState(() {
        _bytes = response.bodyBytes;
        _mimeType = (response.headers['content-type'] ?? '')
            .split(';')
            .first
            .trim()
            .toLowerCase();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error is ApiException
            ? error.message
            : 'No fue posible visualizar el documento.';
      });
    }
  }

  Future<void> _downloadDocument() async {
    if (_downloading) return;

    setState(() => _downloading = true);

    try {
      final examId = widget.exam['id']?.toString();

      if (examId == null || examId.isEmpty) {
        throw const ApiException('Identificador del examen no disponible.');
      }

      final response = await widget.api.getExamFile(
        examId,
        widget.session.accessToken,
        download: true,
      );

      final contentType = (response.headers['content-type'] ?? '')
          .split(';')
          .first
          .trim()
          .toLowerCase();

      final String extension;
      final MimeType mimeType;

      switch (contentType) {
        case 'application/pdf':
          extension = 'pdf';
          mimeType = MimeType.pdf;
          break;
        case 'image/jpeg':
          extension = 'jpg';
          mimeType = MimeType.jpeg;
          break;
        case 'image/png':
          extension = 'png';
          mimeType = MimeType.png;
          break;
        default:
          throw const ApiException('Formato de documento no compatible.');
      }

      final disposition = response.headers['content-disposition'] ?? '';
      String? originalName;

      final encodedMatch = RegExp(
        r"filename\*\s*=\s*UTF-8''([^;]+)",
        caseSensitive: false,
      ).firstMatch(disposition);

      if (encodedMatch != null) {
        try {
          originalName = Uri.decodeComponent(encodedMatch.group(1)!);
        } catch (_) {
          originalName = null;
        }
      }

      originalName ??= RegExp(
        r'filename\s*=\s*"?([^";]+)"?',
        caseSensitive: false,
      ).firstMatch(disposition)?.group(1);

      final safeName = (originalName ?? 'examen_$examId')
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '_')
          .trim();

      final baseName = safeName
          .replaceFirst(RegExp(r'\.[^.]+$'), '')
          .trim();

      await FileSaver.instance.saveFile(
        name: baseName.isEmpty ? 'documento_examen' : baseName,
        bytes: response.bodyBytes,
        fileExtension: extension,
        mimeType: mimeType,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descarga iniciada correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error is ApiException
          ? error.statusCode == 403
              ? 'No tienes autorización para descargar este documento.'
              : error.message
          : 'No fue posible descargar el documento.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final examName =
        widget.exam['name']?.toString() ?? 'Documento del examen';

    return Scaffold(
      appBar: AppBar(
        title: Text(examName),
        actions: [
          if (_downloading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Descargar documento',
              icon: const Icon(Icons.download_outlined),
              onPressed: !_loading && _error == null && _bytes != null
                  ? _downloadDocument
                  : null,
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDocument,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final bytes = _bytes;

    if (bytes == null || bytes.isEmpty) {
      return const Center(
        child: Text('El documento está vacío.'),
      );
    }

    if (_mimeType == 'application/pdf') {
      return PdfViewer.data(
        bytes,
        sourceName: 'Documento del examen',
      );
    }

    if (_mimeType == 'image/jpeg' || _mimeType == 'image/png') {
      return Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.memory(bytes),
        ),
      );
    }

    return const Center(
      child: Text('Formato de documento no compatible.'),
    );
  }

  @override
  void dispose() {
    _bytes = null;
    super.dispose();
  }
}





