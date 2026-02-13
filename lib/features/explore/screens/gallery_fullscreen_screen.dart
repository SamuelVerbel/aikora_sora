import 'package:flutter/material.dart';

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

class _GalleryFullscreenScreenState
    extends State<GalleryFullscreenScreen> {
  late PageController _controller;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // 🔙 Botón cerrar
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

          // 🔢 Indicador inferior
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}