import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

final _random = math.Random();

class ParticlePoetryGenerator extends StatefulWidget {
  @override
  _ParticlePoetryGeneratorState createState() => _ParticlePoetryGeneratorState();
}

class _ParticlePoetryGeneratorState extends State<ParticlePoetryGenerator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _explosionController;
  late AnimationController _gravityController;

  final TextEditingController _textController = TextEditingController();
  final List<Particle> _particles = [];
  final List<WordParticle> _wordParticles = [];

  Timer? _particleTimer;
  Timer? _cleanupTimer;

  double _gravity = 0.0;
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  final List<Color> _colors = [
    Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFF45B7D1),
    Color(0xFF96CEB4), Color(0xFFFFEAA7), Color(0xFFDDA0DD),
    Color(0xFFFD79A8), Color(0xFF74B9FF), Color(0xFFE17055),
    Color(0xFFA29BFE), Color(0xFF6C5CE7), Color(0xFFFF7675),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 50),
      vsync: this,
    );

    _explosionController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _gravityController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _animationController.repeat();
    _startParticleSystem();
    _startCleanupTimer();
  }

  void _startParticleSystem() {
    _particleTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) {
        _updateParticles();
      }
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _cleanupParticles();
      }
    });
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.update(_gravity, _tiltX, _tiltY);
      }

      for (var wordParticle in _wordParticles) {
        wordParticle.update(_gravity, _tiltX, _tiltY);
      }
    });
  }

  void _cleanupParticles() {
    setState(() {
      _particles.removeWhere((particle) => particle.isDead);
      _wordParticles.removeWhere((wordParticle) => wordParticle.isDead);
    });
  }

  void _explodeText(String text) {
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    // Create word particles for each letter
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char != ' ' && char.trim().isNotEmpty) { // Added validation
        final angle = (i / text.length) * 2 * math.pi;
        final radius = 50.0 + (i * 20);

        final x = centerX + math.cos(angle) * radius;
        final y = centerY + math.sin(angle) * radius;

        final color = _colors[i % _colors.length];

        _wordParticles.add(WordParticle(
          x: x,
          y: y,
          char: char,
          color: color,
          targetX: x,
          targetY: y,
        ));

        // Create explosion particles around each letter
        for (int j = 0; j < 15; j++) {
          final particleAngle = (j / 15) * 2 * math.pi;
          final particleRadius = 20.0 + _random.nextDouble() * 30;

          final particleX = x + math.cos(particleAngle) * particleRadius;
          final particleY = y + math.sin(particleAngle) * particleRadius;

          _particles.add(Particle(
            x: x,
            y: y,
            vx: math.cos(particleAngle) * (2 + _random.nextDouble() * 4),
            vy: math.sin(particleAngle) * (2 + _random.nextDouble() * 4),
            color: color,
            size: 2 + _random.nextDouble() * 4,
            life: 1.0,
          ));
        }
      }
    }

    // Add some random background particles
    for (int i = 0; i < 30; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final radius = 100 + _random.nextDouble() * 200;

      _particles.add(Particle(
        x: centerX,
        y: centerY,
        vx: math.cos(angle) * (1 + _random.nextDouble() * 3),
        vy: math.sin(angle) * (1 + _random.nextDouble() * 3),
        color: _colors[_random.nextInt(_colors.length)],
        size: 1 + _random.nextDouble() * 3,
        life: 1.0,
      ));
    }

    _explosionController.reset();
    _explosionController.forward();
  }

  void _simulateGravity() {
    setState(() {
      _gravity = _gravity == 0 ? 0.1 : 0;
    });

    _gravityController.reset();
    _gravityController.forward();
  }

  void _simulateTilt() {
    setState(() {
      _tiltX = (_random.nextDouble() - 0.5) * 0.2;
      _tiltY = (_random.nextDouble() - 0.5) * 0.2;
    });

    Timer(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _tiltX = 0;
          _tiltY = 0;
        });
      }
    });
  }

  void _clearAll() {
    setState(() {
      _particles.clear();
      _wordParticles.clear();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _explosionController.dispose();
    _gravityController.dispose();
    _particleTimer?.cancel();
    _cleanupTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Particle Canvas
            CustomPaint(
              painter: ParticlePainter(
                particles: _particles,
                wordParticles: _wordParticles,
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
              ),
            ),

            // UI Controls - Using SingleChildScrollView to handle overflow
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    reverse: true, // This makes it scroll to bottom when keyboard appears
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Title
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Text(
                                    '🎆 Particle Poetry',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Type words and watch them explode into magic!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                            Expanded(child: Container()),

                            // Text Input
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _textController,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Type your poetry here...',
                                    hintStyle: TextStyle(color: Colors.white60),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.all(20),
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.auto_fix_high, color: Colors.white),
                                      onPressed: () {
                                        _explodeText(_textController.text);
                                      },
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    _explodeText(text);
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Control Buttons
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildControlButton(
                                    icon: Icons.rocket_launch,
                                    label: 'Explode',
                                    onPressed: () => _explodeText(_textController.text),
                                  ),
                                  _buildControlButton(
                                    icon: Icons.gradient,
                                    label: 'Gravity',
                                    onPressed: _simulateGravity,
                                  ),
                                  _buildControlButton(
                                    icon: Icons.screen_rotation,
                                    label: 'Tilt',
                                    onPressed: _simulateTilt,
                                  ),
                                  _buildControlButton(
                                    icon: Icons.clear_all,
                                    label: 'Clear',
                                    onPressed: _clearAll,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 20),

                            // Quick Words
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  Text(
                                    'Quick Words',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      'LOVE', 'DREAM', 'MAGIC', 'FLUTTER', 'POETRY'
                                    ].map((word) => GestureDetector(
                                      onTap: () {
                                        _textController.text = word;
                                        _explodeText(word);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        margin: EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: _colors[(word.hashCode % _colors.length)].withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _colors[(word.hashCode % _colors.length)],
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          word,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final List<WordParticle> wordParticles;

  ParticlePainter({
    required this.particles,
    required this.wordParticles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw regular particles
    for (final particle in particles) {
      // Validate particle properties
      if (particle.x.isNaN || particle.y.isNaN || particle.size.isNaN || particle.size <= 0) {
        continue;
      }

      final opacity = particle.life.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }

    // Draw word particles
    for (final wordParticle in wordParticles) {
      // Validate word particle properties
      if (wordParticle.x.isNaN ||
          wordParticle.y.isNaN ||
          wordParticle.size.isNaN ||
          wordParticle.size <= 0 ||
          wordParticle.char.isEmpty) {
        continue;
      }

      final opacity = wordParticle.life.clamp(0.0, 1.0);

      try {
        final textPainter = TextPainter(
          text: TextSpan(
            text: wordParticle.char,
            style: TextStyle(
              color: wordParticle.color.withOpacity(opacity),
              fontSize: wordParticle.size.clamp(1.0, 100.0), // Clamp font size
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Validate text painter dimensions
        if (textPainter.width.isNaN || textPainter.height.isNaN) {
          continue;
        }

        textPainter.paint(
          canvas,
          Offset(
            wordParticle.x - textPainter.width / 2,
            wordParticle.y - textPainter.height / 2,
          ),
        );
      } catch (e) {
        // Skip this particle if text painting fails
        continue;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Particle {
  double x, y;
  double vx, vy;
  Color color;
  double size;
  double life;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.life,
  });

  void update(double gravity, double tiltX, double tiltY) {
    x += vx;
    y += vy;

    // Apply gravity
    vy += gravity;

    // Apply tilt
    vx += tiltX;
    vy += tiltY;

    // Apply friction
    vx *= 0.99;
    vy *= 0.99;

    // Fade out
    life -= 0.008;
    life = life.clamp(0.0, 1.0); // Ensure life stays in valid range

    // Bounce off edges (get screen size dynamically)
    if (x < 0 || x > 400) vx *= -0.8;
    if (y < 0 || y > 800) vy *= -0.8;

    // Clamp position to prevent NaN
    x = x.clamp(-1000.0, 1400.0);
    y = y.clamp(-1000.0, 1800.0);
  }

  bool get isDead => life <= 0;
}

class WordParticle {
  double x, y;
  double vx, vy;
  double targetX, targetY;
  String char;
  Color color;
  double size;
  double life;

  WordParticle({
    required this.x,
    required this.y,
    required this.char,
    required this.color,
    required this.targetX,
    required this.targetY,
    this.vx = 0,
    this.vy = 0,
    this.size = 24,
    this.life = 1.0,
  });

  void update(double gravity, double tiltX, double tiltY) {
    // Move towards target initially, then physics take over
    if (life > 0.7) {
      final dx = targetX - x;
      final dy = targetY - y;
      vx += dx * 0.01;
      vy += dy * 0.01;
    } else {
      // Apply gravity
      vy += gravity;

      // Apply tilt
      vx += tiltX;
      vy += tiltY;
    }

    x += vx;
    y += vy;

    // Apply friction
    vx *= 0.98;
    vy *= 0.98;

    // Fade out
    life -= 0.003;
    life = life.clamp(0.0, 1.0); // Ensure life stays in valid range

    // Bounce off edges
    if (x < 0 || x > 400) vx *= -0.5;
    if (y < 0 || y > 800) vy *= -0.5;

    // Clamp position to prevent NaN
    x = x.clamp(-1000.0, 1400.0);
    y = y.clamp(-1000.0, 1800.0);
  }

  bool get isDead => life <= 0;
}