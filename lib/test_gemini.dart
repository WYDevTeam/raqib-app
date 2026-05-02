import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final envFile = File('e:/Flutter Projects/raqib/.env');
  if (!envFile.existsSync()) {
    print('No .env file found');
    return;
  }
  
  final lines = envFile.readAsLinesSync();
  String? apiKey;
  for (final line in lines) {
    if (line.trim().startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }
  
  if (apiKey == null || apiKey.isEmpty) {
    print('GEMINI_API_KEY not found in .env');
    return;
  }
  
  final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
  final response = await http.get(Uri.parse(url));
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final models = data['models'] as List<dynamic>?;
    if (models != null) {
      for (final m in models) {
        print(m['name']);
      }
    }
  } else {
    print('Error: \${response.statusCode}');
    print(response.body);
  }
}
