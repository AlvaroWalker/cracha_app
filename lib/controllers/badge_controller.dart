import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_image/crop_image.dart';
import 'dart:ui' as ui;
import '../models/badge_data.dart';
import '../utils/app_colors.dart';

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

      // Selecionar a imagem da fonte escolhida
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
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
      final controller = CropController(
        aspectRatio: 3 / 4,
        defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
      );

      final imageBytes = await pickedFile.readAsBytes();

      // Mostra o diálogo de recorte com a imagem
      if (!context.mounted) return null;
      final croppedBytes = await showDialog<Uint8List>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: const Text(
                  'Ajustar Foto do Crachá',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                width: MediaQuery.of(context).size.width * 0.8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CropImage(
                    controller: controller,
                    image: Image.memory(imageBytes),
                    gridColor: AppColors.primaryColor,
                    gridCornerSize: 25,
                    gridThinWidth: 2,
                    gridThickWidth: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontWeight: FontWeight.bold,
                        color: AppColors.subtitleColor,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () async {
                      final bitmap = await controller.croppedBitmap();
                      final data = await bitmap.toByteData(
                          format: ui.ImageByteFormat.png);
                      if (context.mounted) {
                        Navigator.pop(context, data!.buffer.asUint8List());
                      }
                    },
                    child: const Text(
                      'Recortar',
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

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
