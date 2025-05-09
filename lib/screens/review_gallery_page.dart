import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'deletion_confirmation_page.dart';

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
  double _dragThreshold = 100.0;

  // Cache de imágenes
  final Map<int, Future<Uint8List?>> _imageCache = {};

  @override
  void initState() {
    super.initState();
    _images = widget.initialImages;
    _precacheImage(_currentIndex);
  }

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
    final toRemove = _images[_currentIndex];
    _toDelete.add(toRemove);

    setState(() {
      _images.removeAt(_currentIndex);
      if (_currentIndex >= _images.length) {
        _processDeletedImages();
      } else {
        _dragPosition = 0;
        _isDragging = false;
        _precacheImage(_currentIndex);
      }
    });
  }

  void _handleUndo() {
    setState(() {
      if (_toDelete.isNotEmpty) {
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
    setState(() {
      if (_currentIndex < _images.length - 1) {
        _currentIndex++;
        _dragPosition = 0;
        _isDragging = false;
        _precacheImage(_currentIndex + 1);
      } else {
        _dragPosition = 0;
        _isDragging = false;
        _processDeletedImages();
      }
    });
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

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DeletionConfirmationPage(imagesToDelete: _toDelete),
      ),
    );

    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition += details.primaryDelta!;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragPosition > _dragThreshold) {
      _handleKeep();
    } else if (_dragPosition < -_dragThreshold) {
      _handleDelete();
    } else {
      setState(() {
        _dragPosition = 0;
        _isDragging = false;
      });
    }
  }

  void _onHorizontalDragCancel() {
    setState(() {
      _dragPosition = 0;
      _isDragging = false;
    });
  }

  Color _getDragOverlayColor() {
    if (!_isDragging || _dragPosition == 0) return Colors.transparent;
    if (_dragPosition > 0) {
      double intensity = (_dragPosition / _dragThreshold).clamp(0.0, 1.0) * 0.3;
      return Colors.green.withOpacity(intensity);
    } else {
      double intensity =
          (-_dragPosition / _dragThreshold).clamp(0.0, 1.0) * 0.3;
      return Colors.red.withOpacity(intensity);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
                  FutureBuilder<Uint8List?>(
                    future: _imageCache[_currentIndex],
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
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
                                      gaplessPlayback: true,
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
                          color: _dragPosition > 0
                              ? Colors.green.withOpacity(0.8)
                              : Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _dragPosition > 0 ? Icons.check : Icons.delete,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _dragPosition > 0 ? "GUARDAR" : "ELIMINAR",
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
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
