import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:connexa/app/app.dart';
import 'package:connexa/features/notifications/services/fcm_push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FcmPushService.initialize();
  runApp(const ProviderScope(child: ConnexaApp()));
}
