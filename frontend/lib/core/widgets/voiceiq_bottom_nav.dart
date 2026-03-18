import 'package:flutter/material.dart';

class VoiceIqBottomNav extends StatelessWidget {
  const VoiceIqBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.mic_rounded, 'Record'),
      (Icons.bar_chart_rounded, 'Progress'),
      (Icons.person_rounded, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.06), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = currentIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF6C63FF)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(
                      item.$1,
                      color: selected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
