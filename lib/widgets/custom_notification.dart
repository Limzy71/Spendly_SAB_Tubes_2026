import 'package:flutter/material.dart';
import 'dart:async';

class CustomNotification {
  static OverlayEntry? _currentOverlay;
  static Timer? _currentTimer;
  static String? _currentMessage;

  static void show(BuildContext context, String message, {bool isError = false, bool isWarning = false}) {
    if (_currentOverlay != null) {
      if (_currentMessage == message) {
        _currentTimer?.cancel();
        _currentTimer = Timer(const Duration(seconds: 3), () {
          _removeOverlay();
        });
        return;
      } else {
        _currentTimer?.cancel();
        _removeOverlay();
      }
    }

    _currentMessage = message;

    final overlay = Overlay.of(context);

    Color bgColor = const Color(0xFF00AA5B);
    IconData icon = Icons.check;

    if (isError) {
      bgColor = const Color(0xFFE63946);
      icon = Icons.close;
    } else if (isWarning) {
      bgColor = Colors.orange.shade600;
      icon = Icons.warning_amber_rounded;
    }

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: -100, end: 0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: bgColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlay!);

    _currentTimer = Timer(const Duration(seconds: 3), () {
      _removeOverlay();
    });
  }

  static void _removeOverlay() {
    if (_currentOverlay != null && _currentOverlay!.mounted) {
      _currentOverlay!.remove();
    }
    _currentOverlay = null;
    _currentMessage = null;
  }
}