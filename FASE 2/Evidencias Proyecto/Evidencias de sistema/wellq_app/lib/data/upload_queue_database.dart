import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'upload_queue_database.g.dart';

class ClinicalUploadQueue extends Table {
  TextColumn get ownerId => text()();
  TextColumn get clientUploadId => text()();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get sha256 => text()();
  TextColumn get testType => text()();
  TextColumn get title => text()();
  TextColumn get testDate => text()();
  BlobColumn get fileBytes => blob()();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  TextColumn get uploadId => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {clientUploadId};
}

@DriftDatabase(tables: [ClinicalUploadQueue])
class UploadQueueDatabase extends _$UploadQueueDatabase {
  UploadQueueDatabase()
    : super(
        driftDatabase(
          name: 'wellq_clinical_uploads',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;

  Future<List<ClinicalUploadQueueData>> allUploads({required String ownerId}) =>
      (select(clinicalUploadQueue)
            ..where((row) => row.ownerId.equals(ownerId))
            ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
          .get();

  Future<void> saveUpload(ClinicalUploadQueueCompanion upload) =>
      into(clinicalUploadQueue).insertOnConflictUpdate(upload);

  Future<void> setStatus(
    String clientUploadId, {
    required String status,
    String? uploadId,
    String? error,
    int? attempts,
    DateTime? nextAttemptAt,
  }) async {
    await (update(
      clinicalUploadQueue,
    )..where((row) => row.clientUploadId.equals(clientUploadId))).write(
      ClinicalUploadQueueCompanion(
        status: Value(status),
        uploadId: Value(uploadId),
        lastError: Value(error),
        attempts: attempts == null ? const Value.absent() : Value(attempts),
        nextAttemptAt: Value(nextAttemptAt),
      ),
    );
  }

  Future<void> finishUpload(String clientUploadId) async {
    await (update(
      clinicalUploadQueue,
    )..where((row) => row.clientUploadId.equals(clientUploadId))).write(
      ClinicalUploadQueueCompanion(
        status: Value('complete'),
        fileBytes: Value(Uint8List(0)),
        lastError: Value(null),
        nextAttemptAt: Value(null),
      ),
    );
  }

  Future<void> retryUpload(String clientUploadId) async {
    await (update(
      clinicalUploadQueue,
    )..where((row) => row.clientUploadId.equals(clientUploadId))).write(
      ClinicalUploadQueueCompanion(
        status: Value('queued'),
        lastError: Value(null),
        nextAttemptAt: Value(null),
      ),
    );
  }

  Future<void> close() => super.close();
}
