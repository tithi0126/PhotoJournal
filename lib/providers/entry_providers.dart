import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/models/entry_model.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final entryRepositoryProvider = Provider<EntryRepository>((ref) {
  return EntryRepository();
});

// ---------------------------------------------------------------------------
// Today's entry
// ---------------------------------------------------------------------------

final todayEntryProvider = FutureProvider<EntryModel?>((ref) async {
  final repo = ref.watch(entryRepositoryProvider);
  final today = _isoToday();
  return repo.getEntryForDate(today);
});

// ---------------------------------------------------------------------------
// Entry by date (for daily view and calendar tap)
// ---------------------------------------------------------------------------

final entryByDateProvider = FutureProvider.family<EntryModel?, String>((ref, isoDate) async {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.getEntryForDate(isoDate);
});

// ---------------------------------------------------------------------------
// Entries for a given month 'YYYY-MM'
// ---------------------------------------------------------------------------

final monthEntriesProvider = FutureProvider.family<List<EntryModel>, String>((ref, yearMonth) async {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.getEntriesForMonth(yearMonth);
});

// ---------------------------------------------------------------------------
// All dates → thumb path map (for calendar grid)
// ---------------------------------------------------------------------------

final dateThumbMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final repo = ref.watch(entryRepositoryProvider);
  return repo.getDateToThumbMap();
});

// ---------------------------------------------------------------------------
// Selected date for calendar / daily view navigation
// ---------------------------------------------------------------------------

final selectedDateProvider = StateProvider<String>((ref) => _isoToday());

// ---------------------------------------------------------------------------
// Focused calendar month 'YYYY-MM'
// ---------------------------------------------------------------------------

final calendarMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

String _isoToday() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}
