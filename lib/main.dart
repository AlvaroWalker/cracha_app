import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'models/badge_data.dart';
import 'models/department.dart';
import 'views/badge_view.dart';
import 'controllers/badge_controller.dart';
import 'utils/pdf_generator.dart';
import 'utils/app_colors.dart';
import 'services/badge_manager.dart';
import 'views/saved_badges_page.dart';
import 'views/tutorial_view.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    ChangeNotifierProvider(
      create: (context) => BadgeManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campo Verde — Emissor de Crachás',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryColor,
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          surface: AppColors.cardColor,
        ),
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        fontFamily: 'Rawline',
      ),
      home: const HomePageWidget(),
    );
  }
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late BadgeController _controller;
  final GlobalKey _globalKey = GlobalKey();
  
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = BadgeController(BadgeData());

    _nameController.addListener(() {
      final badgeManager = Provider.of<BadgeManager>(context, listen: false);
      if (badgeManager.currentBadge != null && 
          badgeManager.currentBadge!.name != _nameController.text) {
        badgeManager.updateCurrentBadge(name: _nameController.text.toUpperCase());
      }
    });

    _roleController.addListener(() {
      final badgeManager = Provider.of<BadgeManager>(context, listen: false);
      if (badgeManager.currentBadge != null && 
          badgeManager.currentBadge!.role != _roleController.text) {
        badgeManager.updateCurrentBadge(role: _roleController.text.toUpperCase());
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final badgeManager = Provider.of<BadgeManager>(context, listen: false);
      badgeManager.initBadges().then((_) {
        if (mounted && badgeManager.currentBadge != null) {
          setState(() {
            _controller = BadgeController(badgeManager.currentBadge!);
            _nameController.text = badgeManager.currentBadge!.name;
            _roleController.text = badgeManager.currentBadge!.role;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 960;

    return Consumer<BadgeManager>(
      builder: (context, badgeManager, child) {
        if (badgeManager.currentBadge == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            ),
          );
        }

        final badgeData = badgeManager.currentBadge!;

        // Sincroniza o texto do input apenas quando alterado por fora (ex: ao carregar outro crachá)
        if (_nameController.text != badgeData.name) {
          _nameController.value = TextEditingValue(
            text: badgeData.name,
            selection: TextSelection.collapsed(offset: badgeData.name.length),
          );
        }
        if (_roleController.text != badgeData.role) {
          _roleController.value = TextEditingValue(
            text: badgeData.role,
            selection: TextSelection.collapsed(offset: badgeData.role.length),
          );
        }

        if (_controller.badgeData != badgeData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _controller = BadgeController(badgeData);
            });
          });
        }

        return Scaffold(
          body: Container(
            color: AppColors.backgroundColor,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeaderNavBar(badgeManager, isDesktop),
                  Expanded(
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Lado Esquerdo - Controles e Formulário
                              Expanded(
                                flex: 5,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(32.0),
                                  child: _buildEditorPanel(badgeManager, badgeData),
                                ),
                              ),
                              VerticalDivider(
                                width: 1,
                                thickness: 1,
                                color: Colors.grey.shade200,
                              ),
                              // Lado Direito - Pré-visualização do Crachá
                              Expanded(
                                flex: 5,
                                child: Container(
                                  color: AppColors.lightGreen.withValues(alpha: 0.3),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(32.0),
                                    child: _buildPreviewPanel(badgeData),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildPreviewPanel(badgeData),
                                const SizedBox(height: 24),
                                _buildEditorPanel(badgeManager, badgeData),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderNavBar(BadgeManager badgeManager, bool isDesktop) {
    return Container(
      height: isDesktop ? 70 : 56,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.accentColor.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Branding
          Flexible(
            child: Row(
              children: [
                Image.asset('assets/images/brasao.png', height: 36, errorBuilder: (_, __, ___) {
                  return const Icon(Icons.account_balance_rounded, color: AppColors.primaryColor, size: 28);
                }),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CAMPO VERDE',
                        style: TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryColor,
                          letterSpacing: 1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isDesktop)
                        Text(
                          'Emissor Digital de Crachás',
                          style: TextStyle(
                            fontFamily: 'Rawline',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.subtitleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão Criar Novo
              isDesktop
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                        foregroundColor: AppColors.primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Novo Crachá'),
                      onPressed: () {
                        badgeManager.createNewBadge();
                        setState(() {
                          _nameController.text = "";
                          _roleController.text = "";
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Novo modelo de crachá iniciado!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_rounded, color: AppColors.primaryColor),
                      tooltip: 'Novo Crachá',
                      onPressed: () {
                        badgeManager.createNewBadge();
                        setState(() {
                          _nameController.text = "";
                          _roleController.text = "";
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Novo modelo de crachá iniciado!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
              const SizedBox(width: 8),
              // Botão Salvar
              isDesktop
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text('Salvar'),
                      onPressed: () async {
                        final success = await badgeManager.saveCurrentBadge();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Crachá salvo com sucesso!'
                                  : 'Erro ao salvar o crachá.',
                            ),
                            backgroundColor: success ? AppColors.primaryColor : Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.save_rounded, color: AppColors.primaryColor),
                      tooltip: 'Salvar',
                      onPressed: () async {
                        final success = await badgeManager.saveCurrentBadge();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Crachá salvo com sucesso!'
                                  : 'Erro ao salvar o crachá.',
                            ),
                            backgroundColor: success ? AppColors.primaryColor : Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
              const SizedBox(width: 4),
              // Botão de Tutorial/Ajuda
              IconButton(
                icon: Icon(Icons.help_outline_rounded, color: AppColors.primaryColor, size: isDesktop ? 26 : 22),
                tooltip: 'Como Usar',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TutorialView(
                        onClose: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              ),
              // Botão Galeria / Listar com badge counter
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: Icon(Icons.badge_rounded, color: AppColors.primaryColor, size: isDesktop ? 26 : 22),
                    tooltip: 'Crachás Salvos',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SavedBadgesPage(),
                        ),
                      ).then((_) {
                        if (mounted) {
                          final currentBadge = Provider.of<BadgeManager>(context, listen: false).currentBadge;
                          if (currentBadge != null) {
                            setState(() {
                              _nameController.text = currentBadge.name;
                              _roleController.text = currentBadge.role;
                            });
                          }
                        }
                      });
                    },
                  ),
                  if (badgeManager.badges.isNotEmpty)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accentColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${badgeManager.badges.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPanel(BadgeManager badgeManager, BadgeData badgeData) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 960;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit_note_rounded, color: AppColors.primaryColor, size: isMobile ? 22 : 28),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Dados do Funcionário',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Preencha as informações para atualizar o crachá em tempo real.',
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 14,
            color: AppColors.subtitleColor,
          ),
        ),
        const SizedBox(height: 24),

        // Foto do Perfil Upload Card
        _buildPhotoUploadCard(badgeManager, badgeData),
        const SizedBox(height: 24),

        // Campo Nome Completo
        const Text(
          'Nome do Funcionário',
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontFamily: 'Rawline',
            fontSize: 16,
            color: AppColors.textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'DIGITE O NOME COMPLETO',
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryColor),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Campo Função / Cargo
        const Text(
          'Cargo ou Função',
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _roleController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontFamily: 'Rawline',
            fontSize: 16,
            color: AppColors.textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'DIGITE O CARGO OU FUNÇÃO',
            prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.primaryColor),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Campo Secretaria (Seletor Premium Inline)
        const Text(
          'Secretaria / Departamento',
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: Department.departments.contains(badgeData.department) ? badgeData.department : null,
          hint: const Text(
            'SELECIONE A SECRETARIA',
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 15,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.subtitleColor),
          style: const TextStyle(
            fontFamily: 'Rawline',
            fontSize: 15,
            color: AppColors.textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.account_balance_outlined, color: AppColors.primaryColor),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
          ),
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: Department.departments.map((String dept) {
            return DropdownMenuItem<String>(
              value: dept,
              child: Text(
                dept,
                style: const TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              badgeManager.updateCurrentBadge(department: newValue);
              _controller.updateDepartment(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPhotoUploadCard(BadgeManager badgeManager, BadgeData badgeData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Circular Preview / Upload State
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: badgeData.photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          badgeData.photo!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.person_rounded, size: 50, color: AppColors.primaryColor),
              ),
              if (badgeData.photo != null)
                GestureDetector(
                  onTap: () {
                    badgeManager.updateCurrentBadge(photo: null);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto do Crachá',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Formatos sugeridos: JPG ou PNG. Use fotos frontais nítidas.',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 12,
                    color: AppColors.subtitleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                      label: const Text('Carregar Foto', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final bytes = await _controller.pickImage(context);
                        if (bytes != null) {
                          badgeManager.updateCurrentBadge(photo: bytes);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(BadgeData badgeData) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 960;
    // Scale badge to fit in screen on small phones
    final double maxBadgeWidth = isMobile
        ? (screenWidth - 72).clamp(220, 340)
        : 340;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'PRÉ-VISUALIZAÇÃO EM TEMPO REAL',
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: isMobile ? 11 : 13,
            fontWeight: FontWeight.w900,
            color: AppColors.subtitleColor,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: isMobile ? 14 : 20),
        // Live Badge Floating Frame
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.12),
                spreadRadius: 2,
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                spreadRadius: 0,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppColors.accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: RepaintBoundary(
            key: _globalKey,
            child: SizedBox(
              width: maxBadgeWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: BadgeView(
                  badgeData: badgeData,
                  onImageTap: () async {
                    final badgeManager = Provider.of<BadgeManager>(context, listen: false);
                    final bytes = await _controller.pickImage(context);
                    if (bytes != null) {
                      badgeManager.updateCurrentBadge(photo: bytes);
                    }
                  },
                  onNameTap: () {},
                  onRoleTap: () {},
                  onDepartmentTap: () {},
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 20 : 32),
        // Export Action Button
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? screenWidth - 48 : 320),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [AppColors.primaryColor, AppColors.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 18),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 24),
              label: Text(
                'GERAR CRACHÁ (PDF)',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: isMobile ? 13 : 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              onPressed: () => PdfGenerator.generateAndSharePdf(
                _globalKey,
                context,
                badgeData: badgeData,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
