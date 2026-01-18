// lib/services/service_locator.dart  ✅ لاحظ المسار الصحيح
import 'package:get_it/get_it.dart';
import 'package:flutter_application_1/services/user_service/chat_user_service.dart'; // ✅ المسار الصحيح

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<ChatUserService>(() => ChatUserService());
}