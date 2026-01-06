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
  bool _attendanceCompleted = false; // Tambah ini

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

      print('[DEBUG] fetchTodayAttendance response: $todayAttendance');

      if (todayAttendance != null) {
        try {
          final status = AttendanceStatusData.fromJson(todayAttendance);

          print('[DEBUG] AttendanceStatusData parsed:');
          print('[DEBUG]   isCompleted: ${status.isCompleted}');
          print('[DEBUG]   checkedIn: ${status.checkedIn}');
          print('[DEBUG]   checkedOut: ${status.checkedOut}');
          print('[DEBUG]   checkInTime: ${status.checkInTime}');
          print('[DEBUG]   checkOutTime: ${status.checkOutTime}');

          if (status.isCompleted &&
              status.checkInTime != null &&
              status.checkOutTime != null) {
            print('[DEBUG] Showing: Attendance Completed');
            setState(() => _attendanceCompleted = true);
            NotificationDialogs.showAttendanceCompleted(
              context,
              checkInTime: status.checkInTime!,
              checkOutTime: status.checkOutTime!,
              onConfirm: () {
                // Balik ke home setelah dismiss dialog
                Navigator.pop(context);
              },
            );
            return;
          } else if (status.checkedIn &&
              !status.checkedOut &&
              status.checkInTime != null) {
            print(
              '[DEBUG] Showing: Check-in Already Recorded (Ready to Check-out)',
            );
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
        } catch (parseError) {
          print('[ERROR] AttendanceStatusData parsing error: $parseError');
          print('[ERROR] todayAttendance data: $todayAttendance');
        }
      } else {
        print('[DEBUG] todayAttendance is null');
      }

      print('[DEBUG] Showing: Check Face Registration (ready to check-in)');
      _checkFaceRegistration();
    } catch (e) {
      if (mounted) {
        print('[ERROR] _checkAttendanceStatus error: $e');
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
      print('[DEBUG] userProfile keys: ${userProfile?.keys.toList()}');

      // Cek apakah face_encoding ada dan tidak kosong
      bool faceRegistered = false;
      if (userProfile != null) {
        final hasFaceEncodingKey = userProfile.containsKey('face_encoding');
        print('[DEBUG] has face_encoding key: $hasFaceEncodingKey');

        if (hasFaceEncodingKey) {
          final faceEncoding = userProfile['face_encoding'];
          print('[DEBUG] face_encoding value: $faceEncoding');
          print('[DEBUG] face_encoding type: ${faceEncoding.runtimeType}');
          print('[DEBUG] face_encoding is list: ${faceEncoding is List}');

          if (faceEncoding is List) {
            faceRegistered = faceEncoding.isNotEmpty;
            print('[DEBUG] face_encoding length: ${faceEncoding.length}');
          } else if (faceEncoding == null) {
            print('[DEBUG] face_encoding is null - user belum register face');
          }
        }
      }

      print('[DEBUG] faceRegistered: $faceRegistered');

      if (!faceRegistered) {
        NotificationDialogs.showFaceNotRegistered(
          context,
          onGoToRegister: () {
            // Navigate ke face register screen
            Navigator.pushNamed(context, '/face-register');
          },
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
    // Convert UTC to local timezone
    final local = dateTime.toLocal();
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
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
            onGoToRegister: () {
              // Navigate ke face register screen
              Navigator.pushNamed(context, '/face-register');
            },
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
            if (_attendanceCompleted)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Absensi Sudah Lengkap',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check-in dan check-out sudah dicatat hari ini.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
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
