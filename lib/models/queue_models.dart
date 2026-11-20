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
  // Where the wait usually falls, e.g. "usually 0–9 mins". Empty when the
  // backend sends none (an older server, or a ticket out of the line).
  final String estimatedWaitRangeLabel;
  final String? estimatedServiceStartAt;
  final String? estimatedServiceFinishAt;
  final double estimatedServiceTimeMinutes;

  /// The wait to the second, worked out again by the server on every request.
  /// The app counts it down between requests.
  final int estimatedWaitSeconds;

  /// The clock time this student's turn is expected, e.g. "2:41:30 PM".
  final String estimatedServiceStartLabel;

  /// The current average service time, e.g. 117 s from the "last 4 services".
  final int avgServiceSeconds;
  final String avgServiceBasis;

  /// Why the time is moving later, when a window is running long; else empty.
  final String adjustmentNote;

  const QueueEstimate({
    required this.position,
    required this.estimatedWaitMinutes,
    required this.estimatedWaitLabel,
    this.estimatedWaitRangeLabel = '',
    required this.estimatedServiceStartAt,
    required this.estimatedServiceFinishAt,
    required this.estimatedServiceTimeMinutes,
    this.estimatedWaitSeconds = 0,
    this.estimatedServiceStartLabel = '',
    this.avgServiceSeconds = 0,
    this.avgServiceBasis = '',
    this.adjustmentNote = '',
  });

  factory QueueEstimate.fromJson(Map<String, dynamic> json) {
    final waitMinutes = _readDouble(
      json['estimated_wait_time_minutes'] ?? json['estimated_wait_time'],
    );
    final serviceMinutes = _readDouble(json['estimated_service_time_min'], 0);

    return QueueEstimate(
      position: _readInt(json['position']),
      estimatedWaitMinutes: waitMinutes,
      estimatedWaitLabel: _readString(
        json['estimated_wait_time_label'],
        waitMinutes < 1 ? 'less than 1 min' : '${waitMinutes.round()} min',
      ),
      estimatedWaitRangeLabel: _readString(json['estimated_wait_range_label']),
      estimatedServiceStartAt: json['estimated_service_start_at']?.toString(),
      estimatedServiceFinishAt: json['estimated_service_finish_at']?.toString(),
      estimatedServiceTimeMinutes: serviceMinutes,
      // An older server sends minutes only.
      estimatedWaitSeconds: _readInt(
        json['estimated_wait_seconds'],
        (waitMinutes * 60).round(),
      ),
      estimatedServiceStartLabel: _readString(
        json['estimated_service_start_label'],
      ),
      avgServiceSeconds: _readInt(
        json['avg_service_seconds'],
        (serviceMinutes * 60).round(),
      ),
      avgServiceBasis: _readString(json['avg_service_basis']),
      adjustmentNote: _readString(json['adjustment_note']),
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

  /// The window this ticket has been called to; null while still waiting.
  final int? counterNumber;

  /// What the student said they are paying, from the join form.
  final String? paymentType;
  final double? paymentAmount;
  final String? paymentNote;

  /// Called to a window: how long ago (when the server answered), and how
  /// long the student has to reach it.
  final int? secondsAtCounter;
  final int arriveWithinSeconds;

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
    this.counterNumber,
    this.paymentType,
    this.paymentAmount,
    this.paymentNote,
    this.secondsAtCounter,
    this.arriveWithinSeconds = 60,
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
      counterNumber: _readInt(json['counter_number']) > 0
          ? _readInt(json['counter_number'])
          : null,
      paymentType: json['payment_type']?.toString(),
      paymentAmount: json['payment_amount'] is num
          ? (json['payment_amount'] as num).toDouble()
          : null,
      paymentNote: json['payment_note']?.toString(),
      secondsAtCounter: json['seconds_at_counter'] is num
          ? (json['seconds_at_counter'] as num).toInt()
          : null,
      arriveWithinSeconds: _readInt(json['arrive_within_seconds'], 60),
    );
  }

  String get queueDigits => queueNumber.toString().padLeft(3, '0');
  int get aheadCount => positionInLine > 0 ? positionInLine - 1 : 0;

  /// Called to a window and not yet finished: it is this student's turn.
  bool get isBeingServed => counterNumber != null && !isDone && !isNoShow;
  bool get isDone => status == 'done_pending' || status == 'served';
  bool get isNoShow => status == 'no_show';
  bool get isMissing => status == 'missing';
  bool get isNext =>
      !isDone && !isNoShow && positionInLine > 0 && positionInLine <= 1;

  double get estimatedWaitMinutes => prediction?.estimatedWaitMinutes ?? 0;

  String get estimatedWaitLabel =>
      prediction?.estimatedWaitLabel ?? 'less than 1 min';

  /// The estimate with its usual range, e.g. "3 mins · usually 0–10 mins".
  /// The estimate alone is often off by a few minutes; the range says how far.
  String get estimatedWaitWithRange {
    final range = prediction?.estimatedWaitRangeLabel ?? '';
    return range.isEmpty ? estimatedWaitLabel : '$estimatedWaitLabel · $range';
  }

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
      counterNumber: counterNumber,
      paymentType: paymentType,
      paymentAmount: paymentAmount,
      paymentNote: paymentNote,
      secondsAtCounter: secondsAtCounter,
      arriveWithinSeconds: arriveWithinSeconds,
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

/// One cashier window and the number being served there.
class NowServing {
  final int counterNumber;
  final int queueNumber;
  final String queueLabel;

  /// How long the student at this window had been there when the server
  /// answered; null from an older server.
  final int? servingSeconds;

  /// Longer than the current average service time.
  final bool runningLong;

  const NowServing({
    required this.counterNumber,
    required this.queueNumber,
    required this.queueLabel,
    this.servingSeconds,
    this.runningLong = false,
  });

  factory NowServing.fromJson(Map<String, dynamic> json) {
    final queueNumber = _readInt(json['queue_number']);
    final serving = json['serving_seconds'];
    return NowServing(
      counterNumber: _readInt(json['counter_number']),
      queueNumber: queueNumber,
      queueLabel: _readString(
        json['queue_label'],
        formatQueueLabel(queueNumber),
      ),
      servingSeconds: serving is num ? serving.toInt() : null,
      runningLong: _readBool(json['running_long']),
    );
  }
}

class QueuePrediction {
  final int queueLength;
  final int activeCounters;
  final String dataStatus;
  final List<QueuePerson> activeQueue;

  /// Human-readable wait estimate for someone joining the queue right now,
  /// e.g. "about 12 min" — from the backend's `new_arrival` block.
  final String newArrivalWaitLabel;

  /// The same estimate in minutes, to decide whether the line is long.
  final double newArrivalWaitMinutes;

  /// Who is at each window, ordered by window.
  final List<NowServing> nowServing;

  /// Set while staff have closed every window (lunch), in local time.
  final DateTime? countersClosedUntil;

  /// The wait for someone joining now, to the second.
  final int newArrivalWaitSeconds;

  /// The current average service time and what it is based on.
  final int avgServiceSeconds;
  final String avgServiceLabel;
  final String avgServiceBasis;

  /// When this phone received it, so times can be counted on from there.
  final DateTime receivedAt;

  QueuePrediction({
    required this.queueLength,
    required this.activeCounters,
    required this.dataStatus,
    required this.activeQueue,
    this.newArrivalWaitLabel = '—',
    this.newArrivalWaitMinutes = 0,
    this.nowServing = const [],
    this.countersClosedUntil,
    this.newArrivalWaitSeconds = 0,
    this.avgServiceSeconds = 0,
    this.avgServiceLabel = '',
    this.avgServiceBasis = '',
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

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
    final waitMinutes = newArrival is Map
        ? _readDouble(newArrival['estimated_wait_time_minutes'])
        : 0.0;
    final waitSeconds = newArrival is Map
        ? _readInt(
            newArrival['estimated_wait_seconds'],
            (waitMinutes * 60).round(),
          )
        : 0;

    final rawServing = json['now_serving'];
    final serving = rawServing is List
        ? rawServing
              .whereType<Map>()
              .map(
                (item) => NowServing.fromJson(Map<String, dynamic>.from(item)),
              )
              .where(
                (entry) => entry.counterNumber > 0 && entry.queueNumber > 0,
              )
              .toList()
        : <NowServing>[];
    serving.sort((a, b) => a.counterNumber.compareTo(b.counterNumber));

    final closedRaw = json['counters_closed_until'];
    final closedUntil = closedRaw is String
        ? DateTime.tryParse(closedRaw)?.toLocal()
        : null;

    return QueuePrediction(
      queueLength: _readInt(json['queue_length']),
      activeCounters: _readInt(json['active_counters']),
      dataStatus: _readString(json['data_status'], 'live'),
      activeQueue: people,
      newArrivalWaitLabel: waitLabel,
      newArrivalWaitMinutes: waitMinutes,
      nowServing: serving,
      countersClosedUntil: closedUntil,
      newArrivalWaitSeconds: waitSeconds,
      avgServiceSeconds: _readInt(
        json['avg_service_seconds'],
        (_readDouble(json['avg_service_time_min']) * 60).round(),
      ),
      avgServiceLabel: _readString(json['avg_service_label']),
      avgServiceBasis: _readString(json['avg_service_basis']),
    );
  }

  factory QueuePrediction.empty() {
    return QueuePrediction(
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
