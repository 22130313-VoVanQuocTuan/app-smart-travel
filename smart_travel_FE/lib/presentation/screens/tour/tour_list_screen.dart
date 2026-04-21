import 'package:flutter/material.dart';

class TourListScreen extends StatelessWidget {
  const TourListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tours'),
      ),
      body: const Center(
        child: Text('Tour List Screen'),
      ),
    );
  }
}
