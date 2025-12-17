import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../styles.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.instance.fetchAttendances();
  }

  Future<void> _reload() async {
    final future = ApiService.instance.fetchAttendances();
    setState(() {
      _future = future;
    });
    await future.catchError((_) => <Map<String, dynamic>>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground,
      appBar: AppBar(
        title: const Text('Attendance List'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _FilterChips(),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _ListSkeleton();
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        children: const [
                          Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Gagal memuat data absensi'))),
                        ],
                      );
                    }
                    final data = snapshot.data ?? [];
                    if (data.isEmpty) {
                      return ListView(
                        children: const [
                          Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data absensi'))),
                        ],
                      );
                    }
                    final mapped = data.map(_mapAttendance).toList();
                    return ListView.separated(
                      itemBuilder: (context, index) => _AttendanceTile(item: mapped[index]),
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemCount: mapped.length,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  static const List<String> filters = ['All', 'Completed', 'Pending', 'Late'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return ChoiceChip(
            label: Text(filters[index]),
            selected: selected,
            onSelected: (_) {},
            selectedColor: accentPurple.withOpacity(0.15),
            labelStyle: TextStyle(color: selected ? accentPurple : Colors.grey.shade700, fontWeight: FontWeight.w600),
            backgroundColor: Colors.white,
            shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade300)),
          );
        },
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.item});
  final _AttendanceItem item;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(item.dateLabel, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: theme.textTheme.bodySmall?.copyWith(color: item.statusColor, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _TimeLabel(label: 'Check In', time: item.checkIn),
                const SizedBox(width: 18),
                _TimeLabel(label: 'Check Out', time: item.checkOut),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({required this.label, required this.time});
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: Colors.redAccent, size: 20),
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

class _AttendanceItem {
  const _AttendanceItem({
    required this.title,
    required this.dateLabel,
    required this.checkIn,
    required this.checkOut,
    required this.statusLabel,
    required this.statusColor,
  });

  final String title;
  final String dateLabel;
  final String checkIn;
  final String checkOut;
  final String statusLabel;
  final Color statusColor;
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 16, width: 180, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Container(height: 16, width: 220, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(height: 18, width: 70, color: Colors.grey.shade200),
                const SizedBox(width: 18),
                Container(height: 18, width: 70, color: Colors.grey.shade200),
              ],
            ),
          ],
        ),
      ),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: 4,
    );
  }
}

_AttendanceItem _mapAttendance(Map<String, dynamic> raw) {
  DateTime? parseDate(String? value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String formatDate(DateTime? dt) {
    if (dt == null) return 'Unknown date';
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

  final statusRaw = (raw['status'] as String?)?.toLowerCase();
  String statusLabel;
  Color statusColor;
  if (statusRaw == 'pending') {
    statusLabel = 'Pending';
    statusColor = Colors.orange;
  } else if (statusRaw == 'late') {
    statusLabel = 'Late';
    statusColor = accentYellow;
  } else if (checkOut == null) {
    statusLabel = 'Pending';
    statusColor = Colors.orange;
  } else {
    statusLabel = 'Completed';
    statusColor = accentPurple;
  }

  final title = raw['title'] as String? ?? 'Attendance';

  return _AttendanceItem(
    title: title,
    dateLabel: formatDate(date),
    checkIn: formatTime(checkIn),
    checkOut: formatTime(checkOut),
    statusLabel: statusLabel,
    statusColor: statusColor,
  );
}
