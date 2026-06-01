import 'package:flutter/material.dart';

class DynamicFloorCard extends StatelessWidget {
  final TextEditingController floorCountController;
  final int floorCount;
  final List<TextEditingController> roomsPerFloorControllers;
  final ValueChanged<String> onFloorCountChanged;

  const DynamicFloorCard({
    super.key,
    required this.floorCountController,
    required this.floorCount,
    required this.roomsPerFloorControllers,
    required this.onFloorCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: floorCountController,
              keyboardType: TextInputType.number,
              onChanged: onFloorCountChanged,
              decoration: const InputDecoration(
                labelText: 'Số tầng',
                hintText: 'Nhập số tầng của khu trọ (VD: 3)',
                border: OutlineInputBorder(),
              ),
            ),
            if (floorCount > 0) ...[
              const SizedBox(height: 16),
              const Text('Điều chỉnh số phòng cho từng tầng:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: floorCount,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Text('Tầng ${index + 1}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: roomsPerFloorControllers[index],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                              suffixText: 'phòng',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}