import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

import '../models/task.dart';

class AnimatedTaskTile extends StatefulWidget {
  final Task task;
  final bool isHabit;
  final bool isDone;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const AnimatedTaskTile({
    super.key,
    required this.task,
    required this.isHabit,
    required this.isDone,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<AnimatedTaskTile> createState() => _AnimatedTaskTileState();
}

class _AnimatedTaskTileState extends State<AnimatedTaskTile> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- THIS IS THE FIX ---
    // Get colors from the theme, not hardcoded.
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Faded color for "done" text
    final doneColor = colors.onSurface.withAlpha(128);
    // Primary color for "to-do" text
    final todoColor = colors.onSurface;
    // Border color for checkbox
    final borderColor = colors.outline;
    // --- END FIX ---

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          InkWell(
            onTap: () {
              if (!widget.isDone) {
                _confettiController.play();
              }
              widget.onTap();
            },
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Row(
                  children: [
                    // Animated Circular Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.isDone ? Colors.green : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isDone ? Colors.green : borderColor, // Use theme color
                          width: 2.5,
                        ),
                      ),
                      child: widget.isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Title
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 17,
                          decoration: (widget.isHabit ? false : widget.isDone)
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          // --- USE THEME COLORS ---
                          color: widget.isDone ? doneColor : todoColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confetti Spark Effect
          Align(
            alignment: const Alignment(-0.9, 0),
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 10,
              gravity: 0.05,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.yellow,
                Colors.pink,
                Colors.orange,
              ],
              createParticlePath: (size) {
                return Path()
                  ..addOval(Rect.fromCircle(center: Offset.zero, radius: 1))
                  ..close();
              },
            ),
          ),
        ],
      ),
    );
  }
}