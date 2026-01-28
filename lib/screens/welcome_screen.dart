import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ICONO Y TÍTULO
                const Icon(Icons.school, size: 80, color: Colors.indigo),
                const SizedBox(height: 20),
                const Text(
                  "Aula Cibermedida",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  "Herramienta de Autor SCORM",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 30,
                  runSpacing: 20,
                  children: [
                    SizedBox(
                      width: 360,
                      child: _buildCard(
                        context,
                        title: "Crear Nuevo Curso",
                        desc: "Empieza un proyecto desde cero con IA.",
                        icon: Icons.add_circle,
                        color: Colors.indigo,
                        onTap: () => context.push('/create-course'),
                      ),
                    ),
                    SizedBox(
                      width: 360,
                      child: _buildCard(
                        context,
                        title: "Mis Cursos",
                        desc: "Gestiona y edita tus cursos guardados.",
                        icon: Icons.folder_open,
                        color: Colors.teal,
                        // ✅ Ahora apunta a la ruta que creamos en el main
                        onTap: () => context.push('/saved-courses'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {
    required String title, 
    required String desc, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

}
