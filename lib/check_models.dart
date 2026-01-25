import 'package:google_generative_ai/google_generative_ai.dart';

const String apiKey = 'AIzaSyDYs4JG30bVoup9eGSgP_hSmyd_Bn7oQnw'; 

void main() async {
  print("🔍 Diagnóstico Extendido de API Key...");
  
  final candidates = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro',
    'gemini-1.0-pro', 
    'gemini-pro'
  ];

  for (var name in candidates) {
    print("\n--- Probando '$name' ---");
    final model = GenerativeModel(model: name, apiKey: apiKey);
    try {
      final response = await model.generateContent([Content.text('Hola')]);
      print("✅ ¡EXITO! Modelo '$name' FUNCIONA.");
      print("Respuesta: ${response.text}");
      return; // Salimos si encontramos uno
    } catch (e) {
      print("❌ Falló: ${e.toString().split('\n').first}");
    }
  }
  print("\n⚠️ Ningún modelo funcionó. Verifica que la API 'Generative Language API' esté habilitada en Google Cloud Console.");
}
