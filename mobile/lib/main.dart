import 'package:flutter/material.dart';

void main() {
  runApp(const BillingApp());
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Internal Billing',
      home: const Scaffold(
        body: Center(
          child: Text('Internal Billing and Khata'),
        ),
      ),
    );
  }
}
