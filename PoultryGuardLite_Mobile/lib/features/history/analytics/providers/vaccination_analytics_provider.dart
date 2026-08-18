import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../flock/models/entry_model.dart';
import '../models/vaccination_analytics.dart';

final vaccinationAnalyticsProvider = Provider.family<VaccinationAnalytics, List<EntryModel>>((ref, entries) {
  if (entries.isEmpty) return const VaccinationAnalytics();

  int completed = 0;
  int dueToday = 0;
  int dueThisWeek = 0;
  int overdue = 0;
  int upcoming = 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final endOfWeek = today.add(const Duration(days: 7));

  for (final entry in entries) {
    if (entry.vaccination.isNotEmpty && entry.vaccinationDate != null) {
      completed++;
    }
    
    if (entry.nextVaccinationDate != null) {
      final next = DateTime(
        entry.nextVaccinationDate!.year, 
        entry.nextVaccinationDate!.month, 
        entry.nextVaccinationDate!.day
      );
      
      if (next.isBefore(today)) {
        overdue++;
      } else if (next.isAtSameMomentAs(today)) {
        dueToday++;
      } else if (next.isBefore(endOfWeek)) {
        dueThisWeek++;
      } else {
        upcoming++;
      }
    }
  }
  
  final totalScheduled = completed + overdue + dueToday + dueThisWeek + upcoming;
  final compliance = totalScheduled > 0 ? (completed / totalScheduled) * 100 : 100.0;

  return VaccinationAnalytics(
    completed: completed,
    dueToday: dueToday,
    dueThisWeek: dueThisWeek,
    overdue: overdue,
    upcoming: upcoming,
    compliancePercentage: compliance,
  );
});
