import 'package:flutter/material.dart';

import '../utils/app_animations.dart';
import '../utils/app_tokens.dart';
import '../views/app_button.dart';

/// Tutorial em 5 etapas curtas: Criar → Servidor → Foto → Conferir → PDF.
/// Mesma API pública de antes ([onClose]).
class TutorialView extends StatefulWidget {
  final VoidCallback onClose;

  const TutorialView({super.key, required this.onClose});

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutorialViewState extends State<TutorialView> {
  final PageController _pages = PageController();
  int _index = 0;

  static const _steps = [
    _TutorialStep(
      icon: Icons.add_circle_outline_rounded,
      title: 'Criar',
      description:
          'Toque em Novo no topo do Emissor para começar um crachá do zero.',
    ),
    _TutorialStep(
      icon: Icons.person_search_rounded,
      title: 'Selecionar servidor',
      description:
          'Busque o servidor pelo nome. Cargo e secretaria preenchem sozinhos — e continuam editáveis.',
    ),
    _TutorialStep(
      icon: Icons.photo_camera_outlined,
      title: 'Adicionar fotografia',
      description:
          'Use uma foto frontal e bem iluminada. Dá para editar, ajustar e até remover o fundo.',
    ),
    _TutorialStep(
      icon: Icons.visibility_outlined,
      title: 'Conferir crachá',
      description:
          'A pré-visualização atualiza em tempo real. O que você vê é o que sai no PDF.',
    ),
    _TutorialStep(
      icon: Icons.picture_as_pdf_outlined,
      title: 'Gerar PDF',
      description:
          'Toque em Gerar PDF para salvar ou compartilhar. Na galeria dá para gerar vários de uma vez.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int i) {
    _pages.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _steps.length - 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Fechar tutorial',
          onPressed: widget.onClose,
        ),
        actions: [
          if (!last)
            AppButton.text(
              label: 'Pular',
              onPressed: widget.onClose,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Row(
                    children: [
                      Text(
                        'Etapa ${_index + 1} de ${_steps.length}',
                        style: const TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            value: (_index + 1) / _steps.length,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _steps.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) =>
                        _StepBody(step: _steps[i], number: i + 1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    children: [
                      if (_index > 0)
                        AppButton.text(
                          label: 'Voltar',
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => _goTo(_index - 1),
                        )
                      else
                        const SizedBox(width: 8),
                      const Spacer(),
                      AppAnimations.animatedListItem(
                        AppButton.primary(
                          label: last ? 'Concluir' : 'Próximo',
                          icon: last
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                          onPressed: last
                              ? widget.onClose
                              : () => _goTo(_index + 1),
                        ),
                        _index,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// Conteúdo de uma etapa: ilustração abstrata + título + descrição.
class _StepBody extends StatelessWidget {
  final _TutorialStep step;
  final int number;

  const _StepBody({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: primary.withValues(alpha: 0.14),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Barras abstratas ao fundo (sugestão de interface).
                  Positioned(
                    left: 28,
                    right: 28,
                    child: Column(
                      children: [
                        _bar(primary, 0.9, 14),
                        const SizedBox(height: 10),
                        _bar(primary, 0.65, 10),
                        const SizedBox(height: 10),
                        _bar(primary, 0.75, 10),
                      ],
                    ),
                  ),
                  // Selo da etapa em destaque.
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(step.icon, size: 44, color: primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '$number. ${step.title}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            step.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 15,
              height: 1.5,
              color: theme.textTheme.bodyMedium?.color
                  ?.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(Color color, double widthFactor, double height) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}
