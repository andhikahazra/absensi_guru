import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../styles.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  CameraController? _controller;
  late Future<void> _initFuture;
  bool _submitting = false;
  bool _isCheckOut = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
    _checkAttendanceStatus();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _controller = controller;
    await controller.initialize();
    if (!mounted) return;
    setState(() {});
  }

  /// Check apakah user sudah absen hari ini
  Future<void> _checkAttendanceStatus() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    try {
      final todayAttendance = await ApiService.instance.fetchTodayAttendance();

      if (!mounted) return;

      if (todayAttendance != null) {
        final status = AttendanceStatusData.fromJson(todayAttendance);

        if (status.isCompleted &&
            status.checkInTime != null &&
            status.checkOutTime != null) {
          NotificationDialogs.showAttendanceCompleted(
            context,
            checkInTime: status.checkInTime!,
            checkOutTime: status.checkOutTime!,
            onConfirm: () {},
          );
          setState(() => _isCheckOut = false);
          return;
        } else if (status.checkedIn &&
            !status.checkedOut &&
            status.checkInTime != null) {
          NotificationDialogs.showInfo(
            context,
            title: 'Check-in Sudah Dicatat',
            message:
                'Anda sudah check-in pada ${_formatTime(status.checkInTime!)}.\n\nSilakan ambil foto untuk check-out.',
            onConfirm: () {},
          );
          setState(() => _isCheckOut = true);
          return;
        }
      }

      _checkFaceRegistration();
    } catch (e) {
      if (mounted) {
        _checkFaceRegistration();
      }
    }
  }

  /// Check apakah wajah user sudah terdaftar
  Future<void> _checkFaceRegistration() async {
    try {
      final userProfile = ApiService.instance.currentUser;

      if (!mounted) return;

      print('[DEBUG] userProfile: $userProfile');

      // Handle berbagai tipe value: true/false, 1/0, "1"/"0", atau null
      bool faceRegistered = false;
      if (userProfile != null) {
        final faceReg = userProfile['face_registered'];
        final hasFace = userProfile['has_face'];

        print(
          '[DEBUG] face_registered: $faceReg (type: ${faceReg.runtimeType})',
        );
        print('[DEBUG] has_face: $hasFace (type: ${hasFace.runtimeType})');

        faceRegistered = _isTruthy(faceReg) || _isTruthy(hasFace);
      }

      print('[DEBUG] faceRegistered: $faceRegistered');

      if (!faceRegistered) {
        NotificationDialogs.showFaceNotRegistered(
          context,
          onGoToRegister: () {},
        );
      } else {
        NotificationDialogs.showInfo(
          context,
          title: 'Siap untuk Check-in',
          message:
              'Anda belum melakukan check-in hari ini.\n\nSilakan ambil foto wajah untuk check-in.',
          onConfirm: () {},
        );
        setState(() => _isCheckOut = false);
      }
    } catch (e) {
      if (mounted) {
        NotificationDialogs.showInfo(
          context,
          title: 'Siap untuk Check-in',
          message:
              'Anda belum melakukan check-in hari ini.\n\nSilakan ambil foto wajah untuk check-in.',
          onConfirm: () {},
        );
        setState(() => _isCheckOut = false);
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final hours = dateTime.hour.toString().padLeft(2, '0');
    final minutes = dateTime.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Helper untuk cek apakah value dianggap "truthy"
  /// Handle: true/false, 1/0, "1"/"0", "true"/"false"
  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture(BuildContext context) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (ApiService.instance.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login ulang, token tidak ditemukan.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final shot = await controller.takePicture();
      final result = await ApiService.instance.verifyFace(
        file: File(shot.path),
      );
      if (!mounted) return;

      print('[DEBUG] verifyFace response: $result');

      final status = result['status'] as String?;
      final errorType = result['type'] as String?;
      final message = result['message'] as String?;

      if (status == 'error') {
        if (errorType == 'face_not_registered') {
          NotificationDialogs.showFaceNotRegistered(
            context,
            onGoToRegister: () {},
          );
        } else if (errorType == 'schedule_invalid') {
          // Message dari backend sudah cukup lengkap
          _showFailure(message ?? 'Jadwal tidak sesuai untuk absensi.');
        } else {
          _showFailure(message ?? 'Verifikasi gagal. Coba lagi.');
        }
        return;
      }

      final matched = (result['match'] == true) || (result['matched'] == true);
      if (matched) {
        // Update state berdasarkan attendance_type dari backend
        final attendanceType = result['attendance_type'] as String?;
        setState(() {
          _isCheckOut = attendanceType == 'check-out';
        });
        _showSuccess(context, result);
      } else {
        final distance = result['distance'] as num?;
        NotificationDialogs.showFaceNotMatched(
          context,
          distance: distance?.toDouble() ?? 0.0,
          onRetry: () {},
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('[ERROR] verifyFace error: $e');
      _showFailure(
        'Verifikasi gagal. Coba lagi atau periksa koneksi internet Anda.\n\nError: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSuccess(BuildContext context, Map<String, dynamic> result) {
    if (_isCheckOut) {
      final checkOutTime = DateTime.now();
      DateTime? checkInTime;
      if (result['attendance'] is Map &&
          result['attendance']['check_in'] is String) {
        checkInTime = DateTime.parse(
          result['attendance']['check_in'] as String,
        );
      }

      NotificationDialogs.showCheckOutSuccess(
        context,
        checkOutTime: checkOutTime,
        checkInTime: checkInTime,
        onConfirm: () {
          Navigator.pop(context);
        },
      );
    } else {
      final checkInTime = DateTime.now();
      NotificationDialogs.showCheckInSuccess(
        context,
        checkInTime: checkInTime,
        onConfirm: () {
          Navigator.pop(context);
        },
      );
    }
  }

  void _showFailure(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verifikasi gagal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonText = _isCheckOut
        ? 'Capture & Check Out'
        : 'Capture & Check In';
    final buttonColor = _isCheckOut ? Colors.orange : accentPurple;
    final appBarTitle = _isCheckOut ? 'Check Out' : 'Check In';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: FutureBuilder<void>(
                  future: _initFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    if (snapshot.hasError ||
                        _controller == null ||
                        !_controller!.value.isInitialized) {
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            'Kamera tidak tersedia',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      );
                    }
                    return CameraPreview(_controller!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: const [
                _Tip(icon: Icons.wifi_tethering_rounded, label: 'Signal bagus'),
                _Tip(icon: Icons.light_mode_rounded, label: 'Cahaya cukup'),
                _Tip(icon: Icons.place_rounded, label: 'Aktifkan lokasi'),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _capture(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: softBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accentPurple),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
