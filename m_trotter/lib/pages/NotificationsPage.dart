import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/NotificationsService.dart'; // Importer NotificationService

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isCommentRepliesEnabled = false;
  bool _isLikesEnabled = false;
  bool _isTrendingStoresEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Charger les préférences (état des notifications) à partir de SharedPreferences
  _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCommentRepliesEnabled = prefs.getBool('comment_replies') ?? false;
      _isLikesEnabled = prefs.getBool('likes') ?? false;
      _isTrendingStoresEnabled = prefs.getBool('trending_stores') ?? false;
    });
  }

  // Sauvegarder les préférences (état des notifications) dans SharedPreferences
  _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('comment_replies', _isCommentRepliesEnabled);
    prefs.setBool('likes', _isLikesEnabled);
    prefs.setBool('trending_stores', _isTrendingStoresEnabled);
  }

  // Méthode pour afficher une notification (appel au service)
  _showNotification(String title, String body) {
    NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 2147483647,
      title: title,
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres de Notifications")),
      body: ListView(
        children: [
          // Notification pour les réponses aux commentaires
          SwitchListTile(
            title: const Text("Réponses à vos commentaires"),
            subtitle: const Text("Recevoir une notification lorsqu'un utilisateur répond à votre commentaire."),
            value: _isCommentRepliesEnabled,
            onChanged: (bool value) {
              setState(() {
                _isCommentRepliesEnabled = value;
                _savePreferences();
              });

              // Affichage d'une notification lorsque cette option est activée
              if (value) {
                _showNotification('Réponse à un commentaire', 'Vous avez une nouvelle réponse à votre commentaire.');
              }
            },
          ),

          // Notification pour les likes
          SwitchListTile(
            title: const Text("Likes sur vos commentaires"),
            subtitle: const Text("Recevoir une notification lorsqu'un utilisateur aime votre commentaire."),
            value: _isLikesEnabled,
            onChanged: (bool value) {
              setState(() {
                _isLikesEnabled = value;
                _savePreferences();
              });

              // Affichage d'une notification lorsque cette option est activée
              if (value) {
                _showNotification('Nouveau like', 'Un utilisateur a aimé votre commentaire.');
              }
            },
          ),

          // Notification pour les magasins tendance
          SwitchListTile(
            title: const Text("Magasins ou restaurants en tendance"),
            subtitle: const Text("Recevoir une notification lorsque des magasins ou restaurants deviennent tendance."),
            value: _isTrendingStoresEnabled,
            onChanged: (bool value) {
              setState(() {
                _isTrendingStoresEnabled = value;
                _savePreferences();
              });

              // Affichage d'une notification lorsque cette option est activée
              if (value) {
                _showNotification('Magasins en tendance', 'Un magasin devient tendance près de chez vous!');
              }
            },
          ),
        ],
      ),
    );
  }
}
