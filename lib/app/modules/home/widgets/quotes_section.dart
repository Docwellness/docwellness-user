import 'dart:async';

import 'package:docwellness/app/modules/home/controllers/quotes_controller.dart';
import 'package:docwellness/app/modules/home/views/motivation_view.dart';
import 'package:docwellness/utils/app_theme/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kInk = Color(0xff5A2A44); // quote body
const _kPlum = Color(0xff851653);
const _kPink = Color(0xff9F1561);
const _kDeep = Color(0xff530630);
const _kMeta = Color(0xff9C6B85); // author line
const _kCardTop = Color(0xffFFF4FA);
const _kCardBottom = Color(0xffFBE4F1);
const _kBorder = Color(0xffF3D3E4);
const _kDotOff = Color(0xffE9C6DA);

const _kEaseOut = Cubic(0.23, 1, 0.32, 1);

/// Curated static fallback so the section is never empty on a cold/offline
/// start (the API set mirrors these).
const List<Map<String, String>> _kFallbackQuotes = [
  {
    'text': 'Let food be thy medicine, and medicine be thy food.',
    'author': 'Hippocrates',
    'category': 'Nutrition',
  },
  {
    'text': "Take care of your body. It's the only place you have to live.",
    'author': 'Jim Rohn',
    'category': 'Wellness',
  },
  {
    'text': 'Your body hears everything your mind says.',
    'author': 'Naomi Judd',
    'category': 'Mindfulness',
  },
  {
    'text': 'Progress, not perfection. Every meal is a fresh start.',
    'author': 'DocWellness',
    'category': 'Nutrition',
  },
  {
    'text': 'Small daily habits compound into a life you are proud of.',
    'author': 'DocWellness',
    'category': 'Wellness',
  },
];

class QuotesSection extends StatefulWidget {
  const QuotesSection({super.key});

  @override
  State<QuotesSection> createState() => _QuotesSectionState();
}

class _QuotesSectionState extends State<QuotesSection>
    with WidgetsBindingObserver {
  final QuotesController _controller = Get.isRegistered<QuotesController>()
      ? Get.find<QuotesController>()
      : Get.put(QuotesController(), permanent: true);

  final PageController _page = PageController(viewportFraction: 0.9);
  int _index = 0;
  Timer? _auto;
  bool _entered = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restartAuto();
    } else {
      _auto?.cancel();
    }
  }

  List<Map<String, dynamic>> _quotes() {
    final api = _controller.quotes
        .where((q) => ((q['text'] as String?) ?? '').trim().isNotEmpty)
        .toList();
    if (api.isNotEmpty) return api;
    return _kFallbackQuotes
        .map((q) => Map<String, dynamic>.from(q))
        .toList();
  }

  void _restartAuto() {
    _auto?.cancel();
    if (_reduceMotion) return;
    _auto = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || !_page.hasClients) return;
      final count = _quotes().length;
      if (count < 2) return;
      final next = (_index + 1) % count;
      _page.animateToPage(
        next,
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _openReader(Map<String, dynamic> q) {
    _auto?.cancel();
    Get.to(
      () => _QuoteReader(
        text: (q['text'] as String?) ?? '',
        author: (q['author'] as String?)?.trim().isNotEmpty == true
            ? q['author'] as String
            : 'DocWellness',
        category: (q['category'] as String?) ?? 'Wellness',
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 220),
    )?.then((_) => _restartAuto());
  }

  @override
  Widget build(BuildContext context) {
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    return Obx(() {
      final loading = _controller.isLoading.value;
      final quotes = _quotes();
      if (_auto == null && !loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _restartAuto());
      }

      return AnimatedSlide(
        offset: _entered || _reduceMotion ? Offset.zero : const Offset(0, 0.06),
        duration: const Duration(milliseconds: 420),
        curve: _kEaseOut,
        child: AnimatedOpacity(
          opacity: _entered || _reduceMotion ? 1 : 0,
          duration: const Duration(milliseconds: 380),
          curve: _kEaseOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _Header(
                  onTap: () => Get.to(() => const MotivationScreen()),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _kPlum),
                      )
                    : Listener(
                        onPointerDown: (_) => _auto?.cancel(),
                        onPointerUp: (_) => _restartAuto(),
                        child: PageView.builder(
                          controller: _page,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemCount: quotes.length,
                          itemBuilder: (context, i) {
                            final q = quotes[i];
                            return AnimatedBuilder(
                              animation: _page,
                              builder: (context, child) {
                                double t = 0;
                                if (_page.position.haveDimensions) {
                                  t = (_page.page ?? _index.toDouble()) - i;
                                }
                                final scale = (1 - (t.abs() * 0.06))
                                    .clamp(0.9, 1.0);
                                return Transform.scale(
                                  scale: _reduceMotion ? 1 : scale,
                                  child: child,
                                );
                              },
                              child: _QuoteCard(
                                text: (q['text'] as String?) ?? '',
                                author:
                                    (q['author'] as String?)?.trim().isNotEmpty ==
                                        true
                                    ? q['author'] as String
                                    : 'DocWellness',
                                category: (q['category'] as String?) ?? 'Wellness',
                                onTap: () => _openReader(q),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              if (!loading && quotes.length > 1) ...[
                const SizedBox(height: 12),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(quotes.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: _kEaseOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? _kPink : _kDotOff,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            CustomText(
              text: 'Daily wisdom',
              fontWeight: FontWeight.w500,
              fontSize: 17,
              color: _kDeep,
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward, color: _kDeep, size: 18),
          ],
        ),
      ),
    );
  }
}

class _QuoteCard extends StatefulWidget {
  const _QuoteCard({
    required this.text,
    required this.author,
    required this.category,
    required this.onTap,
  });

  final String text;
  final String author;
  final String category;
  final VoidCallback onTap;

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 140),
          curve: _kEaseOut,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kCardTop, _kCardBottom],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14851653),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative quote mark, tucked behind the text
                Positioned(
                  left: 14,
                  top: -4,
                  child: Text(
                    '“',
                    style: TextStyle(
                      fontSize: 58,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: _kPlum.withValues(alpha: 0.13),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.text,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 15,
                              height: 1.5,
                              letterSpacing: 0.1,
                              fontWeight: FontWeight.w500,
                              color: _kInk,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _kPlum.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              widget.category.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: _kPink,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Flexible(
                            child: Text(
                              '— ${widget.author}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: _kMeta,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen reader — one quote, centred, on a soft brand gradient.
class _QuoteReader extends StatelessWidget {
  const _QuoteReader({
    required this.text,
    required this.author,
    required this.category,
  });

  final String text;
  final String author;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffFFF4FA), Color(0xffF7D9EA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close, color: _kDeep),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“',
                        style: TextStyle(
                          fontSize: 96,
                          height: 0.7,
                          fontWeight: FontWeight.w700,
                          color: _kPlum.withValues(alpha: 0.18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 24,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                          color: _kInk,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _kPlum.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                                color: _kPink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '— $author',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _kMeta,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
