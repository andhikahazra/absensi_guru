/// Enum untuk tipe error yang mungkin terjadi
enum AttendanceErrorType {
  scheduleInvalid,
  faceNotRegistered,
  faceNotMatched,
  serviceError,
  networkError,
  unauthorized,
  unknown;

  String get message {
    switch (this) {
      case AttendanceErrorType.scheduleInvalid:
        return 'Jadwal absen tidak valid';
      case AttendanceErrorType.faceNotRegistered:
        return 'Wajah tidak terdaftar';
      case AttendanceErrorType.faceNotMatched:
        return 'Wajah tidak sesuai dengan data terdaftar';
      case AttendanceErrorType.serviceError:
        return 'Layanan face recognition sedang bermasalah';
      case AttendanceErrorType.networkError:
        return 'Gangguan jaringan';
      case AttendanceErrorType.unauthorized:
        return 'Anda tidak memiliki akses';
      case AttendanceErrorType.unknown:
        return 'Terjadi kesalahan yang tidak diketahui';
    }
  }
}

/// Tipe absen: check-in atau check-out
enum AttendanceType {
  checkIn,
  checkOut;

  String get value {
    switch (this) {
      case AttendanceType.checkIn:
        return 'check-in';
      case AttendanceType.checkOut:
        return 'check-out';
    }
  }

  String get label {
    switch (this) {
      case AttendanceType.checkIn:
        return 'Masuk';
      case AttendanceType.checkOut:
        return 'Keluar';
    }
  }
}

/// Status absen
enum AttendanceStatus {
  success,
  pending,
  completed;

  String get value {
    switch (this) {
      case AttendanceStatus.success:
        return 'success';
      case AttendanceStatus.pending:
        return 'pending';
      case AttendanceStatus.completed:
        return 'completed';
    }
  }
}

/// Model untuk data absen
class Attendance {
  final int id;
  final int userId;
  final String date;
  final DateTime checkIn;
  final DateTime? checkOut;
  final AttendanceStatus status;
  final bool match;
  final double distance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Attendance({
    required this.id,
    required this.userId,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
    required this.match,
    required this.distance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      date: json['date'] as String,
      checkIn: DateTime.parse(json['check_in'] as String),
      checkOut: json['check_out'] != null
          ? DateTime.parse(json['check_out'] as String)
          : null,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => AttendanceStatus.pending,
      ),
      match: json['match'] as bool? ?? false,
      distance: (json['distance'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'date': date,
    'check_in': checkIn.toIso8601String(),
    'check_out': checkOut?.toIso8601String(),
    'status': status.value,
    'match': match,
    'distance': distance,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Model untuk response API absen yang sukses
class AttendanceSuccessResponse {
  final bool status;
  final AttendanceType attendanceType;
  final bool match;
  final double distance;
  final String? message;
  final Attendance? attendance;
  final DateTime timestamp;

  AttendanceSuccessResponse({
    required this.status,
    required this.attendanceType,
    required this.match,
    required this.distance,
    this.message,
    this.attendance,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory AttendanceSuccessResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceSuccessResponse(
      status: json['status'] == 'success',
      attendanceType: json['attendance_type'] == 'check-out'
          ? AttendanceType.checkOut
          : AttendanceType.checkIn,
      match: json['match'] as bool? ?? true,
      distance: (json['distance'] as num).toDouble(),
      message: json['message'] as String?,
      attendance: json['attendance'] != null
          ? Attendance.fromJson(json['attendance'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status ? 'success' : 'error',
    'attendance_type': attendanceType.value,
    'match': match,
    'distance': distance,
    if (message != null) 'message': message,
    if (attendance != null) 'attendance': attendance!.toJson(),
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Model untuk response API absen yang error
class AttendanceErrorResponse {
  final bool status;
  final String message;
  final AttendanceErrorType type;
  final String? code;
  final Map<String, dynamic>? details;
  final DateTime timestamp;

  AttendanceErrorResponse({
    required this.message,
    required this.type,
    this.code,
    this.details,
    DateTime? timestamp,
  }) : status = false,
       timestamp = timestamp ?? DateTime.now();

  factory AttendanceErrorResponse.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    AttendanceErrorType errorType = AttendanceErrorType.unknown;

    if (typeStr != null) {
      switch (typeStr) {
        case 'schedule_invalid':
          errorType = AttendanceErrorType.scheduleInvalid;
          break;
        case 'face_not_registered':
          errorType = AttendanceErrorType.faceNotRegistered;
          break;
        case 'face_not_matched':
          errorType = AttendanceErrorType.faceNotMatched;
          break;
        case 'service_error':
          errorType = AttendanceErrorType.serviceError;
          break;
        case 'network_error':
          errorType = AttendanceErrorType.networkError;
          break;
        case 'unauthorized':
          errorType = AttendanceErrorType.unauthorized;
          break;
      }
    }

    return AttendanceErrorResponse(
      message: json['message'] as String? ?? 'Terjadi kesalahan',
      type: errorType,
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': 'error',
    'message': message,
    'type': _errorTypeString(type),
    if (code != null) 'code': code,
    if (details != null) 'details': details,
    'timestamp': timestamp.toIso8601String(),
  };

  String _errorTypeString(AttendanceErrorType type) {
    switch (type) {
      case AttendanceErrorType.scheduleInvalid:
        return 'schedule_invalid';
      case AttendanceErrorType.faceNotRegistered:
        return 'face_not_registered';
      case AttendanceErrorType.faceNotMatched:
        return 'face_not_matched';
      case AttendanceErrorType.serviceError:
        return 'service_error';
      case AttendanceErrorType.networkError:
        return 'network_error';
      case AttendanceErrorType.unauthorized:
        return 'unauthorized';
      case AttendanceErrorType.unknown:
        return 'unknown';
    }
  }
}

/// Response API yang umum - bisa sukses atau error
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final AttendanceErrorType? errorType;
  final Map<String, dynamic>? meta;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errorType,
    this.meta,
  });

  factory ApiResponse.success({
    required T data,
    String? message,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse(success: true, message: message, data: data, meta: meta);
  }

  factory ApiResponse.error({
    required String message,
    AttendanceErrorType errorType = AttendanceErrorType.unknown,
    Map<String, dynamic>? meta,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      errorType: errorType,
      meta: meta,
    );
  }
}
