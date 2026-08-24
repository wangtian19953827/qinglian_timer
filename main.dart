import 'package:flutter/material.dart';

import 'screens/timer_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QinglianApp());
}

class QinglianApp extends StatelessWidget {
  const QinglianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '轻练',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const TimerScreen(),
    );
  }
}