// ═══════════════════════════════════════════════════════════════════════════
// ALIAS DO BADGEVIEW.
//
// O crachá passou a ser desenhado por `CrachaPainter` (ver
// `badge_view_canvas.dart`), que delega o texto ao `CrachaLayout` — o mesmo
// cálculo usado pelo PDF vetorial. Antes, o widget era montado com `Column`
// + `AutoSizeText` em `badge_design.dart`.
//
// Por que o alias existe: `BadgeView` e `buildBadgeStage` são importados em
// vários lugares. Redirectar a saída do arquivo mantém todos esses imports
// funcionando sem tocar em cada um.
//
// `BadgeGeometry` e `BadgeTextStyles` continuam vindo de `badge_design.dart`
// porque os geradores vetoriais antigos (`pdf_vector_generator`,
// `multi_badge_pdf_generator`) ainda dependem dessas constantes — e eles
// permanecem no repositório como caminho alternativo.
// ═══════════════════════════════════════════════════════════════════════════
export 'badge_view_canvas.dart';
export 'badge_design.dart' show BadgeGeometry, BadgeTextStyles;