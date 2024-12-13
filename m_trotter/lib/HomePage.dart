import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('M\'Trotter')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Où voulez-vous aller ?',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
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
                        child: Text('Élément $i', style: TextStyle(fontSize: 18)),
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
                        child: Text('Élément $i', style: TextStyle(fontSize: 18)),
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