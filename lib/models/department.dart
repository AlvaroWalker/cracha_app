class Department {
  static final List<String> departments = [
    "SECRETARIA MUNICIPAL DE ADMINISTRAÇÃO E RECURSOS HUMANOS",
    "SECRETARIA MUNICIPAL DE AGRICULTURA E MEIO AMBIENTE",
    "SECRETARIA MUNICIPAL DE ASSISTÊNCIA SOCIAL E HABITAÇÃO",
    "SECRETARIA MUNICIPAL DE CIÊNCIA E TECNOLOGIA",
    "SECRETARIA MUNICIPAL DE CULTURA E JUVENTUDE",
    "SECRETARIA MUNICIPAL DE DESENVOLVIMENTO ECONÔMICO",
    "SECRETARIA MUNICIPAL DE EDUCAÇÃO",
    "SECRETARIA MUNICIPAL DE ESPORTE E LAZER",
    "SECRETARIA MUNICIPAL DE FAZENDA",
    "SECRETARIA MUNICIPAL DE FINANÇAS",
    "SECRETARIA MUNICIPAL DE GABINETE",
    "SECRETARIA MUNICIPAL DE OBRAS E VIAÇÃO",
    "SECRETARIA MUNICIPAL DE PLANEJAMENTO",
    "SECRETARIA MUNICIPAL DE SAÚDE",
    "SECRETARIA MUNICIPAL INTEGRADA DE APOIO À SEGURANÇA",
  ];

  /// Converte a secretaria vinda do cadastro de servidores (CSV/Supabase,
  /// ex: "ADMINISTRACAO E RECURSOS HUMANOS") para a forma canônica do crachá
  /// (ex: "SECRETARIA MUNICIPAL DE ADMINISTRAÇÃO E RECURSOS HUMANOS").
  ///
  /// Regra: sempre prefixa "SECRETARIA MUNICIPAL" — o cadastro de servidores
  /// não carrega o órgão completo, e o crachá precisa. Se já estiver com o
  /// prefixo ou não casar com nada conhecido, devolve como veio.
  static String canonical(String raw) {
    final t = raw.trim().toUpperCase();
    if (t.isEmpty) return t;
    if (t.startsWith('SECRETARIA MUNICIPAL')) return t;
    // Forma curta do cadastro -> forma completa do crachá.
    if (t == 'ADMINISTRACAO E RECURSOS HUMANOS' ||
        t == 'ADMINISTRAÇÃO E RECURSOS HUMANOS') {
      return 'SECRETARIA MUNICIPAL DE ADMINISTRAÇÃO E RECURSOS HUMANOS';
    }
    // Genérico: qualquer "X" que exista como "SECRETARIA MUNICIPAL DE X".
    for (final d in departments) {
      final suffix = d
          .replaceFirst('SECRETARIA MUNICIPAL DE ', '')
          .replaceFirst('SECRETARIA MUNICIPAL ', '');
      if (_plain(suffix) == _plain(t)) return d;
    }
    return 'SECRETARIA MUNICIPAL DE $t'.trim();
  }

  /// Remove acentos para comparar "SAUDE" com "SAÚDE".
  static String _plain(String s) => s
      .replaceAll('Á', 'A').replaceAll('À', 'A').replaceAll('Ã', 'A').replaceAll('Â', 'A')
      .replaceAll('É', 'E').replaceAll('Ê', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O').replaceAll('Ô', 'O').replaceAll('Õ', 'O')
      .replaceAll('Ú', 'U').replaceAll('Ü', 'U')
      .replaceAll('Ç', 'C');
}
