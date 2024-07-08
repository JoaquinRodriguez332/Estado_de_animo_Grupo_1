import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DailyQuoteScreen extends StatefulWidget {
  const DailyQuoteScreen({super.key});

  @override
  _DailyQuoteScreenState createState() => _DailyQuoteScreenState();
}

class _DailyQuoteScreenState extends State<DailyQuoteScreen> {
  String _quote = '';
  String _quoteDate = '';
  final String _localImagePath = '/Users/joaquin/Desktop/Trabajo/testeo_base/lib/assests/diario.jpg'; // Ruta a tu imagen local

  @override
  void initState() {
    super.initState();
    _loadDailyQuote();
  }

  Future<void> _loadDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // Solo la parte de la fecha

    if (prefs.containsKey('daily_quote') && prefs.containsKey('quote_date')) {
      final storedQuote = prefs.getString('daily_quote')!;
      final storedDate = prefs.getString('quote_date')!;

      if (storedDate == today) {
        setState(() {
          _quote = storedQuote;
          _quoteDate = storedDate;
        });
        return;
      }
    }

    await _getDailyQuote();
  }

  Future<void> _getDailyQuote() async {
    var apiUrl = 'https://api.openai.com/v1/chat/completions';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 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',
    };

    var body = jsonEncode({
      'model': 'gpt-4',
      'messages': [
        {
          'role': 'system',
          'content': 'Genera una frase motivacional para el día.'
        }
      ],
      'max_tokens': 40,
    });

    var response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);
    print('Body enviado a la API: $body');
    print('Respuesta de la API: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

      var quote = jsonResponse['choices'][0]['message']['content'];
      final today = DateTime.now().toIso8601String().split('T')[0]; // Solo la parte de la fecha

      setState(() {
        _quote = quote;
        _quoteDate = today;
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('daily_quote', quote);
      prefs.setString('quote_date', today);
    } else {
      setState(() {
        _quote = 'Error al obtener la frase del día';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Frase del Día'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _localImagePath.isNotEmpty
                  ? Image.asset(
                _localImagePath,
                width: double.infinity,
                height: 200.0,
                fit: BoxFit.cover,
              )
                  : const SizedBox.shrink(),
              const SizedBox(height: 16.0),
              _quote.isEmpty
                  ? const CircularProgressIndicator()
                  : Text(
                _quote,
                style: const TextStyle(fontSize: 24.0, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

