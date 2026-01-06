import 'package:flutter/material.dart';

/// Enum untuk tipe notification
enum NotificationType {
  success,
  warning,
  error,
  info;

  Color get color {
    switch (this) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.redAccent;
      case NotificationType.info:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.success:
        return Icons.check_circle_rounded;
      case NotificationType.warning:
        return Icons.warning_rounded;
      case NotificationType.error:
        return Icons.error_rounded;
      case NotificationType.info:
        return Icons.info_rounded;
    }
  }
}

/// Model untuk attendance status
class AttendanceStatusData {
  final bool checkedIn;
  final bool checkedOut;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String date;

  AttendanceStatusData({
    required this.checkedIn,
    required this.checkedOut,
    this.checkInTime,
    this.checkOutTime,
    required this.date,
  });

  factory AttendanceStatusData.fromJson(Map<String, dynamic> json) {
    final checkInStr = json['check_in'] as String?;
    final checkOutStr = json['check_out'] as String?;

    return AttendanceStatusData(
      checkedIn: checkInStr != null,
      checkedOut: checkOutStr != null,
      checkInTime: checkInStr != null ? DateTime.parse(checkInStr) : null,
      checkOutTime: checkOutStr != null ? DateTime.parse(checkOutStr) : null,
      date: json['date'] as String? ?? DateTime.now().toString().split(' ')[0],
    );
  }

  bool get isCompleted => checkedIn && checkedOut;
}

/// Utility untuk notification dialogs
class NotificationDialogs {
  /// Format waktu HH:mm dari DateTime (convert UTC to local)
  static String _formatTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Tampilkan notification dialog sukses
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String buttonLabel = 'OK',
  }) {
    _showNotificationDialog(
      context,
      type: NotificationType.success,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onConfirm: onConfirm,
    );
  }

  /// Tampilkan notification dialog warning
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String buttonLabel = 'OK',
  }) {
    _showNotificationDialog(
      context,
      type: NotificationType.warning,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onConfirm: onConfirm,
    );
  }

  /// Tampilkan notification dialog error
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String buttonLabel = 'Coba Lagi',
  }) {
    _showNotificationDialog(
      context,
      type: NotificationType.error,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onConfirm: onConfirm,
    );
  }

  /// Tampilkan notification dialog info
  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onConfirm,
    String buttonLabel = 'OK',
  }) {
    _showNotificationDialog(
      context,
      type: NotificationType.info,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onConfirm: onConfirm,
    );
  }

  /// Tampilkan error ketika wajah tidak terdaftar
  static void showFaceNotRegistered(
    BuildContext context, {
    VoidCallback? onGoToRegister,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: const Text('Wajah Belum Terdaftar', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.face_unlock_rounded,
              color: Colors.redAccent,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Wajah Anda belum terdaftar dalam sistem.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apa yang harus Anda lakukan:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const _InstructionStep(
                    number: '1',
                    text: 'Buka menu Face Registration',
                  ),
                  const SizedBox(height: 6),
                  const _InstructionStep(
                    number: '2',
                    text: 'Ambil foto wajah Anda dengan baik',
                  ),
                  const SizedBox(height: 6),
                  const _InstructionStep(
                    number: '3',
                    text: 'Tunggu proses registrasi selesai',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Setelah terdaftar, Anda dapat melakukan absensi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onGoToRegister?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Daftar Sekarang'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan error ketika wajah tidak cocok
  static void showFaceNotMatched(
    BuildContext context, {
    required double distance,
    VoidCallback? onRetry,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: const Text('Wajah Tidak Cocok', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.face_rounded, color: Colors.orange, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Wajah yang terdeteksi tidak sesuai dengan data terdaftar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Tips untuk hasil lebih baik:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const _TipItem(
                    icon: Icons.light_mode_rounded,
                    text: 'Pastikan cahaya cukup',
                  ),
                  const _TipItem(
                    icon: Icons.center_focus_strong_rounded,
                    text: 'Posisikan wajah di tengah',
                  ),
                  const _TipItem(
                    icon: Icons.remove_red_eye_rounded,
                    text: 'Lihat ke arah kamera',
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRetry?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan error jadwal tidak valid - Check In
  static void showCheckInScheduleError(
    BuildContext context, {
    String allowedStart = '06:30',
    String allowedEnd = '07:30',
    VoidCallback? onConfirm,
  }) {
    final now = DateTime.now();
    final currentTime = _formatTime(now);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: const Text(
          'Diluar Jadwal Check-in',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.orange, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Check-in hanya dapat dilakukan pada jam yang telah ditentukan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  _ScheduleRow(
                    label: 'Jam Check-in',
                    value: '$allowedStart - $allowedEnd',
                    icon: Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 8),
                  _ScheduleRow(
                    label: 'Waktu Sekarang',
                    value: currentTime,
                    icon: Icons.schedule_rounded,
                    isHighlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Silakan check-in pada jam yang telah ditentukan.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan error jadwal tidak valid - Check Out
  static void showCheckOutScheduleError(
    BuildContext context, {
    String allowedStart = '17:00',
    VoidCallback? onConfirm,
  }) {
    final now = DateTime.now();
    final currentTime = _formatTime(now);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: const Text('Belum Waktu Check-out', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.orange, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Check-out baru dapat dilakukan setelah jam yang ditentukan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  _ScheduleRow(
                    label: 'Jam Check-out Mulai',
                    value: allowedStart,
                    icon: Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 8),
                  _ScheduleRow(
                    label: 'Waktu Sekarang',
                    value: currentTime,
                    icon: Icons.schedule_rounded,
                    isHighlight: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan dialog ketika absen sudah lengkap
  static void showAttendanceCompleted(
    BuildContext context, {
    required DateTime checkInTime,
    required DateTime checkOutTime,
    VoidCallback? onConfirm,
  }) {
    final checkInFormatted = _formatTime(checkInTime);
    final checkOutFormatted = _formatTime(checkOutTime);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: const Text('Absen Sudah Lengkap', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Anda sudah melakukan check-in dan check-out hari ini.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _TimeRow(
                    label: 'Check-in',
                    time: checkInFormatted,
                    icon: Icons.login_rounded,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _TimeRow(
                    label: 'Check-out',
                    time: checkOutFormatted,
                    icon: Icons.logout_rounded,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan dialog ketika user baru check-in
  static void showCheckInSuccess(
    BuildContext context, {
    required DateTime checkInTime,
    VoidCallback? onConfirm,
  }) {
    final timeFormatted = _formatTime(checkInTime);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: const Text('Check-in Berhasil', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Absensi Anda sudah terekam.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: _TimeRow(
                label: 'Waktu Check-in',
                time: timeFormatted,
                icon: Icons.access_time_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Jangan lupa untuk check-out sebelum pulang.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan dialog ketika user baru check-out
  static void showCheckOutSuccess(
    BuildContext context, {
    required DateTime checkOutTime,
    required DateTime? checkInTime,
    VoidCallback? onConfirm,
  }) {
    final checkOutFormatted = _formatTime(checkOutTime);
    String durationText = '';

    if (checkInTime != null) {
      final duration = checkOutTime.difference(checkInTime);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      durationText = 'Durasi kerja: ${hours}j ${minutes}m';
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: const Text('Check-out Berhasil', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.orange,
              size: 72,
            ),
            const SizedBox(height: 16),
            const Text(
              'Anda sudah check-out. Selamat istirahat!',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  _TimeRow(
                    label: 'Waktu Check-out',
                    time: checkOutFormatted,
                    icon: Icons.access_time_rounded,
                    color: Colors.orange,
                  ),
                  if (durationText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      durationText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Tampilkan dialog schedule invalid
  static void showScheduleInvalid(
    BuildContext context, {
    required String message,
    required String allowedStart,
    required String allowedEnd,
    String? currentTime,
    VoidCallback? onConfirm,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: const Text('Jadwal Tidak Valid', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Jadwal Absen Berlaku',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dari:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        allowedStart,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sampai:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        allowedEnd,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (currentTime != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Waktu Sekarang:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          currentTime,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  /// Private method untuk menampilkan generic notification dialog
  static void _showNotificationDialog(
    BuildContext context, {
    required NotificationType type,
    required String title,
    required String message,
    required String buttonLabel,
    VoidCallback? onConfirm,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        title: Text(title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, color: type.color, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: type.color),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

/// Helper widget untuk menampilkan waktu
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String label;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                time,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper widget untuk menampilkan jadwal
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isHighlight ? Colors.redAccent : Colors.grey,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.redAccent : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper widget untuk menampilkan tips
class _TipItem extends StatelessWidget {
  const _TipItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

/// Helper widget untuk menampilkan instruction step
class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    );
  }
}
