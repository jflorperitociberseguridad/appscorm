import 'package:google_generative_ai/google_generative_ai.dart';

const String apiKey = 'AIzaSyDYs4JG30bVoup9eGSgP_hSmyd_Bn7oQnw'; 

void main() async {
  final candidates = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-latest',
    'gemini-1.5-pro',
    'gemini-1.0-pro', 
    'gemini-pro'
  ];

  for (var name in candidates) {
    final model = GenerativeModel(model: name, apiKey: apiKey);
    try {
      await model.generateContent([Content.text('Hola')]);
      return; // Salimos si encontramos uno
    } catch (_) {
      // Ignora el modelo fallido y prueba el siguiente.
    }
  }
}
