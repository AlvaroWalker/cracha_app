import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_animations.dart';

class TutorialView extends StatefulWidget {
  final VoidCallback onClose;

  const TutorialView({super.key, required this.onClose});

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se o dispositivo é um tablet/desktop ou celular
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: const Text('Como usar o Gerador de Crachá'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isLargeScreen ? 30.0 : 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isLargeScreen ? 800 : 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Bem-vindo ao Gerador de Crachá!'),
                const SizedBox(height: 20),
                _buildSection(
                  'Como adicionar uma foto:',
                  'Toque na área da foto para escolher uma imagem da galeria',
                  Icons.image,
                  0,
                ),
                _buildSection(
                  'Como editar o nome:',
                  'Toque no nome para editar e personalizar o crachá',
                  Icons.edit,
                  1,
                ),
                _buildSection(
                  'Como alterar a função:',
                  'Toque na função atual para alterar para o cargo correto',
                  Icons.work,
                  2,
                ),
                _buildSection(
                  'Como selecionar a secretaria:',
                  'Toque no nome da secretaria para selecionar a correta na lista',
                  Icons.business,
                  3,
                ),
                _buildSection(
                  'Como exportar o crachá:',
                  'Use o botão flutuante de PDF para gerar e compartilhar seu crachá',
                  Icons.picture_as_pdf,
                  4,
                ),
                const SizedBox(height: 30),
                Center(
                  child: AppAnimations.animatedListItem(
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Começar a usar'),
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    5,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _animationController.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _animationController.value)),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
      String title, String description, IconData icon, int index) {
    return AppAnimations.animatedListItem(
      Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.lightGreen.withValues(alpha: 0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primaryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textColor.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
      index,
      delay: const Duration(milliseconds: 100),
    );
  }
}
