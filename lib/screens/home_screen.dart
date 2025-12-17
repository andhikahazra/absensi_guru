import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _attFuture;

  @override
  void initState() {
    super.initState();
    _attFuture = ApiService.instance.fetchAttendances();
  }

  Future<void> _reload() async {
    final future = ApiService.instance.fetchAttendances();
    setState(() {
      _attFuture = future;
    });
    await future.catchError((_) => <Map<String, dynamic>>[]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: softBackground,
      body: RefreshIndicator(
        onRefresh: _reload,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 260,
                  decoration: BoxDecoration(gradient: headerGradient),
                ),
                Positioned(
                  right: -40,
                  top: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Morning,', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(
                                (ApiService.instance.currentUser?['name'] as String?) ?? 'User',
                                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text('Business Process Development', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                            ],
                          ),
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=47'),
                            backgroundColor: Colors.white.withOpacity(0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Card(
                        shape: defaultCardShape,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Working Schedule', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text('Today', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('09:00 - 18:00', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: accentPurple.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.watch_later_outlined, size: 18, color: accentPurple),
                                        const SizedBox(width: 6),
                                        Text('Office', style: theme.textTheme.bodyMedium?.copyWith(color: accentPurple, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/checkin');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentPurple,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text('Check In'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: defaultCardShape,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _QuickAction(label: 'Attendance\nList', icon: Icons.list_alt_rounded),
                          _QuickAction(label: 'Attendance\nCorrection', icon: Icons.edit_calendar_rounded),
                          _QuickAction(label: 'On Duty', icon: Icons.flight_takeoff_rounded),
                          _QuickAction(label: 'Leave', icon: Icons.beach_access_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Attendance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _attFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const _AttendanceSkeleton();
                      }
                      if (snapshot.hasError) {
                        return Text('Gagal memuat data absensi');
                      }
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return Text('Belum ada data', style: theme.textTheme.bodyMedium);
                      }
                      return Column(
                        children: data.take(2).map((e) {
                          final mapped = _mapAttendance(e);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AttendanceCard(
                              dateLabel: mapped.dateLabel,
                              startTime: mapped.checkIn,
                              endTime: mapped.checkOut,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.dateLabel,
    required this.startTime,
    required this.endTime,
  });

  final String dateLabel;
  final String startTime;
  final String endTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: defaultCardShape,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text('View', style: theme.textTheme.bodyMedium?.copyWith(color: accentPurple, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PinTime(label: 'Start Day', time: startTime),
                const SizedBox(width: 20),
                _PinTime(label: 'End Day', time: endTime),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceSkeleton extends StatelessWidget {
  const _AttendanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkeletonBox(),
        SizedBox(height: 10),
        _SkeletonBox(),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 16, width: 160, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(height: 18, width: 80, color: Colors.grey.shade200),
              const SizedBox(width: 20),
              Container(height: 18, width: 80, color: Colors.grey.shade200),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceViewData {
  _AttendanceViewData({
    required this.dateLabel,
    required this.checkIn,
    required this.checkOut,
  });

  final String dateLabel;
  final String checkIn;
  final String checkOut;
}

_AttendanceViewData _mapAttendance(Map<String, dynamic> raw) {
  DateTime? parseDate(String? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayLabel = days[(dt.weekday - 1).clamp(0, 6)];
    final monthLabel = months[(dt.month - 1).clamp(0, 11)];
    return '$dayLabel, ${dt.day.toString().padLeft(2, '0')} $monthLabel ${dt.year}';
  }

  String formatTime(DateTime? dt) {
    if (dt == null) return '--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  final dateValue = raw['date'] as String? ?? raw['check_in'] as String? ?? raw['checkin_at'] as String? ?? raw['created_at'] as String?;
  final checkInValue = raw['check_in'] as String? ?? raw['checkin_at'] as String?;
  final checkOutValue = raw['check_out'] as String? ?? raw['checkout_at'] as String?;

  final date = parseDate(dateValue) ?? parseDate(checkInValue);
  final checkIn = parseDate(checkInValue);
  final checkOut = parseDate(checkOutValue);

  return _AttendanceViewData(
    dateLabel: formatDate(date),
    checkIn: formatTime(checkIn),
    checkOut: formatTime(checkOut),
  );
}

class _PinTime extends StatelessWidget {
  const _PinTime({required this.label, required this.time});
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.place, color: Colors.redAccent, size: 20),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
            Text(time, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: softBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: accentPurple, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
