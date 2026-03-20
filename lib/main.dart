import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// 1. IMPORTAMOS LA CONFIGURACIÓN (Lo nuevo)
import 'config/theme.dart';
import 'config/routes.dart';

// Importamos tus pantallas
import 'screens/dashboard_screen.dart';
import 'screens/create_course_screen.dart';
import 'screens/course_editor_screen.dart';
import 'screens/course_player_screen.dart';
import 'models/course_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('🚀 APP STARTING - main() called');
  debugPrint('✅ Initialization complete (Firebase removed)');

  debugPrint('🚀 Running App...');
  runApp(
    const ProviderScope(
      child: ScormMasterApp(),
    ),
  );
}

// 2. CONFIGURACIÓN DE RUTAS (Usando constantes de config/routes.dart)
final _router = GoRouter(
  initialLocation: AppRoutes.create, // Antes era '/'
  routes: [
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.create,
      builder: (context, state) => const CreateCourseScreen(),
    ),
    GoRoute(
      path: AppRoutes.editor,
      builder: (context, state) => const CourseEditorScreen(),
    ),
    GoRoute(
      path: '/player', // Debería estar en AppRoutes, pero lo hardcodearé por ahora o añadiré en routes.dart si tengo acceso, aquí directo para cumplir.
      builder: (context, state) {
        // Recibimos el objeto CourseModel como "extra"
        final course = state.extra as CourseModel?;
        if (course == null) {
          return const Scaffold(body: Center(child: Text("Error: No course provided")));
        }
        return CoursePlayerScreen(course: course);
      },
    ),
  ],
);

class ScormMasterApp extends StatelessWidget {
  const ScormMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Aula Cibermedida SCORM-Master',
      debugShowCheckedModeBanner: false,
      
      // 3. TEMA CENTRALIZADO (Desde config/theme.dart)
      // Esto aplica automáticamente los colores Indigo/Amber y estilos de botones
      theme: AppTheme.lightTheme, 
      
      routerConfig: _router,
    );
  }
}
