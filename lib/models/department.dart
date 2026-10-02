class Department {
  static const String securityDepartment =
      'SECRETARIA MUNICIPAL INTEGRADA DE APOIO À SEGURANÇA PÚBLICA';

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
    securityDepartment,
  ];

  /// Migra somente grafias legadas conhecidas. O valor atual é devolvido
  /// sem alteração para que uma secretaria desconhecida não seja corrompida.
  static String migrateLegacyName(String raw) {
    final t = raw.trim().toUpperCase();
    if (t == 'SECRETARIA MUNICIPAL INTEGRADA DE APOIO À SEGURANÇA' ||
        t == 'SECRETARIA MUNICIPAL INTEGRADA DE APOIO A SEGURANCA PUBLICA' ||
        t == 'INTEGRADA DE APOIO A SEGURANCA PUBLICA' ||
        t == 'INTEGRADA DE APOIO À SEGURANÇA PÚBLICA' ||
        t == 'APOIO À SEGURANÇA PÚBLICA' ||
        t == 'APOIO A SEGURANCA PUBLICA') {
      return securityDepartment;
    }
    return raw;
  }

  /// Órgãos que existem no cadastro mas NÃO são "SECRETARIA MUNICIPAL DE ...".
  ///
  /// O genérico no fim de [canonical] prefixa qualquer valor desconhecido,
  /// o que serve para as secretarias curtas do cadastro ("SAUDE" →
  /// "SECRETARIA MUNICIPAL DE SAÚDE") mas corrompe os órgãos que já têm
  /// nome próprio: "GABINETE DO PREFEITO" virava
  /// "SECRETARIA MUNICIPAL DE GABINETE DO PREFEITO".
  ///
  /// Este é o único não-secretaria no cadastro atual (consultado em
  /// `select distinct secretaria from servidores`, 2026-10): as outras 14
  /// entradas são secretarias e devem ser prefixadas.
  static const _naoSecretarias = {
    'GABINETE DO PREFEITO',
  };

  /// Converte a secretaria vinda do cadastro de servidores (CSV/Supabase,
  /// ex: "ADMINISTRACAO E RECURSOS HUMANOS") para a forma canônica do crachá
  /// (ex: "SECRETARIA MUNICIPAL DE ADMINISTRAÇÃO E RECURSOS HUMANOS").
  ///
  /// Regra: prefixa "SECRETARIA MUNICIPAL" para as secretarias curtas — o
  /// cadastro não carrega o órgão completo e o crachá precisa. Órgãos de
  /// nome próprio (ver [_naoSecretarias]) passam intactos, assim como
  /// qualquer valor já canonical ou desconhecido com prefixo próprio.
  static String canonical(String raw) {
    final t = migrateLegacyName(raw).trim().toUpperCase();
    if (t.isEmpty) return t;
    if (t.startsWith('SECRETARIA MUNICIPAL')) return t;

    // Órgão com nome próprio: já está no formato do crachá.
    if (_naoSecretarias.contains(t)) return t;

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

    // Desconhecido SEM prefixo próprio (ex: "OBRAS, VIACAO E SERVICOS
    // PUBLICOS"): a regra do cadastro manda prefixar.
    if (_temPrefixoProprio(t)) return t;

    return 'SECRETARIA MUNICIPAL DE $t'.trim();
  }

  /// Heurística: o valor já se declara como um órgão nomeado, e não como a
  /// cauda de uma secretaria.
  ///
  /// Cobre órgãos fora de [_naoSecretarias] sem precisar listar todos: o
  /// padrão é "PALAVRA DE ORDEM + resto" (GABINETE DO..., PROCURADORIA
  /// GERAL DE..., TESOURARIA MUNICIPAL, CONTROLADORIA-GERAL...). Já uma
  /// secretaria curta é substantivo puro ("SAUDE", "FAZENDA"), sem verbo de
  /// ligação no começo.
  ///
  /// Só protege contra prefixo *indevido*; os casos conhecidos continuam
  /// cobertos pelas listas acima, que têm precedência.
  static bool _temPrefixoProprio(String t) {
    const marcadores = [
      'GABINETE',
      'PROCURADORIA',
      'CONTROLADORIA',
      'TESOURARIA',
      'AUDITORIA',
      'DIRETORIA',
      'COORDENADORIA',
    ];
    // Casa o início do nome, tolerando hífen/underscore: "CONTROLADORIA-GERAL"
    // e "COORDENADORIA_..." não podem escapar por causa do separador.
    for (final m in marcadores) {
      if (t == m) return true;
      if (t.startsWith(m)) {
        final sep = t[m.length];
        if (sep == ' ' || sep == '-' || sep == '_') return true;
      }
    }
    return false;
  }

  /// Remove acentos para comparar "SAUDE" com "SAÚDE".
  static String _plain(String s) => s
      .replaceAll('Á', 'A')
      .replaceAll('À', 'A')
      .replaceAll('Ã', 'A')
      .replaceAll('Â', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Ê', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ô', 'O')
      .replaceAll('Õ', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll('Ü', 'U')
      .replaceAll('Ç', 'C');
}
