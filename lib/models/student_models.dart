class StudentProfile {
  final int studentId;
  final String schoolId;
  final String? fullName;
  final bool hasFaceEmbedding;

  const StudentProfile({
    required this.studentId,
    required this.schoolId,
    this.fullName,
    required this.hasFaceEmbedding,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      studentId: (json['student_id'] as num).toInt(),
      schoolId: (json['school_id'] ?? '').toString(),
      fullName: json['full_name'] as String?,
      hasFaceEmbedding: json['has_face_embedding'] == true,
    );
  }
}

class MyQueueEntry {
  final bool hasActiveEntry;
  final bool pendingLink;

  /// Whether the student has asked to be issued a number on recognition.
  /// The camera ignores registered students who have not opted in.
  final bool joined;

  final int? queueNumber;
  final String? accessToken;

  const MyQueueEntry({
    required this.hasActiveEntry,
    required this.pendingLink,
    this.joined = false,
    this.queueNumber,
    this.accessToken,
  });

  factory MyQueueEntry.fromJson(Map<String, dynamic> json) {
    return MyQueueEntry(
      hasActiveEntry: json['has_active_entry'] == true,
      pendingLink: json['pending_link'] == true,
      joined: json['joined'] == true,
      queueNumber: (json['queue_number'] as num?)?.toInt(),
      accessToken: json['access_token'] as String?,
    );
  }
}

class StudentSession {
  final String sessionToken;
  final StudentProfile profile;

  const StudentSession({required this.sessionToken, required this.profile});

  factory StudentSession.fromJson(Map<String, dynamic> json) {
    return StudentSession(
      sessionToken: (json['session_token'] ?? '').toString(),
      profile: StudentProfile.fromJson(json),
    );
  }
}
