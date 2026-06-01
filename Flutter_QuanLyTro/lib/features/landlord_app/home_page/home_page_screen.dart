import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HomePageScreen extends StatefulWidget{
  const HomePageScreen({super.key});
  
  @override
  State<StatefulWidget> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Xin chào"),
      ),
    );
  }
}