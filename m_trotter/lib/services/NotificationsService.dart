import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Méthode d'initialisation des notifications
  static Future<void> init() async {
    await _requestNotificationPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // Ton icône d'app

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      // Ajoute iOS settings si tu souhaites cibler iOS :
      //iOS: IOSInitializationSettings(),
    );

    /*
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: onSelectNotification, // Callback lorsque l'utilisateur clique sur la notification
    );

*/
  }
  // Méthode pour afficher une notification
  static Future<void> showNotification(
      {required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel', 'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      // Ajouter un NotificationDetails iOS si nécessaire
      //iOS: IOSNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: 'payload', // Information supplémentaire pour manipuler l’action sur click
    );
  }

  // Méthode pour gérer la notification au clic
  static Future<void> onSelectNotification(String? payload) async {
    // Exécuter ce code lors du clic sur la notification
    print("Notification tapped! Payload: $payload");
    // Tu pourrais naviguer vers une page spécifique
  }

  // Demander la permission de notification (uniquement nécessaire pour Android)
  static Future<void> _requestNotificationPermission() async {
    // Demande permission pour notifications
    if (await Permission.notification.request().isGranted) {
      return;
    } else {
      print('Notification permission denied.');
    }
  }
}
