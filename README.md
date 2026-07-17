# YouTube Music & Video Downloader

Um aplicativo móvel desenvolvido em Flutter para Android que permite pesquisar, reproduzir (online e offline) e baixar áudios e vídeos diretamente do YouTube com alta performance, suporte a playlists e integração profunda com o sistema Android.

---

## 📱 Principais Funcionalidades

### 1. Busca e Exploração Organizada
* **Abas de Busca Dedicadas**: Divisão entre **Vídeos** e **Playlists** para facilitar a localização de mídias individuais ou álbuns completos.
* **Carregamento Infinito**: Scroll infinito e paginação rápida utilizando a API pública do YouTube.
* **Redirecionamento Inteligente**: Tocar em um vídeo abre o player multimídia; tocar em uma playlist abre seus detalhes com a lista de faixas.

### 2. Motor de Downloads de Alta Performance
* **Baseado no yt-dlp**: Downloads estáveis, rápidos e confiáveis integrando a biblioteca `extractor`.
* **Qualidade Inteligente com Fallback**: Seleção flexível de qualidades de vídeo (1080p, 720p, 480p, etc.) e áudio (320kbps, 192kbps, etc.) com fallback automático para a qualidade mais próxima imediatamente inferior.
* **Download em Lote (Batch)**: Interface exclusiva para colar múltiplos links de uma vez, analisar metadados em lote e enfileirar os downloads simultaneamente.
* **Capa Embutida (Artwork)**: Incorporação automática de metadados e da miniatura (thumbnail) como arte de capa em arquivos de música (MP3/M4A).
* **Prevenção de Falhas**: Conversão automática de URLs do YouTube Music (`music.youtube.com` -> `youtube.com`).

### 3. Integração Profunda com Android
* **Notificações de Progresso**: Exibição contínua do status de download na bandeja do Android com barra de progresso em tempo real e botão interativo para cancelar.
* **Resiliência de Fila (Startup Recovery)**: Se o app for encerrado ou reiniciado inesperadamente, os downloads interrompidos voltam ao estado `pendente` e são retomados de forma automática na inicialização seguinte.
* **Media Scanner Nativo**: Chamada integrada ao `MediaScannerConnection` nativo do Android após a conclusão de cada download, garantindo que as mídias apareçam imediatamente na Galeria, Google Fotos, VLC e reprodutores de música do sistema.

### 4. Player de Mídia Integrado (Online & Offline)
* **Modo Online**: Transmissão direta por streaming do YouTube usando `youtube_player_flutter` para vídeos ou reprodução otimizada de áudio.
* **Modo Offline**: Carregamento automático de arquivos locais salvos em disco (`chewie` para vídeo e `just_audio` para áudio) ao abrir mídias já baixadas.
* **Controles Avançados de Fila**: Botão flutuante para abrir o painel de fila deslizante (gaveta de reprodução), controle de autoplay (avançar automaticamente) e botões de pular/voltar faixa.
* **Navegação Contínua**: Seção de "Vídeos Relacionados" integrada abaixo do player permitindo a navegação infinita em modo online.

### 5. Configurações e Ajustes Fáceis
* **Suporte a Cookies**: Importação fácil do arquivo `cookies.txt` (formato Netscape) para burlar restrições de idade, bloqueios regionais e limites de requisição do YouTube.
* **Caminhos Customizados**: Configuração do diretório raiz e alertas visuais inteligentes caso o usuário tente salvar mídias em pastas que já existem.

---

## 🛠️ Stack Tecnológica

* **Core**: Flutter & Dart (SDK 3.x)
* **Gerenciamento de Estado**: `flutter_riverpod` (Providers, StateNotifiers e AsyncNotifiers)
* **Roteamento**: `go_router` (Navegação declarativa com suporte a parâmetros complexos)
* **Persistência de Dados**: `isar` (Banco de dados NoSQL rápido e reativo para histórico e fila)
* **Motor de Downloads**: `extractor` (yt-dlp)
* **Reprodutores de Mídia**: `just_audio` (áudio) e `video_player` / `chewie` (vídeo local) / `youtube_player_flutter` (vídeo online)

---

## 📁 Estrutura de Pastas (Clean Architecture adaptada)

A arquitetura do projeto está organizada por **features** de forma modular e escalável:

```text
lib/
├── core/                         # Infraestrutura compartilhada
│   ├── database/                 # Serviço de banco de dados Isar
│   ├── notification/             # Sincronização de notificações locais
│   ├── router/                   # Rotas GoRouter e transições de tela
│   ├── theme/                    # Design System (paleta deep-dark e fontes)
│   └── utils/                    # Utilitários compartilhados (Helper de URLs, Media Scanner, etc.)
└── features/                     # Módulos funcionais
    ├── explore/                  # Busca, paginação e visualização em abas
    ├── download_setup/           # Configuração de download de mídias e playlists
    ├── downloader_engine/        # Motor yt-dlp e processamento concorrente da fila
    ├── downloads_history/        # Histórico de concluídos, ativos e gerenciamento local
    ├── media_player/             # Reprodutor completo de áudio/vídeo online e offline
    └── settings/                 # Ajustes de cookies e diretórios padrão
```

---

## 🚀 Como Executar o Projeto

1. **Pré-requisitos**:
   * Flutter SDK instalado.
   * Dispositivo Android conectado ou emulador configurado.

2. **Obter dependências**:
   ```bash
   flutter pub get
   ```

3. **Gerar arquivos de código (Isar Models)**:
   Como o Isar usa geração de código, execute o build runner:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Executar o app**:
   ```bash
   flutter run
   ```

---

## 📄 Licença

Este projeto é desenvolvido para uso privado de ferramentas de mídia e download pessoal.
