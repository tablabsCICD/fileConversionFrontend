import 'dart:async';
import 'package:file_convertor/app/app.dart';
import 'package:file_convertor/app/theme/app_palette.dart';
import 'package:file_convertor/app/theme/app_tokens.dart';
import 'package:file_convertor/app/theme/app_typography.dart';
import 'package:file_convertor/core/widgets/brand_mark.dart';
import 'package:file_convertor/core/services/permissions_service.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Timer(const Duration(milliseconds: 2500), _goNext);
  }

  void _goNext() async {
    // Ask for media access up front, but never block the app on it: the
    // Storage view explains what is missing and can ask again.
    try {
      await PermissionsService.ensureStoragePermission();
    } catch (_) {
      // Permission APIs are unavailable on some platforms (web, desktop).
    }
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = context.palette;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _backgroundDecor(theme),

          Center(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _logo(theme),
                      const SizedBox(height: AppSpace.lg + 4),
                      Text.rich(
                        const TextSpan(
                          children: [
                            TextSpan(text: 'File '),
                            TextSpan(
                              text: 'Convertor',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        style: theme.textTheme.displaySmall,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        "CONVERT · SHARE · SECURE",
                        style: AppType.eyebrow.copyWith(color: p.inkMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LOGO
  // ------------------------------------------------------------
  Widget _logo(ThemeData theme) {
    return const BrandMark(size: 88, showWordmark: false);
  }

  // ------------------------------------------------------------
  // BACKGROUND DECOR — a quiet grid of hairlines, like a cutting mat.
  // ------------------------------------------------------------
  Widget _backgroundDecor(ThemeData theme) {
    final p = context.palette;
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _GridPainter(color: p.line, accent: p.accent),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 40.0;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = (size.width % step) / 2; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (var y = (size.height % step) / 2; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    // Soft accent bloom behind the mark.
    final c = size.center(Offset.zero);
    canvas.drawCircle(
      c,
      size.shortestSide * 0.6,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                accent.withValues(alpha: 0.10),
                accent.withValues(alpha: 0),
              ],
            ).createShader(
              Rect.fromCircle(center: c, radius: size.shortestSide * 0.6),
            ),
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.color != color || old.accent != accent;
}
