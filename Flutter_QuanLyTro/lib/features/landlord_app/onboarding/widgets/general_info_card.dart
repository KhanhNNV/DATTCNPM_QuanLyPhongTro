import 'package:flutter/material.dart';

class GeneralInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController addressController;
  final int invoiceDay;
  final int dueDate;
  final ValueChanged<int?> onInvoiceDayChanged;
  final ValueChanged<int?> onDueDateChanged;

  const GeneralInfoCard({
    super.key,
    required this.nameController,
    required this.addressController,
    required this.invoiceDay,
    required this.dueDate,
    required this.onInvoiceDayChanged,
    required this.onDueDateChanged,
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
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên khu trọ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: invoiceDay,
                    decoration: const InputDecoration(labelText: 'Ngày chốt HĐ', border: OutlineInputBorder()),
                    items: List.generate(31, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                    onChanged: onInvoiceDayChanged,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: dueDate,
                    decoration: const InputDecoration(labelText: 'Hạn chót đóng', border: OutlineInputBorder()),
                    items: List.generate(31, (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1}'))),
                    onChanged: onDueDateChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}