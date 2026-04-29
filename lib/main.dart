import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  runApp(const MainApp());
}

