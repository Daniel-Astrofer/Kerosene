import 'package:flutter/material.dart';
import 'draggable_card_3d.dart';

/// DraggableCardDemo - Exemplo de uso do DraggableCard3D
/// Mostra como integrar o card com animação 3D
class DraggableCardDemo extends StatefulWidget {
  const DraggableCardDemo({super.key});

  @override
  State<DraggableCardDemo> createState() => _DraggableCardDemoState();
}

class _DraggableCardDemoState extends State<DraggableCardDemo> {
  int _completeCount = 0;
  int _cancelCount = 0;
  bool _cardVisible = true;

  void _resetCard() {
    setState(() {
      _cardVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draggable Card 3D'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF0F1419),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0F1419),
      body: Column(
        children: [
          // Stats Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  label: 'Completo',
                  value: _completeCount,
                  color: const Color(0xFF00FF94),
                ),
                _StatCard(
                  label: 'Cancelado',
                  value: _cancelCount,
                  color: const Color(0xFFFF0055),
                ),
              ],
            ),
          ),
          // Draggable Card Area
          Expanded(
            child: Center(
              child: DraggableCard3D(
                initialHeight: 200,
                onDragComplete: () {
                  setState(() {
                    _completeCount++;
                  });
                },
                onDragCancel: () {
                  setState(() {
                    _cancelCount++;
                  });
                },
                backgroundCards: [
                  _DemoCard(index: 1),
                  _DemoCard(index: 2),
                ],
                child: _DemoCard(index: 0),
              ),
            ),
          ),
          // Instructions
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Arraste para cima',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Efeito Stack 3D Vertical',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// _StatCard - Card de estatísticas
class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// _DemoCard - Card customizado para demonstração
class _DemoCard extends StatelessWidget {
  final int index;
  const _DemoCard({this.index = 0});

  @override
  Widget build(BuildContext context) {
    final colors = [
      [const Color(0xFF1A1F3C), const Color(0xFF0F1419)],
      [const Color(0xFF2A1F3C), const Color(0xFF1F1419)],
      [const Color(0xFF1A2F3C), const Color(0xFF0F2419)],
    ];
    
    final colorPair = colors[index % colors.length];

    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorPair[0].withValues(alpha: 0.9),
            colorPair[1].withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (index == 0 ? const Color(0xFF00D4FF) : Colors.white24).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            index == 0 ? Icons.touch_app : Icons.layers,
            size: 64,
            color: index == 0 ? const Color(0xFF00D4FF) : Colors.white38,
          ),
          const SizedBox(height: 24),
          Text(
            index == 0 ? 'Arraste para Cima' : 'Card #$index',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: index == 0 ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            index == 0 ? 'Perspectiva 3D + Profundidade' : 'No fundo do stack',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          if (index == 0) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '↑ Arraste para começar',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// _PlaceholderCard - Card vazio após completar
class _PlaceholderCard extends StatelessWidget {
  final VoidCallback onReset;

  const _PlaceholderCard({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF00FF94).withValues(alpha: 0.1),
            border: Border.all(
              color: const Color(0xFF00FF94).withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: Color(0xFF00FF94),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '✓ Completado!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF00FF94),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Resetar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      ],
    );
  }
}
