import 'package:flutter/material.dart';

class MockInterviewPage extends StatelessWidget {
  const MockInterviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mock interview', style: theme.textTheme.titleLarge),
          bottom: const TabBar(
            tabs: [Tab(text: 'Setup'), Tab(text: 'Live'), Tab(text: 'Done')],
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SetupCard(),
                  const SizedBox(height: 16),
                  Text(
                    'Pick the role, set the challenge level, and start a realistic voice-based interview practice session.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_LiveInterviewCard(), SizedBox(height: 16), _LiveTranscriptCard()],
              ),
            ),
            Container(
              color: const Color(0xFF1A1A2E),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Interview complete!',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      const _DoneScoreRing(score: 78),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {},
                          child: const Text('View detailed report'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('Share your score'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Interview type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const _FauxDropdown(label: 'Software Engineer'),
            const SizedBox(height: 16),
            const Text('Difficulty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _DifficultyPill(label: 'Easy')),
                SizedBox(width: 8),
                Expanded(child: _DifficultyPill(label: 'Medium', active: true)),
                SizedBox(width: 8),
                Expanded(child: _DifficultyPill(label: 'Hard')),
              ],
            ),
            const SizedBox(height: 16),
            const Text('~15 minutes', style: TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Start interview'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveInterviewCard extends StatelessWidget {
  const _LiveInterviewCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Question 2 of 8'),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            value: 0.25,
            minHeight: 4,
            backgroundColor: Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8FC),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: const [
              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
          child: const Text(
            'Tell me about a time you dealt with a difficult team member.',
            style: TextStyle(color: Color(0xFF1A1A2E), fontSize: 16, height: 1.45),
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: _WaveRingMic()),
        const SizedBox(height: 12),
        const Center(child: Text('00:36', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        const Center(child: Text('Tap to answer', style: TextStyle(color: Color(0xFF9CA3AF)))),
      ],
    );
  }
}

class _LiveTranscriptCard extends StatelessWidget {
  const _LiveTranscriptCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF8F8FC),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your response so far', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text(
              'I tried to understand the teammate first, then aligned on the goal, and we agreed on a clearer way to share ownership...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveRingMic extends StatelessWidget {
  const _WaveRingMic();

  @override
  Widget build(BuildContext context) {
    final bars = List.generate(26, (index) {
      final height = (12 + (index % 5) * 6).toDouble();
      return Transform.rotate(
        angle: (index / 26) * 6.28318,
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      );
    });

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ...bars,
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFF1A1A2E),
            child: Icon(Icons.mic_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DoneScoreRing extends StatelessWidget {
  const _DoneScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: 0.78,
              strokeWidth: 10,
              backgroundColor: Color.fromRGBO(255, 255, 255, 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$score', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w700)),
              const Text('/ 100', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FauxDropdown extends StatelessWidget {
  const _FauxDropdown({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.08)),
      ),
      child: Row(
        children: [Expanded(child: Text(label)), const Icon(Icons.expand_more_rounded)],
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  const _DifficultyPill({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1A1A2E) : const Color(0xFFF8F8FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF1A1A2E) : const Color.fromRGBO(0, 0, 0, 0.08),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF1A1A2E),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
