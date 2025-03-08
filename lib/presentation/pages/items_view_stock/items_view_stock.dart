import 'package:flutter/material.dart';

class ItemsViewStock extends StatefulWidget {
  const ItemsViewStock({super.key});

  @override
  State<ItemsViewStock> createState() => _ItemsViewStockState();
}

class _ItemsViewStockState extends State<ItemsViewStock> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text('ItemsViewStock'),
      ),
      body: const Center(
        child: Text('ItemsViewStock'),
      ),
    );
  }
}