import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late User? _user;
  late DateTime _selectedDay;
  late List<Map<String, dynamic>> _events;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _selectedDay = DateTime.now();
    _events = [];
    _pageController = PageController(initialPage: _selectedDay.weekday - 1);
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (_user == null) return;

    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('estado_de_animo')
        .where('userId', isEqualTo: _user!.uid)
        .get();

    List<Map<String, dynamic>> events = [];

    for (var doc in query.docs) {
      var data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        events.add(data);
      }
    }

    setState(() {
      _events = events;
    });
  }

  Map<String, dynamic> _getEventsForDay(DateTime day) {
    var eventsForDay = _events.firstWhere(
          (event) =>
      DateTime.fromMillisecondsSinceEpoch(
          (event['timestamp'] as Timestamp).millisecondsSinceEpoch)
          .day ==
          day.day,
      orElse: () => {
        'mood': 'No registrado',
        'emotions': [],
      },
    );

    return eventsForDay;
  }

  DateTime _getDateForDayOfWeek(int weekday) {
    DateTime today = DateTime.now();
    int daysFromMonday = today.weekday - DateTime.monday;
    DateTime monday = today.subtract(Duration(days: daysFromMonday));
    return monday.add(Duration(days: weekday - DateTime.monday));
  }

  Widget _buildDaySummary(DateTime day) {
    Map<String, dynamic> events = _getEventsForDay(day);
    double containerSize = MediaQuery.of(context).size.height * 0.6;
    double cardSize = containerSize * 0.5;

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: BorderRadius.circular(20),
        ),
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            const SizedBox(height: 16),

            // Información del estado de ánimo
            Container(
              width: cardSize,
              height: cardSize,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Estado de ánimo:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      events['mood'],
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Emociones sentidas:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Wrap(
                      spacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: (events['emotions'] as List<dynamic>)
                          .map((emotion) => Chip(
                        label: Text(
                          emotion,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.green[200],
                      ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayButton(String dayOfWeek, int dayIndex) {
    DateTime day = _getDateForDayOfWeek(dayIndex + DateTime.monday);
    bool isSelected = day.day == _selectedDay.day;

    Color textColor = isSelected ? Colors.brown[900]! : Colors.grey[700]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _pageController.jumpToPage(dayIndex);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[100] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
        ),
        child: Center(
          child: Text(
            dayOfWeek,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'HOY ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(_selectedDay),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Botones de días de la semana
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDayButton('L', 0),
                _buildDayButton('M', 1),
                _buildDayButton('X', 2),
                _buildDayButton('J', 3),
                _buildDayButton('V', 4),
                _buildDayButton('S', 5),
                _buildDayButton('D', 6),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              itemCount: DateTime.daysPerWeek,
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedDay = _getDateForDayOfWeek(DateTime.monday + index);
                });
              },
              itemBuilder: (context, index) {
                DateTime day = _getDateForDayOfWeek(DateTime.monday + index);
                return _buildDaySummary(day);
              },
            ),
          ),
        ],
      ),
    );
  }
}
