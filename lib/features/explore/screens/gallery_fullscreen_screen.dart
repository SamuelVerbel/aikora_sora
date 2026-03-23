import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Visor de imágenes a pantalla completa.
/// Permite zoom (InteractiveViewer) y deslizar entre fotos (PageView).
class GalleryFullscreenScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const GalleryFullscreenScreen({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<GalleryFullscreenScreen> createState() =>
      _GalleryFullscreenScreenState();
}

class _GalleryFullscreenScreenState extends State<GalleryFullscreenScreen> {
  late final PageController _controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    // FIX: dispose del controller para evitar memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // Carrusel con zoom
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) =>
                setState(() => currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
                ),
              );
            },
          ),

          // Botón cerrar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // Contador
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}