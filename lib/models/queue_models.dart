String formatQueueLabel(int queueNumber) {
  return 'Q${queueNumber.toString().padLeft(3, '0')}';
}

int _readInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _readDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

String _readString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

bool _readBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

class QueueCredentials {
  final int queueNumber;
  final String accessToken;
  final String? apiBaseUrl;

  const QueueCredentials({
    required this.queueNumber,
    required this.accessToken,
    this.apiBaseUrl,
  });

  String get queueLabel => formatQueueLabel(queueNumber);
  String get queueDigits => queueNumber.toString().padLeft(3, '0');

  String get maskedToken {
    final compact = accessToken.replaceAll('-', '');
    if (compact.length <= 4) return compact;
    return '${compact.substring(0, 4)}....';
  }
}

class QueueEstimate {
  final int position;
  final double estimatedWaitMinutes;
  final String estimatedWaitLabel;
  final String? estimatedServiceStartAt;
  final String? estimatedServiceFinishAt;
  final double estimatedServiceTimeMinutes;

  const QueueEstimate({
    required this.position,
    required this.estimatedWaitMinutes,
    required this.estimatedWaitLabel,
    required this.estimatedServiceStartAt,
    required this.estimatedServiceFinishAt,
    required this.estimatedServiceTimeMinutes,
  });

  factory QueueEstimate.fromJson(Map<String, dynamic> json) {
    final waitMinutes = _readDouble(
      json['estimated_wait_time_minutes'] ?? json['estimated_wait_time'],
    );

    return QueueEstimate(
      position: _readInt(json['position']),
      estimatedWaitMinutes: waitMinutes,
      estimatedWaitLabel: _readString(
        json['estimated_wait_time_label'],
        waitMinutes < 1 ? 'less than 1 min' : '${waitMinutes.round()} min',
      ),
      estimatedServiceStartAt: json['estimated_service_start_at']?.toString(),
      estimatedServiceFinishAt: json['estimated_service_finish_at']?.toString(),
      estimatedServiceTimeMinutes: _readDouble(
        json['estimated_service_time_min'],
        0,
      ),
    );
  }
}

class QueueStatus {
  final int queueNumber;
  final String queueLabel;
  final String status;
  final int positionInLine;
  final String waitTime;
  final int waitTimeSeconds;
  final String joinedAt;
  final String joinedAtFull;
  final QueueEstimate? prediction;
  final bool onTheWay;
  final String? onTheWayAt;

  const QueueStatus({
    required this.queueNumber,
    required this.queueLabel,
    required this.status,
    required this.positionInLine,
    required this.waitTime,
    required this.waitTimeSeconds,
    required this.joinedAt,
    required this.joinedAtFull,
    required this.prediction,
    required this.onTheWay,
    required this.onTheWayAt,
  });

  factory QueueStatus.fromJson(Map<String, dynamic> json) {
    final queueNumber = _readInt(json['queue_number']);
    final predictionJson = _readMap(json['prediction']);

    return QueueStatus(
      queueNumber: queueNumber,
      queueLabel: _readString(
        json['queue_label'],
        formatQueueLabel(queueNumber),
      ),
      status: _readString(json['status'], 'waiting'),
      positionInLine: _readInt(
        json['position_in_line'],
        _readInt(predictionJson['position'], 0),
      ),
      waitTime: _readString(json['wait_time'], '0s'),
      waitTimeSeconds: _readInt(json['wait_time_seconds']),
      joinedAt: _readString(json['joined_at']),
      joinedAtFull: _readString(json['joined_at_full']),
      prediction: predictionJson.isEmpty
          ? null
          : QueueEstimate.fromJson(predictionJson),
      onTheWay: _readBool(json['on_the_way']),
      onTheWayAt: json['on_the_way_at_display']?.toString(),
    );
  }

  String get queueDigits => queueNumber.toString().padLeft(3, '0');
  int get aheadCount => positionInLine > 0 ? positionInLine - 1 : 0;
  bool get isDone => status == 'done_pending' || status == 'served';
  bool get isNoShow => status == 'no_show';
  bool get isMissing => status == 'missing';
  bool get isNext =>
      !isDone && !isNoShow && positionInLine > 0 && positionInLine <= 1;

  double get estimatedWaitMinutes => prediction?.estimatedWaitMinutes ?? 0;

  String get estimatedWaitLabel =>
      prediction?.estimatedWaitLabel ?? 'less than 1 min';

  QueueStatus copyWith({bool? onTheWay, String? onTheWayAt}) {
    return QueueStatus(
      queueNumber: queueNumber,
      queueLabel: queueLabel,
      status: status,
      positionInLine: positionInLine,
      waitTime: waitTime,
      waitTimeSeconds: waitTimeSeconds,
      joinedAt: joinedAt,
      joinedAtFull: joinedAtFull,
      prediction: prediction,
      onTheWay: onTheWay ?? this.onTheWay,
      onTheWayAt: onTheWayAt ?? this.onTheWayAt,
    );
  }
}

class QueuePerson {
  final int queueNumber;
  final String queueLabel;
  final String status;
  final int position;
  final double estimatedWaitMinutes;
  final String estimatedWaitLabel;
  final bool onTheWay;
  final String? onTheWayAt;

  const QueuePerson({
    required this.queueNumber,
    required this.queueLabel,
    required this.status,
    required this.position,
    required this.estimatedWaitMinutes,
    required this.estimatedWaitLabel,
    required this.onTheWay,
    required this.onTheWayAt,
  });

  factory QueuePerson.fromJson(Map<String, dynamic> json) {
    final queueNumber = _readInt(json['queue_number']);
    final waitMinutes = _readDouble(
      json['estimated_wait_time_minutes'] ?? json['estimated_wait_time'],
    );

    return QueuePerson(
      queueNumber: queueNumber,
      queueLabel: _readString(
        json['queue_label'],
        formatQueueLabel(queueNumber),
      ),
      status: _readString(json['status'], 'waiting'),
      position: _readInt(json['position'] ?? json['position_in_line']),
      estimatedWaitMinutes: waitMinutes,
      estimatedWaitLabel: _readString(
        json['estimated_wait_time_label'],
        waitMinutes < 1 ? 'less than 1 min' : '${waitMinutes.round()} min',
      ),
      onTheWay: _readBool(json['on_the_way']),
      onTheWayAt: json['on_the_way_at_display']?.toString(),
    );
  }

  String get queueDigits => queueNumber.toString().padLeft(3, '0');
}

class QueuePrediction {
  final int queueLength;
  final int activeCounters;
  final String dataStatus;
  final List<QueuePerson> activeQueue;

  /// Human-readable wait estimate for someone joining the queue right now,
  /// e.g. "about 12 min" — from the backend's `new_arrival` block.
  final String newArrivalWaitLabel;

  const QueuePrediction({
    required this.queueLength,
    required this.activeCounters,
    required this.dataStatus,
    required this.activeQueue,
    this.newArrivalWaitLabel = '—',
  });

  factory QueuePrediction.fromJson(Map<String, dynamic> json) {
    final rawQueue = json['active_queue'];
    final people = rawQueue is List
        ? rawQueue
              .whereType<Map>()
              .map(
                (item) => QueuePerson.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <QueuePerson>[];

    people.sort((a, b) => a.position.compareTo(b.position));

    final newArrival = json['new_arrival'];
    final waitLabel = newArrival is Map
        ? _readString(newArrival['estimated_wait_time_label'], '—')
        : '—';

    return QueuePrediction(
      queueLength: _readInt(json['queue_length']),
      activeCounters: _readInt(json['active_counters']),
      dataStatus: _readString(json['data_status'], 'live'),
      activeQueue: people,
      newArrivalWaitLabel: waitLabel,
    );
  }

  factory QueuePrediction.empty() {
    return const QueuePrediction(
      queueLength: 0,
      activeCounters: 0,
      dataStatus: 'unknown',
      activeQueue: [],
    );
  }

  QueuePerson? findByQueueNumber(int queueNumber) {
    for (final person in activeQueue) {
      if (person.queueNumber == queueNumber) return person;
    }
    return null;
  }
}

class QueueSnapshot {
  final QueueCredentials credentials;
  final QueueStatus status;
  final QueuePrediction prediction;
  final DateTime fetchedAt;

  QueueSnapshot({
    required this.credentials,
    required this.status,
    required this.prediction,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  int get activeCounters => prediction.activeCounters;

  QueueSnapshot copyWith({
    QueueStatus? status,
    QueuePrediction? prediction,
    DateTime? fetchedAt,
  }) {
    return QueueSnapshot(
      credentials: credentials,
      status: status ?? this.status,
      prediction: prediction ?? this.prediction,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  List<QueuePerson> get visibleLine {
    final people = prediction.activeQueue
        .where((person) => person.position <= status.positionInLine)
        .toList();

    if (people.any((person) => person.queueNumber == status.queueNumber)) {
      return people;
    }

    people.add(
      QueuePerson(
        queueNumber: status.queueNumber,
        queueLabel: status.queueLabel,
        status: status.status,
        position: status.positionInLine,
        estimatedWaitMinutes: status.estimatedWaitMinutes,
        estimatedWaitLabel: status.estimatedWaitLabel,
        onTheWay: status.onTheWay,
        onTheWayAt: status.onTheWayAt,
      ),
    );
    people.sort((a, b) => a.position.compareTo(b.position));
    return people;
  }
}
