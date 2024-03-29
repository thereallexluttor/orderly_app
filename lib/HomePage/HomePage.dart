import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
final ScrollController _scrollController = ScrollController();
final bool _scrollEnabled = false;

  @override
  void dispose() {
    _scrollController.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          controller: _scrollController, //Bear
          physics: _scrollEnabled ? null: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }
}