import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterMoodScreen extends StatefulWidget {
  const RegisterMoodScreen({super.key});

  @override
  _RegisterMoodScreenState createState() => _RegisterMoodScreenState();
}

class _RegisterMoodScreenState extends State<RegisterMoodScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentMoodIndex = 2; // Inicia en el índice de 'Más o menos'
  final List<String> _moods = ['Muy mal','Mal', 'Más o menos', 'Bien', 'Bastante bien', 'Excelente'];
  final List<String> _selectedEmotions = [];
  String _note = '';
  bool _moodRegisteredToday = false;
  User? user;
  Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _checkIfMoodRegisteredToday();
    _updateBackgroundColor();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkIfMoodRegisteredToday() async {
    if (user == null) return;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('estado_de_animo')
        .where('userId', isEqualTo: user!.uid)
        .where('timestamp', isGreaterThanOrEqualTo: today)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        _moodRegisteredToday = true;
      });
    }
  }

  void _updateBackgroundColor() {
    setState(() {
      switch (_currentMoodIndex) {
        case 0:
          _backgroundColor = Colors.blue[900]!;// muy mal
          break;
        case 1:
          _backgroundColor = Colors.blue[700]!;//mal
          break;
        case 2:
          _backgroundColor = Colors.blue[50]!;//mas o menos
          break;
        case 3:
          _backgroundColor = Colors.green[100]!;//bien
          break;
        case 4:
          _backgroundColor = Colors.orange[100]!;//bastante bien
          break;
        case 5:
          _backgroundColor = Colors.pink[100]!;//excelente
          break;
        default:
          _backgroundColor = Colors.white;
          break;
      }
    });
  }

  Color _getBackgroundColorForMood() {
    switch (_currentMoodIndex) {
      case 0:
        return Colors.blue[900]!;
      case 1:
        return Colors.blue[700]!;
      case 2:
        return Colors.blue[50]!;
      case 3:
        return Colors.green[100]!;
      case 4:
        return Colors.orange[100]!;
      case 5:
        return Colors.pink[100]!;
      default:
        return Colors.white;
    }
  }

  Future<void> _addMood(String mood) async {
    if (_moodRegisteredToday) {
      _showDialog('Advertencia', 'Ya has registrado tu estado de ánimo hoy.');
      return;
    }

    CollectionReference moodCollection = FirebaseFirestore.instance.collection('estado_de_animo');
    try {
      await moodCollection.add({
        'mood': mood,
        'emotions': _selectedEmotions,
        'note': _note,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user!.uid,
      });
      print('Estado de ánimo agregado exitosamente');
      _showDialog('Éxito', 'Estado de ánimo registrado exitosamente.');
      setState(() {
        _moodRegisteredToday = true;
      });
    } catch (e) {
      print('Error al agregar estado de ánimo: $e');
      _showDialog('Error', 'Error al registrar el estado de ánimo.');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (title == 'Éxito') {
                  _navigateToHomeScreen();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToHomeScreen() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Estado de Ánimo'),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: Colors.white, // Color de fondo general
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMoodWidget(),
              const SizedBox(height: 20),
              _buildEmotionsWidget(),
              const SizedBox(height: 20),
              _buildNoteWidget(),
              const SizedBox(height: 20),
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: _getBackgroundColorForMood(), // Color de fondo del recuadro de "¿Cómo te sientes hoy?"
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '¿Cómo te sientes hoy?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _currentMoodIndex = (_currentMoodIndex - 1).clamp(0, _moods.length - 1);
                    _updateBackgroundColor();
                  });
                },
              ),
              Text(_moods[_currentMoodIndex], style: const TextStyle(fontSize: 24)),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _currentMoodIndex = (_currentMoodIndex + 1).clamp(0, _moods.length - 1);
                    _updateBackgroundColor();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionsWidget() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white, // Color de fondo del recuadro de "¿Qué emociones sientes hoy?"
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '¿Qué emociones sientes hoy?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            children: _buildEmotionChips(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteWidget() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Agrega una nota (opcional)',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(16),
      ),
      onChanged: (value) {
        setState(() {
          _note = value;
        });
      },
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(Colors.amberAccent),
      ),
      onPressed: _moodRegisteredToday ? null : () => _addMood(_moods[_currentMoodIndex]),
      child: const Text('Registrar'),
    );
  }

  List<Widget> _buildEmotionChips() {
    return ['Triste', 'Nervioso', 'Aburrido', 'Agotado', 'Ansioso', 'Feliz', 'Motivado', 'Agradecido', 'Entusiasmado', 'Apasionado', 'Euforico']
        .map((emotion) {
      final chipColor = _getColorForEmotion(emotion);
      return FilterChip(
        label: Text(emotion),
        selected: _selectedEmotions.contains(emotion),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedEmotions.add(emotion);
            } else {
              _selectedEmotions.remove(emotion);
            }
          });
        },
        selectedColor: chipColor.withOpacity(0.5),
      );
    }).toList();
  }

  Color _getColorForEmotion(String emotion) {
    switch (emotion) {
      case 'Triste':
        return Colors.blueGrey;
      case 'Nervioso':
        return Colors.blue;
      case 'Aburrido':
        return Colors.cyan;
      case 'Agotado':
        return Colors.teal;
      case 'Ansioso':
        return Colors.green;
      case 'Feliz':
        return Colors.yellow;
      case 'Motivado':
        return Colors.orange;
      case 'Agradecido':
        return Colors.red;
      case 'Entusiasmado':
        return Colors.pink;
      case 'Apasionado':
        return Colors.purple;
      case 'Euforico':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

