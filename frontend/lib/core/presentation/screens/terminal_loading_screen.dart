import 'dart:async';
import 'package:flutter/material.dart';

class TerminalLoadingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final bool isReady;

  const TerminalLoadingScreen({
    super.key,
    required this.onComplete,
    this.isReady = false,
  });

  @override
  State<TerminalLoadingScreen> createState() => _TerminalLoadingScreenState();
}

class _TerminalLoadingScreenState extends State<TerminalLoadingScreen> {
  final List<String> _allLogs = [
    'Initializing Kerosene Core v1.0.4...',
    'Establishing secure Tor relay via .onion portals...',
    'Entropy source verified. RNG integrity 100%.',
    'Loading encrypted wallet headers...',
    'Verifying biometric signatures against hardware enclave...',
    'Synchronizing Bitcoin node state (testnet/mainnet)...',
    'Decrypting local vault metadata...',
    'Initializing P2P protocol handshake...',
    'Scanning for unauthorized memory injections...',
    'Memory shield active. Virtual machine isolated.',
    'Optimizing UI rendering engine (Metal/Vulkan)...',
    'Establishing socket connection to relay clusters...',
    'Access granted. Welcome back, Agent.',
  ];

  final List<String> _displayedLogs = [];
  int _currentLogIndex = 0;
  Timer? _logTimer;
  bool _showCursor = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startBootSequence();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });
  }

  void _startBootSequence() {
    _logTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_currentLogIndex < _allLogs.length) {
        if (mounted) {
          setState(() {
            _displayedLogs.add(_allLogs[_currentLogIndex]);
            _currentLogIndex++;
          });
        }
      } else {
        _logTimer?.cancel();
        _checkIfCanComplete();
      }
    });
  }

  void _checkIfCanComplete() {
    if (_currentLogIndex >= _allLogs.length && widget.isReady) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) widget.onComplete();
      });
    }
  }

  @override
  void didUpdateWidget(TerminalLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReady && !oldWidget.isReady) {
      _checkIfCanComplete();
    }
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Terminal Header
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00F0FF),
                          boxShadow: [
                            BoxShadow(color: Color(0xFF00F0FF), blurRadius: 10),
                          ],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'SYSTEM BOOT SEQUENCE',
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontFamily: 'Courier',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'ENCRYPTED CHANNEL',
                        style: TextStyle(
                          color: Colors.white12,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),

                  // Terminal Logs
                  Expanded(
                    child: ListView.builder(
                      itemCount: _displayedLogs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _displayedLogs.length) {
                          // Cursor line
                          return Row(
                            children: [
                              const Text(
                                '> ',
                                style: TextStyle(
                                  color: Color(0xFF00F0FF),
                                  fontFamily: 'Courier',
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 16,
                                color: _showCursor
                                    ? const Color(0xFF00F0FF)
                                    : Colors.transparent,
                              ),
                            ],
                          );
                        }
                        final isLast = index == _displayedLogs.length - 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(index + 100).toString().substring(1)} ',
                                style: const TextStyle(
                                  color: Colors.white10,
                                  fontFamily: 'Courier',
                                  fontSize: 11,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _displayedLogs[index],
                                  style: TextStyle(
                                    color: isLast
                                        ? const Color(0xFF00F0FF)
                                        : Colors.white54,
                                    fontFamily: 'Courier',
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Progress or Status
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    color: Color(0xFF00F0FF),
                    minHeight: 1,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'KEROSENE OS v1.0.4',
                        style: TextStyle(color: Colors.white12, fontSize: 10),
                      ),
                      Text(
                        'BOOT: ${((_currentLogIndex / _allLogs.length) * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Scanline effect overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.03),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.03),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
