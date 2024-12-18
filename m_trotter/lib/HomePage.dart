import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'SearchPage.dart';

class HomePage extends StatefulWidget {
  final void Function(int) onTabChange;

  const HomePage({super.key, required this.onTabChange});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
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
                  color: Color.fromRGBO(0, 0, 0, 0.35),
                ),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onTap: () {
                widget.onTabChange(1); // Change l'onglet vers "SearchPage"
              },
            ),
          ),
          Text("Favoris"),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal, // Scroll de droite à gauche.
              children: [
                for (var i = 1; i <= 10; i++)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 150,
                      color: Colors.blue[100 * (i % 9)],
                      child: Center(
                        child:
                            Text('Élément $i', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text("Populaires en ce moment"),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal, // Scroll de droite à gauche.
              children: [
                for (var i = 1; i <= 10; i++)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 150,
                      color: Colors.blue[100 * (i % 9)],
                      child: Center(
                        child:
                            Text('Élément $i', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
