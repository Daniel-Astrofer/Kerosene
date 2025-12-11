import 'package:flutter/material.dart';

/// Lista de contatos rápidos
class QuickContactList extends StatelessWidget {
  const QuickContactList({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      ('Add', Icons.add, null),
      ('GA', null, 'Gilbert'),
      ('SC', null, 'Steph'),
      ('HW', null, 'Harris'),
      ('G', null, 'Giannis'),
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return _buildContactItem(
            label: contact.$1,
            icon: contact.$2,
            name: contact.$3,
          );
        },
      ),
    );
  }

  Widget _buildContactItem({
    required String label,
    IconData? icon,
    String? name,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: icon != null
                  ? const Color(0xFF7B61FF).withOpacity(0.2)
                  : const Color(0xFF1A1F3A),
              shape: BoxShape.circle,
              border: icon != null
                  ? Border.all(
                      color: const Color(0xFF7B61FF),
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: const Color(0xFF7B61FF))
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name ?? label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
