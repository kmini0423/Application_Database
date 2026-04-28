import 'package:flutter/material.dart';
import 'screens/hello_world_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/event_list_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/report_screen.dart';

void main() {
  runApp(const CarMeetApp());
}
class CarMeetApp extends StatelessWidget {
  const CarMeetApp({super.key});






  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFEEE9E0);




    return MaterialApp(
      title: 'Cars & Coffee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
        ),
        scaffoldBackgroundColor: primaryColor,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HelloWorldScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/event-list': (context) => const EventListScreen(),
        '/report': (context) => const ReportScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/admin-dashboard') {
          final openCreate = settings.arguments is Map &&
              (settings.arguments as Map)['openCreate'] == true;
          return MaterialPageRoute(
            builder: (context) =>
                AdminDashboardScreen(openCreateOnLoad: openCreate),
          );
        }
        if (settings.name == '/event-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EventDetailScreen(
              eventId: args['eventId'] as int,
            ),
          );
        }
        return null;
      },
    );
  }
}
