import 'package:flutter/material.dart';
import 'dashboard.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}