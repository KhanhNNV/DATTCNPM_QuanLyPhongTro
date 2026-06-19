import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../models/onboarding_models.dart';

class ServicesCard extends StatelessWidget {
  final List<AppServiceItem> services;
  final VoidCallback onServiceTypeChanged;

  const ServicesCard({
    super.key,
    required this.services,
    required this.onServiceTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(services.length, (index) {
            final service = services[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<ServiceCalculationType>(
                          isExpanded: true,
                          value: service.calcType,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(),
                          ),
                          items: ServiceCalculationType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            service.calcType = value!;
                            onServiceTypeChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: TextField(
                          controller: service.priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Đơn giá',
                            suffixText: service.calcType.getUnit(service.name),
                            suffixStyle: const TextStyle(fontSize: 12, color: Colors.black54),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}