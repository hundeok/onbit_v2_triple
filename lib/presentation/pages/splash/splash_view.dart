import 'package:flutter/material.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Onbit V2 Triple',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}