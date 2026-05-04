import 'package:flutter/material.dart';

import '../../data/services/api_service.dart';
import '../../data/services/content_page_service.dart';

class ContentPageScreen extends StatefulWidget {
  final String slug;
  final String fallbackTitle;

  const ContentPageScreen({
    super.key,
    required this.slug,
    required this.fallbackTitle,
  });

  @override
  State<ContentPageScreen> createState() => _ContentPageScreenState();
}

class _ContentPageScreenState extends State<ContentPageScreen> {
  late final ContentPageService service;

  bool loading = true;
  String? error;
  Map<String, dynamic>? page;
  List<Map<String, dynamic>> children = [];

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFFF59E0B);
  static const Color green = Color(0xFF16A34A);
  static const Color purple = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);

  bool get isTempleSongsIndex => widget.slug == 'temple-songs-prayers';

  @override
  void initState() {
    super.initState();
    service = ContentPageService(ApiService());
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await service.getContentPage(widget.slug);

      List<Map<String, dynamic>> childResult = [];

      if (isTempleSongsIndex) {
        childResult = await service.getContentPageChildren(widget.slug);

        childResult.sort((a, b) {
          final aOrder = _asInt(a['sortOrder']);
          final bOrder = _asInt(b['sortOrder']);

          if (aOrder != bOrder) return aOrder.compareTo(bOrder);

          final aTitle = a['title']?.toString() ?? '';
          final bTitle = b['title']?.toString() ?? '';

          return aTitle.compareTo(bTitle);
        });
      }

      if (!mounted) return;

      setState(() {
        page = result;
        children = childResult;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        error = 'Could not load content';
        loading = false;
      });
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _cleanBody(String body, String title) {
    final trimmed = body.trim();

    if (trimmed.startsWith('# $title')) {
      return trimmed.replaceFirst('# $title', '').trim();
    }

    if (trimmed.startsWith('#$title')) {
      return trimmed.replaceFirst('#$title', '').trim();
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final title = page?['title']?.toString() ?? widget.fallbackTitle;
    final subtitle = page?['subtitle']?.toString() ?? '';
    final body = page?['body']?.toString() ?? '';
    final heroImageUrl = page?['heroImageUrl']?.toString() ?? '';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _ErrorState(message: error!, onRetry: load)
          : RefreshIndicator(
              onRefresh: load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(
                      title: title,
                      subtitle: subtitle,
                      imageUrl: heroImageUrl,
                      isTempleSongs: isTempleSongsIndex,
                    ),
                    const SizedBox(height: 18),
                    if (isTempleSongsIndex)
                      _TempleSongsIndex(intro: body, children: children)
                    else
                      _ContentDetailCard(
                        title: title,
                        body: _cleanBody(body, title),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final bool isTempleSongs;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.isTempleSongs,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTempleSongs
              ? const [Color(0xFFFFF7ED), Color(0xFFF3E8FF)]
              : const [Color(0xFFEFF6FF), Color(0xFFE8F7EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color:
                (isTempleSongs
                        ? _ContentPageScreenState.accent
                        : _ContentPageScreenState.primary)
                    .withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                imageUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 18),
          ] else
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isTempleSongs
                    ? Icons.library_music_rounded
                    : Icons.self_improvement_rounded,
                color: isTempleSongs
                    ? _ContentPageScreenState.accent
                    : _ContentPageScreenState.primary,
                size: 38,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ContentPageScreenState.textDark,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ContentPageScreenState.textMuted,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TempleSongsIndex extends StatelessWidget {
  final String intro;
  final List<Map<String, dynamic>> children;

  const _TempleSongsIndex({required this.intro, required this.children});

  static const colors = [
    Color(0xFF2F6FED),
    Color(0xFFF59E0B),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return _EmptyContentCard(
        title: 'No prayers added yet',
        message: 'Prayers and songs added from admin will appear here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intro.trim().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              intro.trim(),
              style: const TextStyle(
                color: _ContentPageScreenState.textMuted,
                fontSize: 14.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Select a Prayer or Song',
            style: TextStyle(
              color: _ContentPageScreenState.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ...children.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final color = colors[index % colors.length];

          final slug = item['slug']?.toString() ?? '';
          final title = item['title']?.toString() ?? 'Untitled';
          final subtitle = item['subtitle']?.toString() ?? '';
          final sortOrder = item['sortOrder']?.toString() ?? '${index + 1}';

          return _PrayerIndexCard(
            number: sortOrder,
            title: title,
            subtitle: subtitle,
            color: color,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ContentPageScreen(slug: slug, fallbackTitle: title),
                ),
              );
            },
          );
        }),
      ],
    );
  }
}

class _PrayerIndexCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PrayerIndexCard({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.18),
                        color.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ContentPageScreenState.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _ContentPageScreenState.textMuted,
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, color: color, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentDetailCard extends StatelessWidget {
  final String title;
  final String body;

  const _ContentDetailCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final paragraphs = body
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _ContentPageScreenState.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _ContentPageScreenState.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ContentPageScreenState.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (paragraphs.isEmpty)
            const Text(
              'No content added yet.',
              style: TextStyle(
                color: _ContentPageScreenState.textMuted,
                fontSize: 15,
              ),
            )
          else
            ...paragraphs.map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  paragraph,
                  style: const TextStyle(
                    color: _ContentPageScreenState.textDark,
                    fontSize: 15.5,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyContentCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyContentCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.library_music_rounded,
            color: _ContentPageScreenState.accent,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _ContentPageScreenState.textDark,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ContentPageScreenState.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: _ContentPageScreenState.primary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ContentPageScreenState.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
