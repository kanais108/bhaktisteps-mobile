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

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFF2F6FED);
  static const Color primaryDark = Color(0xFF1E4ED8);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);
  static const Color accent = Color(0xFFF59E0B);
  static const Color green = Color(0xFF16A34A);
  static const Color purple = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);

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

      if (!mounted) return;

      setState(() {
        page = result;
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

  bool get isTempleSongs => widget.slug == 'temple-songs-prayers';

  List<_ContentSection> _parseSections(String body) {
    final lines = body.split('\n');
    final sections = <_ContentSection>[];

    String? currentTitle;
    final buffer = <String>[];

    void flush() {
      if (currentTitle == null && buffer.join('\n').trim().isEmpty) return;

      sections.add(
        _ContentSection(
          title: currentTitle ?? 'Details',
          body: buffer.join('\n').trim(),
        ),
      );

      currentTitle = null;
      buffer.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();

      if (line.trimLeft().startsWith('# ')) {
        flush();
        currentTitle = line.trimLeft().replaceFirst('# ', '').trim();
      } else {
        buffer.add(line);
      }
    }

    flush();

    if (sections.isEmpty && body.trim().isNotEmpty) {
      sections.add(_ContentSection(title: 'Details', body: body.trim()));
    }

    return sections;
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
                      isTempleSongs: isTempleSongs,
                    ),
                    const SizedBox(height: 18),
                    if (isTempleSongs)
                      ..._parseSections(body).asMap().entries.map(
                        (entry) => _SongPrayerCard(
                          index: entry.key,
                          section: entry.value,
                        ),
                      )
                    else
                      _AboutCard(body: body),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ContentSection {
  final String title;
  final String body;

  _ContentSection({required this.title, required this.body});
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
                    ? Icons.music_note_rounded
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

class _SongPrayerCard extends StatelessWidget {
  final int index;
  final _ContentSection section;

  const _SongPrayerCard({required this.index, required this.section});

  static const colors = [
    Color(0xFF2F6FED),
    Color(0xFFF59E0B),
    Color(0xFF16A34A),
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final color = colors[index % colors.length];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.music_note_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    color: _ContentPageScreenState.textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          if (section.body.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              section.body,
              style: const TextStyle(
                color: _ContentPageScreenState.textDark,
                fontSize: 15.5,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String body;

  const _AboutCard({required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Text(
        body,
        style: const TextStyle(
          color: _ContentPageScreenState.textDark,
          fontSize: 15.5,
          height: 1.55,
          fontWeight: FontWeight.w500,
        ),
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
