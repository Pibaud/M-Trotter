import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final FocusNode _focusNode = FocusNode(); // FocusNode pour le TextField
  Timer? _debounce;
  List<String> _suggestions = []; // Liste des suggestions à afficher
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Demande le focus dès que la page est chargée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  // Fonction pour récupérer les suggestions depuis le serveur
  Future<void> getPlaces(String input) async {
    final String url = 'http://192.168.0.49:3000/api/places';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': input}),
      );

      if (response.statusCode == 200) {
        print('Réponse du serveur : ${response.body}');
        final data = json.decode(response.body);
        setState(() {
          _suggestions = List<String>.from(data['places'] ?? []);
        });
      } else {
        print('Erreur du serveur : ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la requête : $e');
    }
  }

  // Gestion du debounce pour éviter les appels multiples
  void _onTextChanged(String value) {
    // Annuler le timer existant si l'utilisateur continue à taper
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Vérifier si le champ n'est pas vide avant d'envoyer
      if (value.trim().isNotEmpty) {
        getPlaces(value.trim());
      }
    });
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
              controller: _controller,  // Utiliser le contrôleur
              focusNode: _focusNode, // Associe le TextField au FocusNode
              decoration: InputDecoration(
                hintText: 'Où voulez-vous aller ?',
                hintStyle: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 0.35),
                ),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onChanged: _onTextChanged,
            ),
          ),
          if (_suggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(_suggestions[index]),
                      onTap: () {
                        _controller.text = _suggestions[index]; // en fait plutot redirect sur la map
                        _focusNode.unfocus();
                        setState(() {
                          _suggestions.clear();
                        });
                        _focusNode.requestFocus();
                      });
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Libère le FocusNode
    super.dispose();
  }
}
