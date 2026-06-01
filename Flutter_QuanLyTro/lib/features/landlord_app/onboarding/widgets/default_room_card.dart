import 'package:flutter/material.dart';

class DefaultRoomCard extends StatelessWidget {
  final TextEditingController rentPriceController;
  final TextEditingController depositController;
  final TextEditingController areaSizeController;
  final TextEditingController maxOccupantsController;

  const DefaultRoomCard({
    super.key,
    required this.rentPriceController,
    required this.depositController,
    required this.areaSizeController,
    required this.maxOccupantsController,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: rentPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giá thuê (VNĐ)', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: depositController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tiền cọc (VNĐ)', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: areaSizeController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Diện tích (m2)', border: OutlineInputBorder()))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: maxOccupantsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số người tối đa', border: OutlineInputBorder()))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}