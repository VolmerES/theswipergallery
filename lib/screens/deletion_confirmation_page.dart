import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const MethodChannel _channel =
      MethodChannel('com.example.theswipergallery/delete');
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
            child: ElevatedButton.icon(
              onPressed: _isDeleting ? null : _deleteImages,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.delete),
              label: _isDeleting
                  ? const Text("Eliminando...")
                  : Text("Borrar ${widget.imagesToDelete.length} imágenes"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteImages() async {
    setState(() => _isDeleting = true);

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth && !permission.hasAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Permiso denegado para acceder a fotos"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isDeleting = false);
      return;
    }

    List<String> failed = [];
    int successCount = 0;

    for (var asset in widget.imagesToDelete) {
      try {
        final uri = Uri.parse("content://media/external/images/media/${asset.id}");
        final success = await _channel.invokeMethod<bool>('delete', {
          'uri': uri.toString(),
          'moveToTrash': true, // <- Aquí lo activamos
        });

        if (success == true) {
          successCount++;
        } else {
          failed.add(asset.id);
        }
      } catch (e) {
        debugPrint("Error al eliminar ${asset.id}: $e");
        failed.add(asset.id);
      }
    }

    await PhotoManager.clearFileCache();

    if (!mounted) return;

    if (failed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Se enviaron $successCount imágenes a la papelera"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Se eliminaron $successCount imágenes. Fallaron: ${failed.length}"),
          backgroundColor: Colors.orange,
        ),
      );
    }

    Navigator.pop(context, successCount);
  }
}
