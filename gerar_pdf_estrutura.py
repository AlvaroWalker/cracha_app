#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gera PDF com a explicacao metodica do cracha_app."""
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table,
                                TableStyle, PageBreak, ListFlowable, ListItem, HRFlowable)

OUT = r"D:\401\cracha_app\estrutura-cracha-app.pdf"

styles = getSampleStyleSheet()
h1 = ParagraphStyle("H1", parent=styles["Heading1"], fontSize=18, textColor=colors.HexColor("#0F5A29"), spaceAfter=8)
h2 = ParagraphStyle("H2", parent=styles["Heading2"], fontSize=14, textColor=colors.HexColor("#0F5A29"), spaceBefore=14, spaceAfter=6)
h3 = ParagraphStyle("H3", parent=styles["Heading3"], fontSize=12, textColor=colors.HexColor("#2E7D32"), spaceBefore=10, spaceAfter=4)
body = ParagraphStyle("Body", parent=styles["Normal"], fontSize=10, leading=14, spaceAfter=4)
small = ParagraphStyle("Small", parent=styles["Normal"], fontSize=9, leading=12, textColor=colors.HexColor("#334155"))
cell = ParagraphStyle("Cell", parent=styles["Normal"], fontSize=9, leading=11)
cellH = ParagraphStyle("CellH", parent=styles["Normal"], fontSize=9, leading=11, textColor=colors.white, fontName="Helvetica-Bold")
code = ParagraphStyle("Code", parent=styles["Code"], fontSize=8.5, leading=11, backColor=colors.HexColor("#F1F5F9"), borderPadding=6)

def T(rows, widths=None):
    data = [[Paragraph(f"<b>{c}</b>", cellH) if i == 0 else Paragraph(c, cell) for c in r] for i, r in enumerate(rows)]
    t = Table(data, colWidths=widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0F5A29")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E1")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAF9")]),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    return t

story = []
def add(p): story.append(p)
def p(t): add(Paragraph(t, body))
def s(h=0.3): add(Spacer(1, h * cm))

add(Paragraph("Emissor de Crachas — Campo Verde<br/>Raio-X Completo da Estrutura (do main() ao PDF)", h1))
add(Paragraph("App: cracha_app (Flutter + Material 3 + Provider + Supabase) | Gerado pelo Hermes Agent | Base: codigo real em D:\\401\\cracha_app\\lib", small))
add(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#0F5A29")))
s()
p("<b>TL;DR:</b> boot em <b>lib/main.dart</b> carrega fonte Rawline + Supabase + ThemeNotifier, injeta <b>BadgeManager</b> via Provider e abre <b>AuthGate -&gt; HomePage</b>. Fonte da verdade e a nuvem (tabela <b>crachas</b> + bucket <b>fotos-crachas</b>); SharedPreferences e so cache offline. Edicao propaga por keystroke ate o preview; salvar faz upsert; PDF e screenshot do widget real em 54x85mm.")
s(0.2)
add(T([
    ["Camada", "Onde", "Papel"],
    ["Boot/Tema/Auth", "lib/main.dart, utils/app_theme.dart, services/auth_service.dart", "Fonts, Supabase, LoginView + AuthGate, light/dark"],
    ["Estado/Dados", "models/badge_data.dart, services/badge_manager.dart, services/badge_form_controller.dart", "Entidade, ChangeNotifier global, ponte TextField-&gt;Manager"],
    ["Persistencia", "services/badge_cloud_service.dart, badge_storage_service.dart", "Supabase (upsert/download paralelo) + SharedPreferences (fallback cota)"],
    ["Editor/Preview", "home/home_page.dart + home/widgets/*, views/badge_view.dart", "3 etapas + preview tempo real 333.4x523.19"],
    ["Saidas", "utils/pdf_generator.dart, multi_badge_pdf_generator.dart, views/saved_badges_page.dart", "PDF individual/lote + galeria com filtros"],
], widths=[3.2*cm, 5.5*cm, 8.3*cm]))

add(Paragraph("1. Boot — lib/main.dart", h2))
p("<b>main():</b> ensureInitialized -&gt; usePathUrlStrategy (URL limpa web) -&gt; _loadRawlineFonts (9 pesos via FontLoader) -&gt; Supabase.initialize(url + publishableKey) -&gt; ThemeNotifier.load -&gt; MultiProvider(BadgeManager, ThemeNotifier) -&gt; MyApp.")
p("<b>_loadRawlineFonts():</b> rootBundle.load de cada rawline-W.ttf; try/catch so com debugPrint (falha = fonte fallback, app nao trava).")
p("<b>MyApp:</b> Consumer ThemeNotifier -&gt; MaterialApp(debugBanner off, title 'Campo Verde — Emissor de Crachas', theme light, darkTheme dark, themeMode, home AuthGate(HomePage)).")

add(Paragraph("2. Modelos — lib/models/", h2))
add(T([
    ["Membro de BadgeData", "Comportamento"],
    ["id/name/role/department/photo/createdAt/updatedAt", "Entidade unica. Default department = SECRETARIA MUNICIPAL DE EDUCACAO. photo = Uint8List?"],
    ["_generateUuid()", "UUID v4 manual com Random.secure + mascaras 0x40/0x80. Sem dependencia externa."],
    ["validate() / isValid()", "nome&gt;=3 chars, cargo obrigatorio, secretaria obrigatoria/valida. Retorna List&lt;BadgeValidationError&gt;."],
    ["toMap() / toMapSemFoto()", "base64Encode(photo) vs photo:null. Segundo e plano B quando localStorage estoura cota."],
    ["fromMap()", "base64Decode + UPPER CASE em nome/cargo. Normalizacao agressiva."],
    ["copyWith() / updateTimestamp()", "Clona preservando id/createdAt, novo updatedAt. Chamado a cada save/update."],
], widths=[5.5*cm, 11.5*cm]))
p("<b>Department.departments:</b> lista hardcoded com 16 secretarias — fonte do dropdown de secretaria.")

add(Paragraph("3. Servicos — lib/services/", h2))
add(Paragraph("3.1 auth_service.dart", h3))
add(T([
    ["Funcao/Classe", "O que faz"],
    ["client / isSignedIn", "Atalhos para Supabase.instance.client e currentSession != null."],
    ["signIn / signOut / onAuthStateChange", "signInWithPassword; signOut; stream que o AuthGate escuta."],
    ["LoginView", "Bipartida: brand panel (gradiente verde + brasao) + form card (email/senha, obscure, erro, loading). Desktop=Row, mobile=Column."],
    ["_entrar()", "validate -&gt; loading -&gt; signIn. 'Invalid login' vira 'Email ou senha incorretos'. AuthGate reage sozinho."],
    ["AuthGate", "Checa isSignedIn + listen(stream). Logado mostra child, senao LoginView."],
], widths=[5.5*cm, 11.5*cm]))
add(Paragraph("3.2 badge_manager.dart (ChangeNotifier global)", h3))
add(T([
    ["Funcao", "O que faz"],
    ["initBadges()", "Cria BadgeData() fallback -&gt; tenta fetchBadges() nuvem -&gt; replaceAll local. Em falha: cloudAvailable=false + getBadgeList() local. currentBadge = first ou vazio."],
    ["updateCurrentBadge()", "UPPERCASE nome/cargo + copyWith + notifyListeners = preview rebuilda em tempo real."],
    ["saveCurrentBadge()", "Se cloud: identical(photo, _lastSavedPhoto)? pula upload : sobe foto. Espelha local. Sucesso = nuvem OK (local opcional) ou so local se offline. Em cloudError cai p/ modo local."],
    ["deleteBadge() / deleteSelectedBadges()", "Deleta nuvem (linha + id.jpg do bucket) + local, recarrega lista, re-elege currentBadge."],
    ["Selecao multipla", "Set&lt;String&gt; de IDs: toggle/isSelected/selectAll/clear/selectedBadges p/ PDF em lote e delete em lote."],
    ["createNewBadge() / duplicateBadge()", "Novo vazio / clone com novo ID (nao salva — usuario revisa)."],
], widths=[5.5*cm, 11.5*cm]))
add(Paragraph("3.3 badge_form_controller.dart (ponte TextField-&gt;Manager)", h3))
p("<b>attach(manager):</b> registra listeners nos controllers + no manager. Chamado no HomePage.initState ANTES do primeiro build. <b>_onNameChanged/_onRoleChanged:</b> cada keystroke -&gt; updateCurrentBadge(upper). <b>_onManagerChanged/setFieldsFromBadge:</b> volta (galeria/init) sincroniza controllers sob lock _suprimirListeners (cursor no fim, sem loop). <b>applyServidor(s):</b> autocomplete -&gt; update + setFields. <b>clear():</b> limpa campos no 'Novo'. <b>BadgeFormProvider:</b> InheritedNotifier exposto via of(context).")
add(Paragraph("3.4 Persistencia: nuvem x local", h3))
add(T([
    ["Funcao", "O que faz"],
    ["BadgeCloudService.saveBadge(skipPhotoUpload)", "uploadBinary id.jpg (upsert) + upsert(id,nome,cargo,secretaria,[foto_path],updated_at) em 'crachas'. Skip preserva coluna."],
    ["fetchBadges()", "select order updated_at desc + Future.wait de download(foto_path) em PARALELO. Falha de foto isolada nao derruba linha."],
    ["deleteBadge()", "delete().eq(id) + storage.remove(id.jpg) em try/catch silencioso."],
    ["BadgeStorageService.save/get/replaceAll/delete", "SharedPreferences chave badge_list (StringList JSON). save tenta com foto, em cota cai p/ sem foto. get ordena updatedAt desc."],
], widths=[6*cm, 11*cm]))
add(Paragraph("3.5 Servidores RH + miscelanea", h3))
p("<b>ServidorRepository.searchRemote(q, limit 8):</b> q&lt;2 = []. Tenta rpc('buscar_servidores',{termo,limite}) com unaccent (SQL em assets/data/buscar_servidores.sql); fallback ilike em nome/cargo/secretaria com escape de % e _. Erro = []. Nao carrega os 1472 no boot por decisao. <b>ThemeNotifier:</b> load/setMode/toggle persistindo 'theme_mode' (default dark). <b>RemoveBgService:</b> POST multipart api.remove.bg (key hardcoded, size auto, bg FFFFFF). <b>RetryQueue:</b> fila persistente pending_operations (add/remove/markAttempt max 3/clear) tolerante a JSON corrompido — hoje existe mas o Manager nao enfileira. <b>AuthInterceptor:</b> hasValidSession (expiresAt), handleAuthError (401/jwt/expired -&gt; refreshSession senao forceLogout).")

add(Paragraph("4. Controller de foto — lib/controllers/badge_controller.dart", h2))
p("<b>pickImage(context):</b> SimpleDialog camera/galeria -&gt; pickImage(max 1024, quality 80) -&gt; showPhotoEditDialog -&gt; badgeData.photo = cropped. Cancel = Snackbar 'Recorte cancelado'. Erro no crop = fallback p/ bytes originais + aviso. <b>updateName/Role/Department:</b> setters com UPPER (quase legado, Manager faz hoje).")

add(Paragraph("5. Home + widgets — lib/home/", h2))
p("<b>HomePage:</b> initState faz _form.attach(bm) imediato + postFrame initBadges(). _HomeContent exige BadgeFormProvider. Sem currentBadge = loading. Desktop (&gt;=900): NavigationRail + HeaderNav + DashboardMetrics + Row(Editor flex5 | Preview flex5). Mobile: Drawer + HeaderNav + Column(Metrics, Preview, Editor). Helpers: _openGallery (push + re-sync controllers no retorno), _openTutorial, _confirmLogout, _closeDrawerIfOpen.")
add(T([
    ["Widget", "Papel + funcoes internas"],
    ["app_sidebar", "NavigationRail (desktop) / NavigationDrawer (mobile). Badge(count), status nuvem success/warning, callbacks emissor/galeria/tutorial/logout/tema."],
    ["header_nav", "Command bar 56px. _saveCurrent (validate-&gt;save-&gt;Snackbar), _newBadge (create+clear), _openGallery, _confirmLogout. Botao galeria com Badge(count)."],
    ["dashboard_metrics", "total / comFoto / secretarias distintas / recentes 7d. Wrap 2 ou 4 cards via LayoutBuilder."],
    ["editor_panel", "3 etapas: 1 Foto(EditorPhotoCard) 2 Servidor(EditorServidorField) 3 Secretaria(EditorSecretariaField) + banner dica."],
    ["editor_photo_card", "_pickPhoto (BadgeController+update) / _removerFundo (dialog loading + RemoveBg + Snackbar). Thumb 84px com borda ativa."],
    ["editor_servidor_field", "ServidorAutocompleteField + AppTextField cargo. onServidorSelecionado -&gt; update + setFields."],
    ["editor_secretaria_field", "SearchableDropdownField(items=Department.departments, onChanged-&gt;update)."],
    ["preview_panel", "Badge 'PRE-VISUALIZACAO EM TEMPO REAL' + FittedBox(BadgeView key=globalKey) + botao PDF -&gt; PdfGenerator. _onImageTap reusa pickImage."],
], widths=[4*cm, 13*cm]))

add(Paragraph("6. Views — lib/views/", h2))
add(T([
    ["Arquivo", "Funcoes"],
    ["badge_view 333.4x523.19", "Stack: CRACHA.png + foto 153x189 top175 (memory ou placeholder) + card branco bottom17 280x135 (nome/role AutoSize 2 linhas + Divider + secretaria). Taps + repaintBoundaryKey p/ PDF."],
    ["servidor_autocomplete", "_onChanged debounce 200ms -&gt; searchRemote(8) -&gt; overlay CompositedTransformFollower (contador, hints, highlight multi-termo). Teclado setas/Enter/Esc, hover, _selecionar(suprime listener, seta texto, callback, unfocus)."],
    ["photo_edit_dialog", "ImageAdjustments (matriz preview + pixel-a-pixel final, brilho/contraste/saturacao -100..100, auto 8/12/6). CropImage 3/4, rotacao 90 + fina -45..45 c/ debounce 120ms+cache, _aplicarRecorte(croppedBitmap-&gt;ajustes-&gt;PNG-&gt;pop)."],
    ["saved_badges_page", "Busca debounce 250ms + SavedBadgesFilter.apply + chips ordenacao/periodo/secretarias + bottom sheet. Grid maxCross 300. Card: foto/nome/cargo/secretaria/updatedAt, tap edita, long-press seleciona, menu edit/duplicate/delete. Barra flutuante: count + PDF Lote + Excluir."],
    ["saved_badges_filter", "apply(search+secretaria+ordenacao+periodo) puro sem mutar entrada + secretariasComContagem ordenado. Unit-testavel."],
    ["design system", "app_button (primary/secondary/danger/text/icon), app_card, app_text_field (prefix/suffix), app_banner_dica, tutorial_view (5 secoes animadas)."],
], widths=[4*cm, 13*cm]))

add(Paragraph("7. Utils — PDF, tema, tokens", h2))
add(T([
    ["Arquivo", "Funcoes"],
    ["pdf_generator", "Dialog progresso 0.2/0.4/0.6/0.8/1.0; espera RepaintBoundary 20x100ms; toImage(3.0)-&gt;PNG-&gt;pw.Page 54x85mm Center contain-&gt;save; filename sanitizado 'NOME - SECRETARIA.pdf'; Printing.sharePdf; erro = AlertDialog com detalhes."],
    ["multi_badge_pdf", "generateMultipleBadgesPdf: 1 pw.Page por badge. _captureBadgeAsImage injeta BadgeView REAL em OverlayEntry off-screen (+1000px) via _BadgeCaptureWidget (reload fonts + 3 frames + toImage 3.0). Arquivo 'crachas_N.pdf'. Garante lote identico ao individual."],
    ["app_theme/colors/tokens/text", "light/dark Material3 completos (Rawline em tudo); primary light 0F5A29 / dark 3FA562; Spacing 4-48, Radius 8-full, Breakpoints 600/900; name 22w700, role/dept 15w700."],
    ["snackbar/animations", "showSuccess/Error/Info; animatedListItem (fade+slide por indice)."],
], widths=[4*cm, 13*cm]))

add(Paragraph("8. Fluxo end-to-end + pros/contras", h2))
p("1) Digita nome -&gt; _onNameChanged -&gt; updateCurrentBadge -&gt; Preview rebuilda. 2) Escolhe servidor -&gt; applyServidor preenche cargo+secretaria (editaveis depois). 3) Foto -&gt; pick -&gt; crop/ajustes -&gt; update(photo) -&gt; opcional remove.bg. 4) Secretaria -&gt; dropdown -&gt; update. 5) Salvar (HeaderNav valida -&gt; saveCurrentBadge nuvem+local). 6) Galeria (busca/filtros/selecao) -&gt; editar/duplicar/excluir/PDF lote. 7) PDF individual = screenshot do BadgeView; lote = mesmo widget renderizado off-screen, pagina por cracha.")
s(0.2)
add(T([
    ["Ponto", "Pro", "Contra"],
    ["Nuvem-first + fallback", "Funciona offline", "Duas fontes podem divergir; RetryQueue ociosa"],
    ["Foto Uint8List+base64", "Preview instantaneo", "Cota ~5MB: fallback sem foto joga imagem fora"],
    ["PDF via screenshot", "Lote identico ao individual", "pixelRatio 3 + overlay off-screen fragil; fonte recarregada na mao"],
    ["Autocomplete limit 8", "Boot leve (nao puxa 1472)", "1 request por tecla (debounce ajuda); sem cache"],
    ["remove.bg hardcoded", "1 linha e funciona", "Key exposta + custo por chamada (ok p/ uso interno)"],
], widths=[3.5*cm, 6.5*cm, 7*cm]))

doc = SimpleDocTemplate(OUT, pagesize=A4, topMargin=1.5*cm, bottomMargin=1.5*cm, leftMargin=1.5*cm, rightMargin=1.5*cm, title="Cracha App - Raio-X da Estrutura", author="Hermes Agent")
doc.build(story)
print(f"OK -> {OUT}")
