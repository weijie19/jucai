import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

class JucaiApp extends StatelessWidget {
  const JucaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '聚财',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
