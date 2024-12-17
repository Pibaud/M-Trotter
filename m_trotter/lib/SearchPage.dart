import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  // Fonction pour envoyer la requête au serveur
  Future<void> sendDataToServer(String input) async {
    // L'URL de votre serveur (local ou distant)
    final String url =
        'http://192.168.1.11:3000/api/data'; // Changez l'URL si nécessaire

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'data': input
        }), // Assure-toi d'envoyer la donnée sous forme de clé 'data'
      );

      if (response.statusCode == 200) {
        print('Réponse du serveur : ${response.body}');
      } else {
        print('Erreur du serveur : ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la requête : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Center(
        child: Text('M\'Trotter'),
      )),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Où voulez-vous aller ?',
                hintStyle: TextStyle(
                  color: Color.fromRGBO(
                      0, 0, 0, 0.35), // Réduit l'opacité à 50% avec RGB
                ),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onChanged: (String value) {
                // Appelé à chaque modification du texte
                sendDataToServer(value); // Envoie les données au serveur
              },
            ),
          ),
        ],
      ),
    );
  }
}