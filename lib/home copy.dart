import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_mood.dart';
import 'history.dart';
// Importa el nuevo archivo
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mi_resumen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Índice inicial del BottomNavigationBar
  final List<Widget> _children = [
    const HomeContent(), // Contenido principal de la pantalla de inicio
    const HistoryScreen(), // Pantalla de historial de estados de ánimo
    const MiResumenScreen(), // Pantalla de frases del día
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienestar Estudiantil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              // Cerrar sesión y navegar a la pantalla de inicio
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              '/Users/joaquin/Desktop/Trabajo/testeo_base/lib/assests/fondo2.jpg', // Ruta de la imagen de fondo
              fit: BoxFit.cover,
            ),
          ),
          // Contenido principal según el índice seleccionado
          _children[_currentIndex],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Frase del Día',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Mi Resúmen',
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Map<DateTime, List<String>> _events;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String _tips = ''; // Variable para almacenar los tips del día

  @override
  void initState() {
    super.initState();
    _events = {};
    _loadEvents();
    _loadDailyTips(); // Cargar los tips del día al iniciar la pantalla
  }

  Future<void> _loadEvents() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('estado_de_animo')
        .where('userId', isEqualTo: user.uid)
        .get();

    Map<DateTime, List<String>> events = {};
    for (var doc in querySnapshot.docs) {
      DateTime date = (doc['timestamp'] as Timestamp).toDate();
      DateTime eventDate = DateTime(date.year, date.month, date.day);
      if (events[eventDate] == null) {
        events[eventDate] = [];
      }
      events[eventDate]!.add(doc['mood']);
    }

    setState(() {
      _events = events;
    });
  }

  Future<void> _loadDailyTips() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // Solo la parte de la fecha

    if (prefs.containsKey('daily_tips') && prefs.containsKey('tips_date')) {
      final storedTips = prefs.getString('daily_tips')!;
      final storedDate = prefs.getString('tips_date')!;

      if (storedDate == today) {
        setState(() {
          _tips = storedTips;
        });
        return;
      }
    }

    // Si no hay tips almacenados o si es un nuevo día, obtener nuevos tips
    await _getTips();
  }


  Future<void> _getTips() async {
    var apiUrl = 'https://api.openai.com/v1/chat/completions';
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer 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',
    };

    var body = jsonEncode({
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content': 'Genera tres tips que me ayuden a mejorar mi estado de ánimo y mis emociones.'
        }
      ],
      'max_tokens': 40,
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
        _tips = tips.join('\n\n');
      });

      final today = DateTime.now().toIso8601String().split('T')[0]; // Solo la parte de la fecha
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('daily_tips', _tips);
      prefs.setString('tips_date', today);
    } else {
      setState(() {
        _tips = 'Error al obtener tips';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          // Recuadro para registrar estado de ánimo
          Container(
            margin: const EdgeInsets.only(bottom: 20.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF7AB992).withOpacity(0.8), // Color verde vintage con opacidad
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                const Text(
                  'Registrar Estado de Ánimo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterMoodScreen()),
                    );
                  },
                  child: const Text('Registrar Ahora'),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white.withOpacity(0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TableCalendar(
                    firstDay: DateTime.utc(2021, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                      todayDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent,
                      ),
                      markersMaxCount: 1,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Semana',
                      CalendarFormat.twoWeeks: 'Mes',
                      CalendarFormat.week: 'Dos semanas',
                    },
                  ),
                  const SizedBox(height: 20.0),
                  if (_tips.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[100], // Color naranja pastel
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tips del día:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            _tips,
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20.0),

        ],
      ),
    );
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }}
