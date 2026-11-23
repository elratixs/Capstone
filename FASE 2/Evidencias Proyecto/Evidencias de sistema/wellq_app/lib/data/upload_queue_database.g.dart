// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_queue_database.dart';

// ignore_for_file: type=lint
class $ClinicalUploadQueueTable extends ClinicalUploadQueue
    with TableInfo<$ClinicalUploadQueueTable, ClinicalUploadQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClinicalUploadQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientUploadIdMeta = const VerificationMeta(
    'clientUploadId',
  );
  @override
  late final GeneratedColumn<String> clientUploadId = GeneratedColumn<String>(
    'client_upload_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _testTypeMeta = const VerificationMeta(
    'testType',
  );
  @override
  late final GeneratedColumn<String> testType = GeneratedColumn<String>(
    'test_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _testDateMeta = const VerificationMeta(
    'testDate',
  );
  @override
  late final GeneratedColumn<String> testDate = GeneratedColumn<String>(
    'test_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileBytesMeta = const VerificationMeta(
    'fileBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> fileBytes = GeneratedColumn<Uint8List>(
    'file_bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _uploadIdMeta = const VerificationMeta(
    'uploadId',
  );
  @override
  late final GeneratedColumn<String> uploadId = GeneratedColumn<String>(
    'upload_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    clientUploadId,
    fileName,
    mimeType,
    sizeBytes,
    sha256,
    testType,
    title,
    testDate,
    fileBytes,
    status,
    uploadId,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clinical_upload_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClinicalUploadQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('client_upload_id')) {
      context.handle(
        _clientUploadIdMeta,
        clientUploadId.isAcceptableOrUnknown(
          data['client_upload_id']!,
          _clientUploadIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientUploadIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('test_type')) {
      context.handle(
        _testTypeMeta,
        testType.isAcceptableOrUnknown(data['test_type']!, _testTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_testTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('test_date')) {
      context.handle(
        _testDateMeta,
        testDate.isAcceptableOrUnknown(data['test_date']!, _testDateMeta),
      );
    } else if (isInserting) {
      context.missing(_testDateMeta);
    }
    if (data.containsKey('file_bytes')) {
      context.handle(
        _fileBytesMeta,
        fileBytes.isAcceptableOrUnknown(data['file_bytes']!, _fileBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_fileBytesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('upload_id')) {
      context.handle(
        _uploadIdMeta,
        uploadId.isAcceptableOrUnknown(data['upload_id']!, _uploadIdMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientUploadId};
  @override
  ClinicalUploadQueueData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClinicalUploadQueueData(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      clientUploadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_upload_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      testType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}test_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      testDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}test_date'],
      )!,
      fileBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}file_bytes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      uploadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upload_id'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ClinicalUploadQueueTable createAlias(String alias) {
    return $ClinicalUploadQueueTable(attachedDatabase, alias);
  }
}

class ClinicalUploadQueueData extends DataClass
    implements Insertable<ClinicalUploadQueueData> {
  final String ownerId;
  final String clientUploadId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
  final String testType;
  final String title;
  final String testDate;
  final Uint8List fileBytes;
  final String status;
  final String? uploadId;
  final int attempts;
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  const ClinicalUploadQueueData({
    required this.ownerId,
    required this.clientUploadId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    required this.testType,
    required this.title,
    required this.testDate,
    required this.fileBytes,
    required this.status,
    this.uploadId,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    map['client_upload_id'] = Variable<String>(clientUploadId);
    map['file_name'] = Variable<String>(fileName);
    map['mime_type'] = Variable<String>(mimeType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['sha256'] = Variable<String>(sha256);
    map['test_type'] = Variable<String>(testType);
    map['title'] = Variable<String>(title);
    map['test_date'] = Variable<String>(testDate);
    map['file_bytes'] = Variable<Uint8List>(fileBytes);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || uploadId != null) {
      map['upload_id'] = Variable<String>(uploadId);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ClinicalUploadQueueCompanion toCompanion(bool nullToAbsent) {
    return ClinicalUploadQueueCompanion(
      ownerId: Value(ownerId),
      clientUploadId: Value(clientUploadId),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      sha256: Value(sha256),
      testType: Value(testType),
      title: Value(title),
      testDate: Value(testDate),
      fileBytes: Value(fileBytes),
      status: Value(status),
      uploadId: uploadId == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadId),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory ClinicalUploadQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClinicalUploadQueueData(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      clientUploadId: serializer.fromJson<String>(json['clientUploadId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      sha256: serializer.fromJson<String>(json['sha256']),
      testType: serializer.fromJson<String>(json['testType']),
      title: serializer.fromJson<String>(json['title']),
      testDate: serializer.fromJson<String>(json['testDate']),
      fileBytes: serializer.fromJson<Uint8List>(json['fileBytes']),
      status: serializer.fromJson<String>(json['status']),
      uploadId: serializer.fromJson<String?>(json['uploadId']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'clientUploadId': serializer.toJson<String>(clientUploadId),
      'fileName': serializer.toJson<String>(fileName),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'sha256': serializer.toJson<String>(sha256),
      'testType': serializer.toJson<String>(testType),
      'title': serializer.toJson<String>(title),
      'testDate': serializer.toJson<String>(testDate),
      'fileBytes': serializer.toJson<Uint8List>(fileBytes),
      'status': serializer.toJson<String>(status),
      'uploadId': serializer.toJson<String?>(uploadId),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ClinicalUploadQueueData copyWith({
    String? ownerId,
    String? clientUploadId,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    String? sha256,
    String? testType,
    String? title,
    String? testDate,
    Uint8List? fileBytes,
    String? status,
    Value<String?> uploadId = const Value.absent(),
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => ClinicalUploadQueueData(
    ownerId: ownerId ?? this.ownerId,
    clientUploadId: clientUploadId ?? this.clientUploadId,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    sha256: sha256 ?? this.sha256,
    testType: testType ?? this.testType,
    title: title ?? this.title,
    testDate: testDate ?? this.testDate,
    fileBytes: fileBytes ?? this.fileBytes,
    status: status ?? this.status,
    uploadId: uploadId.present ? uploadId.value : this.uploadId,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  ClinicalUploadQueueData copyWithCompanion(ClinicalUploadQueueCompanion data) {
    return ClinicalUploadQueueData(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      clientUploadId: data.clientUploadId.present
          ? data.clientUploadId.value
          : this.clientUploadId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      testType: data.testType.present ? data.testType.value : this.testType,
      title: data.title.present ? data.title.value : this.title,
      testDate: data.testDate.present ? data.testDate.value : this.testDate,
      fileBytes: data.fileBytes.present ? data.fileBytes.value : this.fileBytes,
      status: data.status.present ? data.status.value : this.status,
      uploadId: data.uploadId.present ? data.uploadId.value : this.uploadId,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClinicalUploadQueueData(')
          ..write('ownerId: $ownerId, ')
          ..write('clientUploadId: $clientUploadId, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('testType: $testType, ')
          ..write('title: $title, ')
          ..write('testDate: $testDate, ')
          ..write('fileBytes: $fileBytes, ')
          ..write('status: $status, ')
          ..write('uploadId: $uploadId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ownerId,
    clientUploadId,
    fileName,
    mimeType,
    sizeBytes,
    sha256,
    testType,
    title,
    testDate,
    $driftBlobEquality.hash(fileBytes),
    status,
    uploadId,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClinicalUploadQueueData &&
          other.ownerId == this.ownerId &&
          other.clientUploadId == this.clientUploadId &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          other.testType == this.testType &&
          other.title == this.title &&
          other.testDate == this.testDate &&
          $driftBlobEquality.equals(other.fileBytes, this.fileBytes) &&
          other.status == this.status &&
          other.uploadId == this.uploadId &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class ClinicalUploadQueueCompanion
    extends UpdateCompanion<ClinicalUploadQueueData> {
  final Value<String> ownerId;
  final Value<String> clientUploadId;
  final Value<String> fileName;
  final Value<String> mimeType;
  final Value<int> sizeBytes;
  final Value<String> sha256;
  final Value<String> testType;
  final Value<String> title;
  final Value<String> testDate;
  final Value<Uint8List> fileBytes;
  final Value<String> status;
  final Value<String?> uploadId;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ClinicalUploadQueueCompanion({
    this.ownerId = const Value.absent(),
    this.clientUploadId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.testType = const Value.absent(),
    this.title = const Value.absent(),
    this.testDate = const Value.absent(),
    this.fileBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.uploadId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClinicalUploadQueueCompanion.insert({
    required String ownerId,
    required String clientUploadId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String sha256,
    required String testType,
    required String title,
    required String testDate,
    required Uint8List fileBytes,
    this.status = const Value.absent(),
    this.uploadId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       clientUploadId = Value(clientUploadId),
       fileName = Value(fileName),
       mimeType = Value(mimeType),
       sizeBytes = Value(sizeBytes),
       sha256 = Value(sha256),
       testType = Value(testType),
       title = Value(title),
       testDate = Value(testDate),
       fileBytes = Value(fileBytes);
  static Insertable<ClinicalUploadQueueData> custom({
    Expression<String>? ownerId,
    Expression<String>? clientUploadId,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<String>? testType,
    Expression<String>? title,
    Expression<String>? testDate,
    Expression<Uint8List>? fileBytes,
    Expression<String>? status,
    Expression<String>? uploadId,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (clientUploadId != null) 'client_upload_id': clientUploadId,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (testType != null) 'test_type': testType,
      if (title != null) 'title': title,
      if (testDate != null) 'test_date': testDate,
      if (fileBytes != null) 'file_bytes': fileBytes,
      if (status != null) 'status': status,
      if (uploadId != null) 'upload_id': uploadId,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClinicalUploadQueueCompanion copyWith({
    Value<String>? ownerId,
    Value<String>? clientUploadId,
    Value<String>? fileName,
    Value<String>? mimeType,
    Value<int>? sizeBytes,
    Value<String>? sha256,
    Value<String>? testType,
    Value<String>? title,
    Value<String>? testDate,
    Value<Uint8List>? fileBytes,
    Value<String>? status,
    Value<String?>? uploadId,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ClinicalUploadQueueCompanion(
      ownerId: ownerId ?? this.ownerId,
      clientUploadId: clientUploadId ?? this.clientUploadId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      testType: testType ?? this.testType,
      title: title ?? this.title,
      testDate: testDate ?? this.testDate,
      fileBytes: fileBytes ?? this.fileBytes,
      status: status ?? this.status,
      uploadId: uploadId ?? this.uploadId,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (clientUploadId.present) {
      map['client_upload_id'] = Variable<String>(clientUploadId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (testType.present) {
      map['test_type'] = Variable<String>(testType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (testDate.present) {
      map['test_date'] = Variable<String>(testDate.value);
    }
    if (fileBytes.present) {
      map['file_bytes'] = Variable<Uint8List>(fileBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (uploadId.present) {
      map['upload_id'] = Variable<String>(uploadId.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClinicalUploadQueueCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('clientUploadId: $clientUploadId, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('testType: $testType, ')
          ..write('title: $title, ')
          ..write('testDate: $testDate, ')
          ..write('fileBytes: $fileBytes, ')
          ..write('status: $status, ')
          ..write('uploadId: $uploadId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UploadQueueDatabase extends GeneratedDatabase {
  _$UploadQueueDatabase(QueryExecutor e) : super(e);
  $UploadQueueDatabaseManager get managers => $UploadQueueDatabaseManager(this);
  late final $ClinicalUploadQueueTable clinicalUploadQueue =
      $ClinicalUploadQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [clinicalUploadQueue];
}

typedef $$ClinicalUploadQueueTableCreateCompanionBuilder =
    ClinicalUploadQueueCompanion Function({
      required String ownerId,
      required String clientUploadId,
      required String fileName,
      required String mimeType,
      required int sizeBytes,
      required String sha256,
      required String testType,
      required String title,
      required String testDate,
      required Uint8List fileBytes,
      Value<String> status,
      Value<String?> uploadId,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ClinicalUploadQueueTableUpdateCompanionBuilder =
    ClinicalUploadQueueCompanion Function({
      Value<String> ownerId,
      Value<String> clientUploadId,
      Value<String> fileName,
      Value<String> mimeType,
      Value<int> sizeBytes,
      Value<String> sha256,
      Value<String> testType,
      Value<String> title,
      Value<String> testDate,
      Value<Uint8List> fileBytes,
      Value<String> status,
      Value<String?> uploadId,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ClinicalUploadQueueTableFilterComposer
    extends Composer<_$UploadQueueDatabase, $ClinicalUploadQueueTable> {
  $$ClinicalUploadQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientUploadId => $composableBuilder(
    column: $table.clientUploadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get testType => $composableBuilder(
    column: $table.testType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get testDate => $composableBuilder(
    column: $table.testDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get fileBytes => $composableBuilder(
    column: $table.fileBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uploadId => $composableBuilder(
    column: $table.uploadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClinicalUploadQueueTableOrderingComposer
    extends Composer<_$UploadQueueDatabase, $ClinicalUploadQueueTable> {
  $$ClinicalUploadQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientUploadId => $composableBuilder(
    column: $table.clientUploadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get testType => $composableBuilder(
    column: $table.testType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get testDate => $composableBuilder(
    column: $table.testDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get fileBytes => $composableBuilder(
    column: $table.fileBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uploadId => $composableBuilder(
    column: $table.uploadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClinicalUploadQueueTableAnnotationComposer
    extends Composer<_$UploadQueueDatabase, $ClinicalUploadQueueTable> {
  $$ClinicalUploadQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get clientUploadId => $composableBuilder(
    column: $table.clientUploadId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get testType =>
      $composableBuilder(column: $table.testType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get testDate =>
      $composableBuilder(column: $table.testDate, builder: (column) => column);

  GeneratedColumn<Uint8List> get fileBytes =>
      $composableBuilder(column: $table.fileBytes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get uploadId =>
      $composableBuilder(column: $table.uploadId, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ClinicalUploadQueueTableTableManager
    extends
        RootTableManager<
          _$UploadQueueDatabase,
          $ClinicalUploadQueueTable,
          ClinicalUploadQueueData,
          $$ClinicalUploadQueueTableFilterComposer,
          $$ClinicalUploadQueueTableOrderingComposer,
          $$ClinicalUploadQueueTableAnnotationComposer,
          $$ClinicalUploadQueueTableCreateCompanionBuilder,
          $$ClinicalUploadQueueTableUpdateCompanionBuilder,
          (
            ClinicalUploadQueueData,
            BaseReferences<
              _$UploadQueueDatabase,
              $ClinicalUploadQueueTable,
              ClinicalUploadQueueData
            >,
          ),
          ClinicalUploadQueueData,
          PrefetchHooks Function()
        > {
  $$ClinicalUploadQueueTableTableManager(
    _$UploadQueueDatabase db,
    $ClinicalUploadQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClinicalUploadQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClinicalUploadQueueTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClinicalUploadQueueTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String> clientUploadId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> testType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> testDate = const Value.absent(),
                Value<Uint8List> fileBytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> uploadId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClinicalUploadQueueCompanion(
                ownerId: ownerId,
                clientUploadId: clientUploadId,
                fileName: fileName,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                sha256: sha256,
                testType: testType,
                title: title,
                testDate: testDate,
                fileBytes: fileBytes,
                status: status,
                uploadId: uploadId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                required String clientUploadId,
                required String fileName,
                required String mimeType,
                required int sizeBytes,
                required String sha256,
                required String testType,
                required String title,
                required String testDate,
                required Uint8List fileBytes,
                Value<String> status = const Value.absent(),
                Value<String?> uploadId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClinicalUploadQueueCompanion.insert(
                ownerId: ownerId,
                clientUploadId: clientUploadId,
                fileName: fileName,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                sha256: sha256,
                testType: testType,
                title: title,
                testDate: testDate,
                fileBytes: fileBytes,
                status: status,
                uploadId: uploadId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ClinicalUploadQueueTable,
                    ClinicalUploadQueueData
                  >(table),
                  BaseReferences<
                    _$UploadQueueDatabase,
                    $ClinicalUploadQueueTable,
                    ClinicalUploadQueueData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClinicalUploadQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$UploadQueueDatabase,
      $ClinicalUploadQueueTable,
      ClinicalUploadQueueData,
      $$ClinicalUploadQueueTableFilterComposer,
      $$ClinicalUploadQueueTableOrderingComposer,
      $$ClinicalUploadQueueTableAnnotationComposer,
      $$ClinicalUploadQueueTableCreateCompanionBuilder,
      $$ClinicalUploadQueueTableUpdateCompanionBuilder,
      (
        ClinicalUploadQueueData,
        BaseReferences<
          _$UploadQueueDatabase,
          $ClinicalUploadQueueTable,
          ClinicalUploadQueueData
        >,
      ),
      ClinicalUploadQueueData,
      PrefetchHooks Function()
    >;

class $UploadQueueDatabaseManager {
  final _$UploadQueueDatabase _db;
  $UploadQueueDatabaseManager(this._db);
  $$ClinicalUploadQueueTableTableManager get clinicalUploadQueue =>
      $$ClinicalUploadQueueTableTableManager(_db, _db.clinicalUploadQueue);
}
