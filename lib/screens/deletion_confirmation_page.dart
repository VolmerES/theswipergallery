import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class DeletionConfirmationPage extends StatefulWidget {
  final List<AssetEntity> imagesToDelete;

  const DeletionConfirmationPage({Key? key, required this.imagesToDelete})
    : super(key: key);

  @override
  State<DeletionConfirmationPage> createState() =>
      _DeletionConfirmationPageState();
}

class _DeletionConfirmationPageState extends State<DeletionConfirmationPage> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirmar eliminación")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Has seleccionado ${widget.imagesToDelete.length} imágenes para eliminar",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: widget.imagesToDelete.length,
              itemBuilder: (context, index) {
                final asset = widget.imagesToDelete[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: FutureBuilder<Uint8List?>(
                    future: asset.thumbnailDataWithSize(
                      ThumbnailSize(200, 200),
                    ), // wrap in ThumbnailSize
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      }
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                      _isDeleting
                          ? null
                          : () {
                            Navigator.pop(context); // Cancel and go back
                          },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: _isDeleting ? null : _deleteImages,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child:
                      _isDeleting
                          ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text("Eliminando..."),
                            ],
                          )
                          : const Text("Confirmar eliminación"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteImages() async {
    setState(() {
      _isDeleting = true;
    });

    // Request permission before deleting
    final hasPermission = await PhotoManager.requestPermissionExtend();
    if (!hasPermission.hasAccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se tienen permisos para eliminar imágenes'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isDeleting = false;
        });
      }
      return;
    }

    // Delete the images
    List<String> failedDeletes = [];
    for (var asset in widget.imagesToDelete) {
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

    // Show result message if still mounted
    if (mounted) {
      final successCount = widget.imagesToDelete.length - failedDeletes.length;
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

      Navigator.pop(
        context,
        successCount,
      ); // Return to previous screen with count
    }
  }
}
