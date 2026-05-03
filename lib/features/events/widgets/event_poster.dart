import 'package:flutter/material.dart';

class EventPoster extends StatelessWidget {
  final String imageUrl;

  const EventPoster({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9, // clean banner ratio
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullScreenPoster(imageUrl: imageUrl)),
    );
  }
}

class _FullScreenPoster extends StatelessWidget {
  final String imageUrl;

  const _FullScreenPoster({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
