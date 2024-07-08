import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MiResumenScreen extends StatefulWidget {
  const MiResumenScreen({super.key});

  @override
  _MiResumenScreenState createState() => _MiResumenScreenState();
}

class _MiResumenScreenState extends State<MiResumenScreen> {
  late List<dynamic> _weeklyEvents;
  late String _weeklyAnalysis;
  late String _weekendTips;

  @override
  void initState() {
    super.initState();
    _weeklyEvents = [];
    _weeklyAnalysis = '';
    _weekendTips = '';
    _fetchWeeklyData();
  }

  Future<void> _fetchWeeklyData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Obtener eventos semanales de Firestore
    QuerySnapshot weeklyQuery = await FirebaseFirestore.instance
        .collection('estado_de_animo')
        .where('userId', isEqualTo: user.uid)
        .where('timestamp', isGreaterThanOrEqualTo: startOfWeek)
        .where('timestamp', isLessThanOrEqualTo: endOfWeek)
        .get();

    // Inicializar con días de la semana completos
    List<dynamic> weeklyEvents = List.filled(7, null);

    // Llenar la lista con datos obtenidos
    for (var doc in weeklyQuery.docs) {
      DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();
      int dayIndex = timestamp.weekday - 1; // Índice de día de la semana (0=lunes, ..., 6=domingo)
      weeklyEvents[dayIndex] = doc.data();
    }

    setState(() {
      _weeklyEvents = weeklyEvents;
    });

    // Generar el análisis semanal
    await _generateWeeklyAnalysis();

    // Obtener tips para el fin de semana
    await _generateWeekendTips();
  }

  Future<void> _generateWeeklyAnalysis() async {
    // Generar el análisis basado en los eventos obtenidos o establecer "sin información"
    Map<String, dynamic> weeklyData = {};

    // Nombres de días de la semana en español
    List<String> weekDays = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];

    // Llenar con "sin información" por defecto
    for (var day in weekDays) {
      weeklyData[day] = {
        'mood': 'sin información',
        'emotions': ['sin información'],
      };
    }

    // Llenar con datos reales si están disponibles
    _weeklyEvents.asMap().forEach((index, event) {
      if (event != null) {
        DateTime timestamp = (event['timestamp'] as Timestamp).toDate();
        String dayName = weekDays[timestamp.weekday - 1];
        weeklyData[dayName] = {
          'mood': event['mood'],
          'emotions': event['emotions'],
        };
      }
    });

    var apiUrl = 'https://api.openai.com/v1/chat/completions';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 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',
    };

    var prompt = 'Analiza mi estado de ánimo y emociones de la semana y dame recomendaciones en máximo 150 tokens:\n';
    weeklyData.forEach((day, data) {
      prompt += '$day: estado de ánimo: ${data['mood']}, emociones: ${data['emotions'].join(', ')}\n';
    });

    var body = jsonEncode({
      'model': 'gpt-4',
      'messages': [
        {
          'role': 'system',
          'content': prompt,
        }
      ],
      'max_tokens': 150, // Ajusta según sea necesario
    });

    var response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);
    print('Body enviado a la API: $body');
    print('Respuesta de la API: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var tips = [];

      for (var choice in jsonResponse['choices']) {
        var tip = choice['message']['content'];
        tips.add(tip);
      }

      setState(() {
        _weeklyAnalysis = tips.join('\n\n');
      });
    } else {
      setState(() {
        _weeklyAnalysis = 'Error al obtener análisis';
      });
    }
  }

  Future<void> _generateWeekendTips() async {
    var apiUrl = 'https://api.openai.com/v1/chat/completions';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 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',
    };

    var prompt = 'Genera tips para el fin de semana basados en el análisis semanal concisos no más de tres max 100 tokens:\n';
    prompt += _weeklyAnalysis; // Usando el análisis semanal como base para los tips

    var body = jsonEncode({
      'model': 'gpt-4',
      'messages': [
        {
          'role': 'system',
          'content': prompt,
        }
      ],
      'max_tokens': 100, // Ajusta según sea necesario
    });

    var response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);
    print('Body enviado a la API: $body');
    print('Respuesta de la API: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      var tips = [];

      for (var choice in jsonResponse['choices']) {
        var tip = choice['message']['content'];
        tips.add(tip);
      }

      setState(() {
        _weekendTips = tips.join('\n\n');
      });
    } else {
      setState(() {
        _weekendTips = 'Error al obtener tips para el fin de semana';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Resumen Semanal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              decoration: BoxDecoration(
                color: Colors.orange[200],
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Análisis de tu semana:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    _weeklyAnalysis.isEmpty ? 'Analizando' : _weeklyAnalysis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.green[200],
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tips para el Fin de Semana:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    _weekendTips.isEmpty ? 'Generando tips...' : _weekendTips,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
