import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:extractor/extractor.dart';
import 'package:permission_handler/permission_handler.dart';

/// Callback de background executado em uma isolate separada quando o usuário
/// clica em botões de ação na bandeja de notificações.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  final actionId = notificationResponse.actionId;
  final processId = notificationResponse.payload;

  if (actionId == null || processId == null || processId.isEmpty) return;

  debugPrint('[NotificationService] Clique em background: actionId=$actionId, processId=$processId');

  if (actionId == 'cancel_download' || actionId == 'pause_download') {
    // Mata o processo de download nativo diretamente via processId
    YoutubeDLFlutter.instance.cancelDownload(processId).catchError((e) {
      debugPrint('[NotificationService] Erro ao cancelar download em background: $e');
      return false;
    });
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Inicializa as configurações de notificação local para Android.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Solicita permissão de notificação no Android 13+
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Inicializa o plugin registrando callbacks para foreground e background
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final actionId = response.actionId;
        final processId = response.payload;

        if (actionId == null || processId == null || processId.isEmpty) return;

        debugPrint('[NotificationService] Clique em foreground: actionId=$actionId, processId=$processId');

        if (actionId == 'cancel_download' || actionId == 'pause_download') {
          // Cancela o download ativo
          YoutubeDLFlutter.instance.cancelDownload(processId).catchError((e) {
            debugPrint('[NotificationService] Erro ao cancelar download: $e');
            return false;
          });
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    _isInitialized = true;
    debugPrint('[NotificationService] Inicializado com sucesso.');
  }

  /// Exibe ou atualiza uma notificação de progresso para uma tarefa de download ativa.
  static Future<void> showProgressNotification({
    required int taskId,
    required String title,
    required double progress,
    required String speed,
    required String eta,
    required String processId,
    required bool isAudio,
  }) async {
    if (!_isInitialized) await initialize();

    final percent = progress.clamp(0.0, 100.0).toInt();
    final typeLabel = isAudio ? 'Música' : 'Vídeo';

    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Notificações de progresso de downloads',
      importance: Importance.low, // Evita popups invasivos repetidos a cada update
      priority: Priority.low,
      showWhen: false,
      onlyAlertOnce: true, // Toca som/vibra apenas uma vez
      showProgress: true,
      maxProgress: 100,
      progress: percent,
      indeterminate: false,
      ongoing: true, // impede o usuário de fechar arrastando
      styleInformation: BigTextStyleInformation(
        'Baixando $typeLabel: $title\nProgresso: $percent% | Speed: $speed | ETA: $eta',
        contentTitle: 'Download em andamento...',
        summaryText: '$percent%',
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'cancel_download',
          'Cancelar',
          cancelNotification: true, // fecha a notificação após o clique
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      taskId,
      'Baixando $typeLabel...',
      title,
      notificationDetails,
      payload: processId,
    );
  }

  /// Remove/cancela uma notificação da barra de status pelo ID da tarefa.
  static Future<void> cancelNotification(int taskId) async {
    if (!_isInitialized) await initialize();
    await _notificationsPlugin.cancel(taskId);
  }
}
