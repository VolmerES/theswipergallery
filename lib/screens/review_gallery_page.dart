import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class ReviewGalleryPage extends StatefulWidget {
  final List<AssetEntity> initialImages;

  const ReviewGalleryPage({super.key, required this.initialImages});

  @override
  State<ReviewGalleryPage> createState() => _ReviewGalleryPageState();
}

class _ReviewGalleryPageState extends State<ReviewGalleryPage> {
  late List<AssetEntity> _images;
  List<AssetEntity> _toDelete = [];
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Variables para la animación de swipe
  double _dragPosition = 0;
  bool _isDragging = false;
  double _dragThreshold = 100.0; // Umbral para detectar swipe

  // Variables para cachear las imágenes
  final Map<int, Future<Uint8List?>> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _images = widget.initialImages;
    // Precarga la imagen actual
    _precacheImage(_currentIndex);
  }

  // Método para precachear imágenes
  void _precacheImage(int index) {
    if (!_imageCache.containsKey(index) &&
        index >= 0 &&
        index < _images.length) {
      _imageCache[index] = _images[index].thumbnailDataWithSize(
        const ThumbnailSize(800, 800),
      );
    }
  }

  void _handleKeep() => _nextImage();

  void _handleDelete() {
    _toDelete.add(_images[_currentIndex]);
    _nextImage();
  }

  void _handleUndo() {
    setState(() {
      if (_toDelete.isNotEmpty) {
        // Quitar la última imagen de la lista de eliminación
        _toDelete.removeLast();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se ha restaurado la última imagen'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    });
  }

  void _nextImage() {
    if (_currentIndex < _images.length - 1) {
      setState(() {
        _currentIndex++;
        _dragPosition = 0;
        _isDragging = false;
      });
      // Precachear la siguiente imagen si existe
      _precacheImage(_currentIndex + 1);
    } else {
      _processDeletedImages();
    }
  }

  Future<void> _processDeletedImages() async {
    if (_toDelete.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisión completada, no hay imágenes para eliminar'),
        ),
      );
      Navigator.pop(context);
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Eliminando imágenes...'),
            ],
          ),
        );
      },
    );

    // Request permission before deleting
    final hasPermission = await PhotoManager.requestPermissionExtend();
    if (!hasPermission.hasAccess) {
      // Close the loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se tienen permisos para eliminar imágenes'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context, 0);
      return;
    }

    // Delete the images
    List<String> failedDeletes = [];
    for (var asset in _toDelete) {
      try {
        final result = await PhotoManager.editor.deleteWithIds([asset.id]);
        if (result.isNotEmpty) {
          failedDeletes.addAll(result);
          print('Failed to delete asset: ${asset.id}');
        } else {
          print('Successfully deleted asset: ${asset.id}');
        }
      } catch (e) {
        print('Error deleting asset ${asset.id}: $e');
        failedDeletes.add(asset.id);
      }
    }

    // Close the loading dialog
    Navigator.pop(context);

    // Show result message
    final successCount = _toDelete.length - failedDeletes.length;
    if (failedDeletes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount imágenes eliminadas con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se eliminaron $successCount imágenes. No se pudieron eliminar ${failedDeletes.length} imágenes',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    Navigator.pop(context, successCount);
  }

  // Método para manejar el swipe
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition += details.primaryDelta!;
    });
  }

  // Método para finalizar el swipe
  void _onHorizontalDragEnd(DragEndDetails details) {
    // Detectar swipe a la derecha (guardar)
    if (_dragPosition > _dragThreshold) {
      _handleKeep();
    }
    // Detectar swipe a la izquierda (eliminar)
    else if (_dragPosition < -_dragThreshold) {
      _handleDelete();
    }
    // Si no alcanzó el umbral, resetear posición
    else {
      setState(() {
        _dragPosition = 0;
        _isDragging = false;
      });
    }
  }

  // Restablecer posición si se cancela el gesto
  void _onHorizontalDragCancel() {
    setState(() {
      _dragPosition = 0;
      _isDragging = false;
    });
  }

  // Método para determinar el color de tinte según la dirección del arrastre
  Color _getDragOverlayColor() {
    if (!_isDragging || _dragPosition == 0) return Colors.transparent;

    // Swipe derecha (guardar) -> verde, Swipe izquierda (eliminar) -> rojo
    if (_dragPosition > 0) {
      double intensity = (_dragPosition / _dragThreshold).clamp(0.0, 1.0) * 0.3;
      return Colors.green.withOpacity(
        intensity,
      ); // Corregido: verde para guardar (derecha)
    } else {
      double intensity =
          (-_dragPosition / _dragThreshold).clamp(0.0, 1.0) * 0.3;
      return Colors.red.withOpacity(
        intensity,
      ); // Corregido: rojo para eliminar (izquierda)
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Precarga la imagen actual si no está en caché
    _precacheImage(_currentIndex);

    return Scaffold(
      appBar: AppBar(title: const Text("Revisión de galería")),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onHorizontalDragCancel: _onHorizontalDragCancel,
              child: Stack(
                children: [
                  // Mostrar imagen usando FutureBuilder y AnimatedBuilder para suavizar las transformaciones
                  FutureBuilder<Uint8List?>(
                    future: _imageCache[_currentIndex],
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        return AnimatedBuilder(
                          animation: Listenable.merge(
                            [],
                          ), // Un truco para reconstruir solo cuando se llama a setState
                          builder: (context, _) {
                            return Transform.translate(
                              offset: Offset(_dragPosition, 0),
                              child: Transform.rotate(
                                angle: _dragPosition / 1000,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  margin: const EdgeInsets.all(10),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.contain,
                                          gaplessPlayback:
                                              true, // Evita parpadeos al cambiar de imagen
                                        ),
                                      ),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          color: _getDragOverlayColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  ),
                  if (_isDragging && _dragPosition.abs() > 20)
                    Positioned(
                      top: 20,
                      left: _dragPosition > 0 ? 20 : null,
                      right: _dragPosition < 0 ? 20 : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _dragPosition > 0
                                  ? Colors.green.withOpacity(
                                    0.8,
                                  ) // Corregido: verde para guardar (derecha)
                                  : Colors.red.withOpacity(
                                    0.8,
                                  ), // Corregido: rojo para eliminar (izquierda)
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _dragPosition > 0
                                  ? Icons.check
                                  : Icons
                                      .delete, // Corregido: iconos consistentes
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _dragPosition > 0
                                  ? "GUARDAR"
                                  : "ELIMINAR", // Corregido: texto correcto
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "${_currentIndex + 1} de ${_images.length}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
