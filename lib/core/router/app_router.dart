import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/today/today_screen.dart';
import '../../presentation/screens/calendar/calendar_screen.dart';
import '../../presentation/screens/sheets/sheets_screen.dart';
import '../../presentation/screens/daily/daily_view_screen.dart';
import '../../presentation/screens/shell/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/today',
          name: 'today',
          pageBuilder: (context, state) => NoTransitionPage(
            child: TodayScreen(date: _isoToday()),
          ),
        ),
        GoRoute(
          path: '/day/:date',
          name: 'day',
          pageBuilder: (context, state) {
            final date = state.pathParameters['date']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: DailyViewScreen(date: date),
              transitionsBuilder: (context, anim, secondaryAnim, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 220),
            );
          },
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalendarScreen(),
          ),
        ),
        GoRoute(
          path: '/sheets',
          name: 'sheets',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SheetsScreen(),
          ),
        ),
      ],
    ),
  ],
);

String _isoToday() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}
