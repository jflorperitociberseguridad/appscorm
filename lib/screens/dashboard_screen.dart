import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/course_model.dart';
import '../providers/api_providers.dart';
import '../providers/course_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _showLoginDialog(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (dialogContext, dialogRef, child) {
          final authState = dialogRef.watch(authNotifierProvider);
          final isLoading = authState.isLoading;
          final hasError = authState.error != null;
          return AlertDialog(
            title: const Text('Autenticación JWT'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                if (hasError) ...[
                  const SizedBox(height: 12),
                  Text(authState.error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        await dialogRef.read(authNotifierProvider.notifier).login(
                              email: emailController.text.trim(),
                              password: passwordController.text,
                            );
                        if (dialogRef.read(authNotifierProvider).token != null) {
                          Navigator.pop(dialogContext);
                          dialogRef.read(coursesListProvider.notifier).refresh();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sesión JWT iniciada')),
                          );
                        }
                      },
                child: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Iniciar sesión'),
              ),
            ],
          );
        },
      ),
    );

    emailController.dispose();
    passwordController.dispose();
  }

  void _openCourse(BuildContext context, WidgetRef ref, CourseModel course) {
    ref.read(courseProvider.notifier).setCourse(course);
    context.push('/editor');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesListProvider);
    final authState = ref.watch(authNotifierProvider);
    final currentCourse = ref.watch(courseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Aula Cibermedida', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar lista',
            onPressed: () => ref.read(coursesListProvider.notifier).refresh(),
          ),
          IconButton(
            icon: Icon(authState.token != null ? Icons.logout : Icons.login),
            tooltip: authState.token != null ? 'Cerrar sesión JWT' : 'Iniciar sesión JWT',
            onPressed: () {
              if (authState.token != null) {
                ref.read(authNotifierProvider.notifier).logout();
                ref.read(coursesListProvider.notifier).refresh();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
              } else {
                _showLoginDialog(context, ref);
              }
            },
          ),
        ],
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty && currentCourse == null) {
            return _buildEmptyState(context, ref);
          }
          return _buildCourseList(context, ref, courses);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Error al cargar cursos: ${error.toString()}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(coursesListProvider.notifier).refresh(),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create'),
        label: const Text('Nuevo Curso'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authNotifierProvider).token != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              'Bienvenido al Generador SCORM',
              style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isLoggedIn
                  ? 'Tu cuenta aún no tiene cursos guardados. Crea uno nuevo para sincronizar con la API.'
                  : 'Necesitas autenticarte con un token JWT para sincronizar la librería.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showLoginDialog(context, ref),
              icon: const Icon(Icons.login),
              label: const Text('Autenticarse'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(BuildContext context, WidgetRef ref, List<CourseModel> courses) {
    final currentCourse = ref.watch(courseProvider);
    final children = <Widget>[];

    if (currentCourse != null) {
      children.add(_buildCourseTile(context, ref, currentCourse, isDraft: true));
      children.add(const SizedBox(height: 16));
    }

    if (courses.isEmpty) {
      children.add(const Center(child: Text('Aún no hay cursos sincronizados.')));
    } else {
      children.addAll(courses.map((course) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildCourseTile(context, ref, course),
          )));
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }

  Widget _buildCourseTile(BuildContext context, WidgetRef ref, CourseModel course, {bool isDraft = false}) {
    return Card(
      elevation: isDraft ? 6 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _openCourse(context, ref, course),
        leading: CircleAvatar(
          backgroundColor: isDraft ? Colors.teal.shade50 : Colors.indigo.shade50,
          child: Icon(isDraft ? Icons.edit : Icons.book, color: isDraft ? Colors.teal : Colors.indigo),
        ),
        title: Text(course.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(isDraft ? 'Borrador local · ${course.modules.length} módulos' : '${course.modules.length} módulos'),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          tooltip: 'Abrir editor',
          onPressed: () => _openCourse(context, ref, course),
        ),
      ),
    );
  }
}
