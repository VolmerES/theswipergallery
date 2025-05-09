import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class DeletionConfirmationPage extends StatefulWidget {
  final List<AssetEntity> imagesToDelete;

  const DeletionConfirmationPage({
    Key? key,
    required this.imagesToDelete,
  }) : super(key: key);

  @override
  State<DeletionConfirmationPage> createState() =>
      _DeletionConfirmationPageState();
}

class _DeletionConfirmationPageState extends State<DeletionConfirmationPage> {
  bool _isDeleting = false;

  Future<void> _deleteImages() async {
    setState(() => _isDeleting = true);

    // 1. Verificar permiso de lectura (total o limitado)
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin permiso para acceder a las fotos'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isDeleting = false);
      return;
    }

    try {
      // 2. Delegar en PhotoManager para borrar
      final ids = widget.imagesToDelete.map((e) => e.id).toList();
      // En Android 11+ invocará el diálogo nativo de confirmación de borrado
      final failed = await PhotoManager.editor.deleteWithIds(ids);

      // 3. Limpiar caché interno
      await PhotoManager.clearFileCache();

      if (!mounted) return;

      // 4. Mostrar resultado y regresar
      if (failed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imágenes enviadas a la papelera'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudieron eliminar ${failed.length} imágenes'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isDeleting = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al borrar: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar borrado')),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4),
                    itemCount: widget.imagesToDelete.length,
                    itemBuilder: (_, i) => FutureBuilder<Uint8List?>(
                      future: widget.imagesToDelete[i]
                          .thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                      builder: (_, snap) {
                        final b = snap.data;
                        return b != null
                            ? Image.memory(b, fit: BoxFit.cover)
                            : Container(color: Colors.grey[300]);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton.icon(
                    onPressed: _deleteImages,
                    icon: const Icon(Icons.delete_forever),
                    label: Text(
                      _isDeleting
                          ? 'Procesando...'
                          : 'Borrar ${widget.imagesToDelete.length}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
