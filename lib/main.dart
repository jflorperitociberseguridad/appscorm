import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/theme.dart';

// Importaciones de pantallas
import 'screens/welcome_screen.dart';
import 'screens/create_course_screen.dart';
import 'screens/course_dashboard_screen.dart'; 
import 'screens/saved_courses_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Inicialización de Firebase con control de errores para entorno web
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (safe mode): $e');
  }

  runApp(const ProviderScope(child: ScormMasterApp()));
}

// CONFIGURACIÓN DE RUTAS (GoRouter)
final _router = GoRouter(
  initialLocation: '/', 
  routes: [
    // 1. PANTALLA DE INICIO (BIENVENIDA)
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    
    // 2. PANTALLA INTERMEDIA (PROMPT / IA)
    GoRoute(
      path: '/create-course',
      builder: (context, state) => const CreateCourseScreen(),
    ),

    // 3. PANTALLA DE BIBLIOTECA (CURSOS GUARDADOS)
    GoRoute(
      path: '/saved-courses',
      builder: (context, state) => const SavedCoursesScreen(),
    ),

    // 4. PANTALLA DEL EDITOR (DASHBOARD)
    GoRoute(
      path: '/course-dashboard',
      builder: (context, state) {
        // Recibe los datos del curso como un Map dinámico
        final data = state.extra as Map<String, dynamic>?;
        return CourseDashboardScreen(courseData: data);
      },
    ),
  ],
);

class ScormMasterApp extends StatelessWidget {
  const ScormMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aula Cibermedida', 
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, 
      routerConfig: _router,
    );
  }
}
