import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  // Initialiser le service de notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  // Gérer le tap sur une notification
  static void _onNotificationTapped(NotificationResponse response) {
    // TODO: Naviguer vers la page appropriée selon le type de notification
    print('Notification tapped: ${response.payload}');
  }

  // Demander les permissions
  static Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    return true; // iOS gère les permissions différemment
  }

  // Afficher une notification simple
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'raaga_channel',
      'B-Place Notifications',
      channelDescription: 'Notifications Business Place',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Notification de nouvelle commande pour l'e-commerçant
  static Future<void> showNewOrderNotification({
    required String orderId,
    required String customerName,
    required double totalAmount,
  }) async {
    await showNotification(
      id: 1,
      title: 'Nouvelle commande reçue !',
      body: 'Commande de $customerName pour ${totalAmount.toStringAsFixed(0)} FCFA',
      payload: 'order:$orderId',
    );
  }

  // Notification de statut de commande pour le client
  static Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
  }) async {
    String title = 'Statut de commande mis à jour';
    String body = 'Votre commande #${orderId.substring(0, 8)} est maintenant $status';
    
    switch (status) {
      case 'confirmed':
        title = 'Commande confirmée !';
        body = 'Votre commande #${orderId.substring(0, 8)} a été confirmée';
        break;
      case 'shipped':
        title = 'Commande expédiée !';
        body = 'Votre commande #${orderId.substring(0, 8)} a été expédiée';
        break;
      case 'delivered':
        title = 'Commande livrée !';
        body = 'Votre commande #${orderId.substring(0, 8)} a été livrée';
        break;
    }

    await showNotification(
      id: 2,
      title: title,
      body: body,
      payload: 'order:$orderId',
    );
  }

  // Notification de produit ajouté au panier
  static Future<void> showProductAddedNotification({
    required String productName,
  }) async {
    await showNotification(
      id: 3,
      title: 'Produit ajouté au panier',
      body: '$productName a été ajouté à votre panier',
      payload: 'cart',
    );
  }

  // Notification de promotion
  static Future<void> showPromotionNotification({
    required String title,
    required String body,
  }) async {
    await showNotification(
      id: 4,
      title: title,
      body: body,
      payload: 'promotion',
    );
  }

  // Notification de nouveau produit
  static Future<void> showNewProductNotification({
    required String productName,
    required String merchantName,
  }) async {
    await showNotification(
      id: 5,
      title: 'Nouveau produit disponible !',
      body: '$productName de $merchantName',
      payload: 'product',
    );
  }

  // Annuler une notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Programmer une notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'raaga_scheduled',
      'B-Place Scheduled',
      channelDescription: 'Notifications programmées Business Place',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Obtenir les notifications en attente
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
