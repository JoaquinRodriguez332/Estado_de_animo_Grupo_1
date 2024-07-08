import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // Importa http para usar post
import 'dart:convert'; // Importa dart:convert para usar jsonEncode y jsonDecode
import 'package:table_calendar/table_calendar.dart'; // Importa table_calendar para usar TableCalendar

import 'history.dart';
import 'mi_resumen.dart';
import 'register_mood.dart';

// Archivo para almacenar configuraciones y claves API

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late DateTime _today;
  final List<Widget> _children = [
    const HomeContent(),
    const HistoryScreen(),
    const MiResumenScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienestar Estudiantil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              '/Users/joaquin/Desktop/Trabajo/testeo_base/lib/assests/fondo2.jpg',
              fit: BoxFit.cover,
            ),
          ),
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
            label: 'Analisis Semanal',
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 2) {
      // Validar acceso a Mi Resumen solo los jueves
      bool isThursday = _today.weekday == DateTime.thursday;
      if (!isThursday) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mi Resumen solo está disponible los jueves')),
        );
        setState(() {
          _currentIndex = 0; // Regresar a la pantalla de Inicio
        });
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
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
  CalendarFormat _calendarFormat = CalendarFormat.month; // Usa CalendarFormat del paquete table_calendar

  String _dailyQuote = '';

  @override
  void initState() {
    super.initState();
    _events = {};
    _loadEvents();
    _loadDailyQuote();
  }

  Future<void> _loadEvents() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('estado_de_animo')
          .where('userId', isEqualTo: user.uid)
          .get();

      Map<DateTime, List<String>> events = {};
      DateTime today = DateTime.now();
      for (var doc in querySnapshot.docs) {
        DateTime date = (doc['timestamp'] as Timestamp).toDate();
        DateTime eventDate = DateTime(date.year, date.month, date.day);
        if (eventDate.isAtSameMomentAs(today)) {
          // Mostrar advertencia de estado ya registrado
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ya has registrado tu estado de ánimo hoy')),
          );
          return; // Salir si ya está registrado
        }
        events.putIfAbsent(eventDate, () => []).add(doc['mood']);
      }

      setState(() {
        _events = events;
      });
    } catch (e) {
      print('Error al cargar eventos: $e');
    }
  }

  Future<void> _loadDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (prefs.containsKey('daily_quote') && prefs.containsKey('quote_date')) {
      final storedDate = prefs.getString('quote_date')!;

      if (storedDate == today) {
        setState(() {
          _dailyQuote = prefs.getString('daily_quote') ?? '';
        });
        return;
      }
    }

    await _getDailyQuote();
  }

  Future<void> _getDailyQuote() async {
    try {
      var apiUrl = 'https://api.openai.com/v1/chat/completions';
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer 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',
      };

      var prompt = 'Genera una frase motivacional para el día';

      var body = jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': prompt,
          }
        ],
        'max_tokens': 30,
      });

      var response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        var quote = jsonResponse['choices'][0]['message']['content'];

        setState(() {
          _dailyQuote = quote;
        });

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('daily_quote', _dailyQuote);
        prefs.setString('quote_date', DateTime.now().toIso8601String().split('T')[0]);
      } else {
        throw Exception('Failed to load quote');
      }
    } catch (e) {
      setState(() {
        _dailyQuote = 'Error al obtener la frase del día: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          _buildMoodRegistrationCard(),
          const SizedBox(height: 20.0),
          _buildCalendarCard(),
          const SizedBox(height: 20.0),
          _buildDailyQuoteCard(),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }

  Widget _buildMoodRegistrationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF7AB992).withOpacity(0.8),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterMoodScreen()),
            ),
            child: const Text('Registrar Ahora'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
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
      child: TableCalendar(
        firstDay: DateTime.utc(2021, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: Colors.red),
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
    );
  }

  Widget _buildDailyQuoteCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.yellow[200],
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frase del día:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
              fontFamily: 'Pacifico',
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            _dailyQuote.isNotEmpty ? _dailyQuote : 'No hay frase del día disponible',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16.0,
              fontFamily: 'Pacifico',
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }
}
