import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart';

class DeletionConfirmationPage extends StatefulWidget {
  final List<AssetEntity> imagesToDelete;

  const DeletionConfirmationPage({Key? key, required this.imagesToDelete})
      : super(key: key);

  @override
  State<DeletionConfirmationPage> createState() =>
      _DeletionConfirmationPageState();
}

class _DeletionConfirmationPageState extends State<DeletionConfirmationPage> {
  static const MethodChannel _channel = MethodChannel(
    'com.example.theswipergallery/delete',
  );
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
                      const ThumbnailSize(200, 200),
                    ),
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
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: _isDeleting ? null : _deleteImages,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: _isDeleting
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

    try {
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

      List<String> failedDeletes = [];
      int successCount = 0;

      for (var asset in widget.imagesToDelete) {
        try {
          final file = await asset.file;
          if (file != null) {
            final uri = file.uri.toString();
            debugPrint('Intentando eliminar URI: $uri');

            final success = await _channel.invokeMethod<bool>('delete', {
              'uri': uri,
            });

            if (success == true) {
              successCount++;
              debugPrint('Eliminado con éxito el asset: ${asset.id}');
            } else {
              failedDeletes.add(asset.id);
              debugPrint('No se pudo eliminar el asset: ${asset.id}');
            }
          } else {
            failedDeletes.add(asset.id);
            debugPrint('No se pudo obtener el archivo para el asset: ${asset.id}');
          }
        } catch (e) {
          debugPrint('Error eliminando ${asset.id}: $e');
          failedDeletes.add(asset.id);
        }
      }

      await PhotoManager.clearFileCache();

      if (mounted) {
        if (failedDeletes.isEmpty && successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount imágenes eliminadas con éxito'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, successCount);
        } else if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se eliminaron $successCount imágenes. No se pudieron eliminar ${failedDeletes.length} imágenes',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context, successCount);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo eliminar ninguna imagen. Verifica los permisos de la aplicación',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isDeleting = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error general: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }
}
