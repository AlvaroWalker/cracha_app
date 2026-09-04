import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/badge_data.dart';
import '../views/photo_edit_dialog.dart';

class BadgeController {
  final BadgeData badgeData;
  final ImagePicker _picker = ImagePicker();

  BadgeController(this.badgeData);

  // Exibe um diálogo para permitir o usuário escolher entre galeria e câmera
  Future<Uint8List?> pickImage(BuildContext context) async {
    try {
      // Perguntar ao usuário se quer tirar uma foto ou escolher da galeria
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) => SimpleDialog(
          title: const Text('Escolha uma opção'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ImageSource.camera);
              },
              child: const ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Tirar uma foto'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ImageSource.gallery);
              },
              child: const ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Escolher da galeria'),
              ),
            ),
          ],
        ),
      );

      // Se o usuário cancelou a seleção
      if (source == null) return null;

      // Selecionar a imagem da fonte escolhida.
      // Reduzida para 1024px: suficiente para o crachá (153x189 @3x no PDF)
      // e evita fotos de vários MB no upload + base64 local.
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (!context.mounted) return null;
      if (pickedFile != null) {
        try {
          // Usar o recorte de imagem tanto na web quanto em plataformas nativas
          final Uint8List? croppedBytes = await _cropImage(pickedFile, context);
          if (!context.mounted) return null;

          // Verificar explicitamente se o retorno é nulo (usuário cancelou o recorte)
          if (croppedBytes == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recorte de imagem cancelado')),
            );
            return null;
          }

          badgeData.photo = croppedBytes;
          return croppedBytes;
        } catch (e) {
          // Se ocorrer um erro no recorte, usamos a imagem original como fallback
          debugPrint('Erro ao recortar a imagem: $e');
          final bytes = await pickedFile.readAsBytes();
          if (!context.mounted) return null;
          badgeData.photo = bytes;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível recortar a imagem. A foto original foi usada.',
              ),
            ),
          );
          return bytes;
        }
      }
    } catch (e) {
      debugPrint('Erro ao processar a imagem: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar a imagem: $e')),
        );
      }
    }
    return null;
  }

  Future<Uint8List?> _cropImage(XFile pickedFile, BuildContext context) async {
    try {
      final imageBytes = await pickedFile.readAsBytes();

      // Diálogo premium de ajuste e recorte
      if (!context.mounted) return null;
      final croppedBytes = await showPhotoEditDialog(context, imageBytes);

      return croppedBytes;
    } catch (e) {
      debugPrint('Erro no _cropImage: $e');
      rethrow;
    }
  }

  void updateName(String name) {
    badgeData.name = name.toUpperCase();
  }

  void updateRole(String role) {
    badgeData.role = role.toUpperCase();
  }

  void updateDepartment(String department) {
    badgeData.department = department;
  }
}
