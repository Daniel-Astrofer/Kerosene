import 'package:flutter/material.dart';
import 'package:teste/core/responsive/kerosene_responsive.dart';

class SeedGrid extends StatefulWidget {
  final int selectedLength;
  final ValueChanged<int> onLengthChanged;
  final List<TextEditingController> controllers;

  const SeedGrid({
    super.key,
    required this.selectedLength,
    required this.onLengthChanged,
    required this.controllers,
  });

  @override
  State<SeedGrid> createState() => _SeedGridState();
}

class _SeedGridState extends State<SeedGrid> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      children: [
        // Tab Selector (12 | 18 | 24)
        Container(
          width: responsive.clampWidth(200),
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.05),
            ),
          ),
          child: Row(children: [_buildTab(12), _buildTab(18), _buildTab(24)]),
        ),
        const SizedBox(height: 32),

        // Grid Container
        LayoutBuilder(
          builder: (context, constraints) {
            final oneColumn = constraints.maxWidth < 420;
            return Container(
              padding: EdgeInsets.all(responsive.isTinyPhone ? 16 : 24),
              decoration: BoxDecoration(
                color: const Color(0xFF030303),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.selectedLength,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: oneColumn ? 1 : 2,
                  childAspectRatio: oneColumn ? 6.2 : 3.5,
                  crossAxisSpacing: responsive.isTinyPhone ? 10 : 16,
                  mainAxisSpacing: responsive.isTinyPhone ? 8 : 12,
                ),
                itemBuilder: (context, index) {
                  final number = (index + 1).toString().padLeft(2, '0');
                  return Row(
                    children: [
                      Text(
                        number,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.3),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: widget.controllers[index],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: responsive.isTinyPhone ? 13 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTab(int length) {
    final isSelected = widget.selectedLength == length;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onLengthChanged(length),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            length.toString(),
            style: TextStyle(
              fontFamily: 'Inter',
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.3),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
