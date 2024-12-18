import 'package:flutter/material.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  NewsPageState createState() => NewsPageState();
}

class NewsPageState extends State<NewsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Center(
        child: Text('M\'Trotter NewsPage'),
      )),
    );
  }
}