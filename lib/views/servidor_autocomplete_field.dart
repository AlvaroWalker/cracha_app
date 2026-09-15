import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/servidor_repository.dart';
import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';

/// Campo de nome com autocomplete da base de servidores.
/// Ao selecionar, chama [onServidorSelecionado] para preencher cargo e secretaria.
class ServidorAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final List<Servidor> servidores;
  final ValueChanged<Servidor> onServidorSelecionado;
  final FocusNode? focusNode;

  const ServidorAutocompleteField({
    super.key,
    required this.controller,
    required this.servidores,
    required this.onServidorSelecionado,
    this.focusNode,
  });

  @override
  State<ServidorAutocompleteField> createState() =>
      _ServidorAutocompleteFieldState();
}

class _ServidorAutocompleteFieldState extends State<ServidorAutocompleteField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<Servidor> _sugestoes = [];
  bool _suprimirSugestoes = false;
  bool _carregando = false;
  Timer? _debounce;
  String _lastQuery = '';
  int _itemAtivo = -1; // Índice do item selecionado por teclado

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.focusNode?.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant ServidorAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se a lista de servidores mudou e o controller tem texto, refaz a busca
    if (oldWidget.servidores.length != widget.servidores.length &&
        widget.controller.text.trim().length >= 3) {
      _performSearch(widget.controller.text.trim());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    widget.focusNode?.removeListener(_onFocus);
    _debounce?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocus() {
    if (!(widget.focusNode?.hasFocus ?? false)) {
      // Fecha após 180ms (tempo do tap concluir). Se o foco continua fora,
      // o overlay é obsoleto e morre — sem isso ele grudava para sempre
      // quando um pointer-down não virava seleção (scroll, clique fora).
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        if (widget.focusNode?.hasFocus ?? false) return;
        _removeOverlay();
      });
    } else if (widget.controller.text.trim().length >= 3) {
      // Reabre sugestões quando ganha foco e tem texto
      _performSearch(widget.controller.text.trim());
    }
  }

  void _onChanged() {
    if (_suprimirSugestoes) return;
    final q = widget.controller.text.trim();
    if (q.length < 3) {
      _debounce?.cancel();
      _removeOverlay();
      return;
    }

    // Debounce 200ms para evitar busca a cada tecla
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (q != _lastQuery) {
        _lastQuery = q;
        _performSearch(q);
      }
    });
  }

  void _performSearch(String q) {
    // Busca lazy no Supabase — não precisa mais da lista em memória
    setState(() {
      _carregando = true;
    });

    ServidorRepository.searchRemote(q, limit: 8).then((resultados) {
      if (!mounted) return;
      setState(() {
        _sugestoes = resultados;
        _itemAtivo = -1;
        _carregando = false;
      });
      if (_sugestoes.isEmpty) {
        _removeOverlay();
      } else {
        _showOverlay();
      }
    });
  }

  void _navegarTeclado(int direcao) {
    if (_sugestoes.isEmpty) return;
    setState(() {
      _itemAtivo += direcao;
      if (_itemAtivo < 0) _itemAtivo = _sugestoes.length - 1;
      if (_itemAtivo >= _sugestoes.length) _itemAtivo = 0;
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _selecionarAtivo() {
    if (_itemAtivo >= 0 && _itemAtivo < _sugestoes.length) {
      _selecionar(_sugestoes[_itemAtivo]);
    }
  }

  void _showOverlay() {
    // Resultado tardio com campo desfocado = overlay fantasma. Mata aqui.
    if (widget.focusNode != null && !(widget.focusNode!.hasFocus)) return;
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primary = Theme.of(context).colorScheme.primary;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
            (isDark ? AppColors.darkText : AppColors.textColor);
        final subtitleColor = isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor;
        final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
        final cardColor = isDark ? const Color(0xFF101418) : Colors.white;
        final selectedBg = primary.withValues(alpha: isDark ? 0.16 : 0.08);
        return Positioned(
          width: MediaQuery.of(context).size.width.clamp(300.0, 460.0),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 8),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: AppShadow.lg(context),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Contador de resultados
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Row(
                    children: [
                      Text(
                        '${_sugestoes.length} ${_sugestoes.length == 1 ? 'resultado' : 'resultados'}',
                        style: TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 11,
                          color: subtitleColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      _buildKeyboardHint('↑↓', 'navegar', subtitleColor),
                      const SizedBox(width: 8),
                      _buildKeyboardHint('Enter', 'selecionar', subtitleColor),
                      const SizedBox(width: 8),
                      _buildKeyboardHint('Esc', 'fechar', subtitleColor),
                    ],
                  ),
                ),
                // Lista de sugestões
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shrinkWrap: true,
                    itemCount: _sugestoes.length,
                    itemBuilder: (context, i) {
                      final s = _sugestoes[i];
                      final isAtivo = i == _itemAtivo;
                      return Listener(
                        onPointerHover: (_) {
                          if (_itemAtivo != i) {
                            setState(() => _itemAtivo = i);
                            _overlayEntry?.markNeedsBuild();
                          }
                        },
                        child: InkWell(
                          onTap: () => _selecionar(s),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: isAtivo ? selectedBg : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildHighlightedText(
                                        s.nome,
                                        widget.controller.text.trim(),
                                        TextStyle(
                                          fontFamily: 'Rawline',
                                          fontSize: 14,
                                          fontWeight: isAtivo
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isAtivo ? primary : textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      _buildHighlightedText(
                                        '${s.cargo} • ${s.secretaria}',
                                        widget.controller.text.trim(),
                                        TextStyle(
                                          fontFamily: 'Rawline',
                                          fontSize: 12,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAtivo)
                                  Icon(Icons.arrow_forward_rounded,
                                      size: 16, color: primary),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildKeyboardHint(String tecla, String acao, [Color? color]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = color ?? (isDark ? AppColors.darkText : AppColors.textColor);
    final bgColor = isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade100;
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade300;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            tecla,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          acao,
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 10,
            color: textColor,
          ),
        ),
      ],
    );
  }

  /// Renderiza texto com destaque (negrito) do termo buscado.
  Widget _buildHighlightedText(String text, String query, TextStyle baseStyle) {
    if (query.isEmpty) {
      return Text(
        text,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final highlightStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w800,
      color: AppColors.primaryColor,
    );

    // Suporte a multi-termo (ex: "maria saude")
    final termos =
        query.toUpperCase().split(' ').where((t) => t.isNotEmpty).toList();

    final spans = <TextSpan>[];
    final textUpper = text.toUpperCase();
    int currentIndex = 0;

    while (currentIndex < text.length) {
      // Encontra a próxima ocorrência de qualquer termo
      int earliestMatch = -1;
      int matchLength = 0;

      for (final termo in termos) {
        final idx = textUpper.indexOf(termo, currentIndex);
        if (idx != -1 && (earliestMatch == -1 || idx < earliestMatch)) {
          earliestMatch = idx;
          matchLength = termo.length;
        }
      }

      if (earliestMatch == -1) {
        spans.add(TextSpan(
          text: text.substring(currentIndex),
          style: baseStyle,
        ));
        break;
      }

      if (earliestMatch > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, earliestMatch),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(earliestMatch, earliestMatch + matchLength),
        style: highlightStyle,
      ));

      currentIndex = earliestMatch + matchLength;
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selecionar(Servidor s) {
    _suprimirSugestoes = true;
    _removeOverlay();
    widget.controller.text = s.nome;
    widget.controller.selection = TextSelection.collapsed(offset: s.nome.length);
    widget.onServidorSelecionado(s);
    widget.focusNode?.unfocus();
    _suprimirSugestoes = false;
  }

  void _limparCampo() {
    _removeOverlay();
    widget.controller.clear();
    _lastQuery = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? AppColors.darkText : AppColors.textColor);
    final hintColor = isDark ? AppColors.darkHint : Colors.grey.shade500;
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;
    final fillColor = isDark ? AppColors.darkSurfaceVariant : Colors.white;

    return CompositedTransformTarget(
      link: _layerLink,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          if (_sugestoes.isEmpty) return;

          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowDown:
              _navegarTeclado(1);
            case LogicalKeyboardKey.arrowUp:
              _navegarTeclado(-1);
            case LogicalKeyboardKey.enter:
            case LogicalKeyboardKey.numpadEnter:
              _selecionarAtivo();
            case LogicalKeyboardKey.escape:
              _removeOverlay();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 16,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: 'Nome',
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            labelStyle: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: hintColor,
              letterSpacing: 0.2,
            ),
            floatingLabelStyle: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hintColor,
              letterSpacing: 0.2,
            ),
            hintText: 'Ex: NOME COMPLETO',
            hintStyle: TextStyle(fontFamily: 'Rawline', color: hintColor),
            prefixIcon: Icon(Icons.person_outline_rounded, color: primary),
            suffixIcon: _buildSuffixIcon(),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: primary, width: 2),
            ),
          ),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildSuffixIcon() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.darkHint : AppColors.subtitleColor;
    if (_carregando) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    if (widget.controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear_rounded, size: 20),
        color: hintColor,
        tooltip: 'Limpar',
        onPressed: _limparCampo,
      );
    }
    if (widget.controller.text.trim().length >= 3) {
      return Tooltip(
        message: 'Autocomplete ativo — busca no Supabase',
        child: Icon(Icons.auto_awesome_rounded,
            size: 20, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
      );
    }
    return const SizedBox.shrink();
  }
}
