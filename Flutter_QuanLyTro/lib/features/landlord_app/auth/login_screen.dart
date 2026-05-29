import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Màn hình Đăng nhập sẽ ở đây',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}