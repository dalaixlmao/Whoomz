import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: WhoomzApp()));
}

class WhoomzApp extends StatelessWidget {
  const WhoomzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Whoomz',
      home: Scaffold(
        body: Center(child: Text('Whoomz')),
      ),
    );
  }
}
