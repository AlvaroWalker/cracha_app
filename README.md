# 🌿 Campo Verde — Emissor Digital de Crachás

[![Flutter](https://img.shields.io/badge/Flutter-^3.6.1-02569B?logo=flutter&logoColor=white&style=for-the-badge)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-^3.0.0-0175C2?logo=dart&logoColor=white&style=for-the-badge)](https://dart.dev)
[![Cloudflare Pages](https://img.shields.io/badge/Cloudflare_Pages-Deploy_Direct-F38020?logo=cloudflare&logoColor=white&style=for-the-badge)](https://pages.cloudflare.com)
[![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)](#)

O **Campo Verde — Emissor Digital de Crachás** é uma aplicação web e mobile premium construída em Flutter para simplificar a criação, o gerenciamento, a exportação em lote e a impressão de identificações funcionais (crachás) de servidores e colaboradores.

Com uma interface moderna inspirada no Material 3, o sistema conta com fluxos intuitivos de edição em tempo real, recorte inteligente de fotos e persistência de dados local segura.

---

## ✨ Principais Funcionalidades

- 📱 **Interface Fluida e Responsiva**: Totalmente otimizada para desktops e dispositivos móveis, adaptando-se perfeitamente a diferentes tamanhos de tela.
- ⚡ **Edição em Tempo Real**: Atualizações dinâmicas na pré-visualização do crachá funcional à medida que o usuário edita o nome, o cargo e a secretaria (departamento).
- ✂️ **Recorte de Imagem Avançado**: Carregue imagens e utilize o pacote `crop_image` para ajustar a foto frontal no enquadramento oficial.
- 📂 **Gerenciador de Crachás Salvos (Galeria)**:
  - Persistência local segura utilizando o `shared_preferences` para evitar perdas acidentais de dados.
  - Visualização de crachás gerados anteriormente.
  - Busca, edição, remoção rápida e duplicação.
- 🖨️ **Geração e Impressão de PDFs (Pacote `pdf` & `printing`)**:
  - **Impressão Individual**: Emissão imediata do crachá selecionado no formato padrão da prefeitura.
  - **Impressão em Lote (Bulk Export)**: Seleção múltipla de crachás no painel de salvos e exportação unificada em um único arquivo PDF altamente otimizado para impressão em folha A4.
- 🎨 **Estilo Municipal Premium**: Tipografia customizada utilizando a fonte `Rawline` e paleta de cores institucional verde e dourada do município.

---

## 📂 Estrutura do Código

O projeto está estruturado seguindo as melhores práticas de modularização em Flutter:

```text
lib/
├── main.dart                 # Ponto de entrada e configuração do app (MaterialApp & Providers)
├── controllers/
│   └── badge_controller.dart # Regras de captura e corte de imagem
├── models/
│   ├── badge_data.dart       # Entidade que define os atributos do crachá
│   └── department.dart       # Lista oficial de secretarias e departamentos
├── services/
│   ├── badge_manager.dart    # Estado global de crachás ativos e lista (SharedPreferences)
│   └── badge_storage_service.dart # Abstração de persistência em disco/browser
├── utils/
│   ├── app_animations.dart   # Definições de animações de transição
│   ├── app_colors.dart       # Tokens de cores (Design System do Campo Verde)
│   ├── text_styles.dart      # Estilos tipográficos oficiais da fonte Rawline
│   ├── pdf_generator.dart    # Motor de renderização PDF para crachá individual
│   └── multi_badge_pdf_generator.dart # Motor de exportação PDF consolidado para lote
└── views/
    ├── badge_view.dart       # O widget visual do crachá (frente/verso)
    ├── saved_badges_page.dart # Painel da galeria e operações em lote
    └── tutorial_view.dart    # Guia introdutório de ajuda ao usuário
```

---

## 🚀 Como Executar Localmente

### Pré-requisitos

Certifique-se de possuir o [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado em sua máquina na versão **3.6.1 ou superior**.

### Passos para Inicialização

1. **Clonar o Repositório:**
   ```bash
   git clone <URL_DO_REPOSITORIO>
   cd cracha_app
   ```

2. **Obter as Dependências:**
   ```bash
   flutter pub get
   ```

3. **Executar em Modo de Desenvolvimento (Web / Chrome):**
   ```bash
   flutter run -d chrome
   ```

4. **Gerar Build de Produção para Web:**
   ```bash
   flutter build web --release
   ```
   > [!NOTE]
   > Em versões modernas do Flutter (a partir da 3.29, incluindo a sua 3.41), a opção `--web-renderer` foi descontinuada e removida. O Flutter agora compila para renderização WebGL nativa de alta fidelidade (CanvasKit) por padrão. Caso queira experimentar a nova compilação em WebAssembly (Wasm) para o máximo desempenho, utilize `flutter build web --release --wasm`.

---

## ☁️ Como Subir no Cloudflare Pages

O **Cloudflare Pages** é a melhor plataforma para hospedar o frontend do seu gerador de crachás por possuir CDN global ultrarrápido, suporte a SSL automático gratuito e redirecionamentos configuráveis para SPAs.

Como o ambiente de compilação automática da Cloudflare não possui o Flutter SDK pré-instalado por padrão, a melhor estratégia é compilar o projeto em sua máquina local e subir o resultado para a Cloudflare. 

Temos **três abordagens excelentes** para realizar o deploy:

---

### 📂 Método A: Upload Manual via Dashboard (Drag & Drop — O Mais Simples!)

Esta é a forma mais rápida e visual de colocar o seu app no ar, ideal para o método de arrastar e soltar da Cloudflare.

1. **Compilar a versão Web de produção localmente (com Wasm):**
   ```powershell
   flutter build web --release --wasm
   ```
   *(Isso criará a pasta com os arquivos otimizados e prontos em `build/web`)*

2. **Localizar a pasta de build:**
   Abra o explorador de arquivos no seu computador e navegue até a raiz do seu projeto. A pasta a ser enviada é:
   `d:\401\cracha_app\build\web`

3. **Fazer o upload no painel do Cloudflare Pages:**
   - Faça login no painel da [Cloudflare](https://dash.cloudflare.com).
   - No menu lateral esquerdo, clique em **Workers & Pages**.
   - Clique no botão **Create** (ou *Create Application*) e selecione a aba **Pages**.
   - Clique na opção **Upload assets** (Fazer upload de arquivos estáticos).
   - Insira um nome para o seu projeto (ex: `cracha-campo-verde`).
   - Arraste a pasta inteira **`web`** (localizada dentro de `build/`) e solte na área pontilhada do navegador (ou clique para selecionar a pasta `build/web` do seu projeto).
   - Clique em **Deploy site** (ou *Publish*).

4. 🎉 **Pronto!** A Cloudflare Pages processará o upload em segundos e te dará um domínio gratuito (ex: `https://cracha-campo-verde.pages.dev`). A regra de SPA do arquivo `_redirects` já será carregada automaticamente!

---

### 🛡️ Método B: Deploy Direto via Wrangler CLI (Sem abrir o navegador para upload)

Se preferir usar o terminal sem precisar arrastar pastas manualmente:

1. **Compilar a versão Web localmente:**
   ```powershell
   flutter build web --release --wasm
   ```

2. **Subir com Wrangler (CLI da Cloudflare):**
   ```powershell
   npx wrangler pages deploy build/web
   ```

3. **Seguir os passos no terminal:**
   - Faça login no navegador quando solicitado.
   - Escolha o nome do projeto e confirme a branch padrão.

---

### 🤖 Método B: Integração Contínua (CI/CD) via GitHub Actions (Profissional)

Se o seu repositório está no GitHub e você deseja que o deploy ocorra **automaticamente a cada `git push`** para a branch principal, configure uma Pipeline de CI/CD:

1. **Criar o arquivo do Workflow no projeto:**
   Crie as pastas `.github/workflows/` se não existirem, e salve o arquivo com o nome `deploy.yml`:
   `[ROOT]/.github/workflows/deploy.yml`

2. **Colar a seguinte configuração de pipeline:**
   ```yaml
   name: Deploy Flutter Web to Cloudflare Pages

   on:
     push:
       branches:
         - main  # Altere para master ou sua branch principal se necessário

   jobs:
     build-and-deploy:
       runs-on: ubuntu-latest

       steps:
         # 1. Copiar os arquivos do repositório
         - name: Checkout Repository
           uses: actions/checkout@v4

         # 2. Configurar o ambiente Java (requerido por algumas dependências do SDK)
         - name: Setup Java JDK
           uses: actions/setup-java@v3
           with:
             distribution: 'zulu'
             java-version: '17'

         # 3. Instalar o Flutter SDK
         - name: Setup Flutter
           uses: subosito/flutter-action@v2
           with:
             flutter-version: '3.41.x' # Versão estável instalada no seu ambiente
             channel: 'stable'
             cache: true

         # 4. Baixar as dependências do Dart/Flutter
         - name: Install Dependencies
           run: flutter pub get

         # 5. Compilar o aplicativo para Flutter Web
         - name: Build Web App
           run: flutter build web --release

         # 6. Publicar a pasta build/web no Cloudflare Pages
         - name: Deploy to Cloudflare Pages
           uses: cloudflare/pages-action@v1
           with:
             apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
             accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
             projectName: 'cracha-campo-verde' # Nome do seu projeto na Cloudflare
             directory: 'build/web'
             gitHubToken: ${{ secrets.GITHUB_TOKEN }}
   ```

3. **Configurar as Variáveis Secretas no Repositório do GitHub:**
   No seu repositório no GitHub, vá em **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret** e adicione:
   - `CLOUDFLARE_API_TOKEN`: Seu Token de API gerado na Cloudflare (vá ao seu perfil na Cloudflare -> API Tokens -> Create Token -> Usar o template "Edit Cloudflare Pages").
   - `CLOUDFLARE_ACCOUNT_ID`: Sua ID da conta Cloudflare (disponível na barra lateral direita do seu Painel Geral da Cloudflare).

4. **Enviar para o GitHub:**
   ```bash
   git add .
   git commit -m "ci: adiciona pipeline de deploy automático no Cloudflare Pages"
   git push origin main
   ```
   Agora, a cada atualização de código enviada à branch `main`, o GitHub Actions irá buildar e atualizar o seu site no Cloudflare Pages automaticamente!

---

### 🌐 Roteamento SPA (URLs amigáveis sem o #)

Este aplicativo utiliza a estratégia de URL de caminho limpo (`usePathUrlStrategy()`) na linha 14 do `main.dart`. Isso remove o `#` feio das URLs do navegador (ex: transformando `site.com/#/saved` em `site.com/saved`).

Para que rotas diretas digitadas na barra de endereços não retornem erro **404 (Not Found)** da hospedagem, o Cloudflare Pages requer uma regra de redirecionamento para Single Page Applications (SPA).

> [!TIP]
> **Já está tudo configurado!**
> Nós incluímos o arquivo `_redirects` dentro da pasta `web/` com o seguinte conteúdo:
> ```text
> /*    /index.html   200
> ```
> O Flutter copia esse arquivo automaticamente para a pasta `build/web/` no momento da compilação. O Cloudflare Pages lê esse arquivo e redireciona qualquer requisição interna para o `index.html` mantendo a resposta HTTP 200, garantindo o funcionamento perfeito do roteamento do Flutter.

