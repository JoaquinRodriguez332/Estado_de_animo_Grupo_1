import 'dart:convert';
import 'package:http/http.dart' as http;

class MotivationalMessageService {
  static const String apiUrl = 'https://zenquotes.io/api/random';

  Future<String> fetchMotivationalMessage() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]['q'] != null) {
          return data[0]['q'];
        }
      }
    } catch (e) {
      print('Error fetching motivational message: $e');
    }
    return 'Ten un excelente día!';
  }
}