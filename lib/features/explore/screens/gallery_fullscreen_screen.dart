import 'package:flutter/material.dart';

/// Visor de imágenes a pantalla completa.
/// Permite al usuario hacer zoom (InteractiveViewer) y deslizar entre las
/// diferentes fotos del destino (PageView).
class GalleryFullscreenScreen extends StatefulWidget {
  final List<String> images;   // Lista de URLs de las imágenes
  final int initialIndex;      // Foto que el usuario tocó (para abrir directamente ahí)

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
    // El PageController arranca en el índice exacto de la foto seleccionada
    _controller = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro para resaltar las fotos
      body: Stack(
        children: [
          // ── Carrusel de Imágenes ───────────────────────────────────────
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              // Actualiza el contador de abajo cuando deslizamos
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              // InteractiveViewer es la magia que permite hacer zoom con los dedos (Pinch-to-zoom)
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain, // Mantiene la proporción de la foto
                  ),
                ),
              );
            },
          ),

          // ── 🔙 Botón cerrar (Esquina superior izquierda) ───────────────
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

          // ── 🔢 Indicador inferior (Ej: 2 / 5) ──────────────────────────
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
