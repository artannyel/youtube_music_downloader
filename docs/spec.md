# Especificação Técnica (Spec) - Downloader de Música e Vídeo do YouTube

Esta especificação define o comportamento, a arquitetura e as regras de negócio para a aplicação Android de download do YouTube, seguindo o desenvolvimento guiado por especificações (Spec Driven Development - SDD).

---

## 1. Visão Geral
O aplicativo permitirá que usuários explorem o YouTube, insiram URLs de vídeos, músicas ou playlists do YouTube, configurem detalhes do download (formato, qualidade e subpastas), monitorem os downloads ativos com progresso em tempo real (tanto na interface do app quanto nas notificações do sistema Android) e acessem o histórico de mídias baixadas.

---

## 2. Tecnologias & Dependências

O aplicativo será construído com as seguintes dependências:

| Pacote | Versão recomendada | Finalidade |
| :--- | :--- | :--- |
| `flutter_riverpod` | `^2.5.1` | Gerenciamento de estado (Providers, Notifier). |
| `go_router` | `^14.2.0` | Roteamento declarativo de telas. |
| `youtube_explode_dart` | `^2.2.2` | Busca e exploração de metadados de vídeos do YouTube. |
| `extractor` | `^1.0.0` | Mecanismo principal de download baseado em `yt-dlp`. |
| `isar` | `^3.1.0` | Banco de dados local para persistência de downloads e histórico. |
| `isar_generator` | `^3.1.0` | Gerador de código para o banco de dados Isar. |
| `flutter_local_notifications` | `^17.1.2` | Exibição de progresso e botões interativos na bandeja de notificações. |
| `path_provider` | `^2.1.3` | Localização e criação de diretórios de Download. |
| `permission_handler` | `^11.3.1` | Solicitação de permissões (Armazenamento, Notificações). |
| `shared_preferences` | `^2.2.3` | Persistência de configurações leves (cookies path, etc). |
| `file_picker` | `^8.0.0` | Seleção do arquivo `cookies.txt`. |
| `youtube_player_flutter` | `^9.1.1` | Reprodução online de vídeos do YouTube. |
| `just_audio` | `^0.9.38` | Reprodução de áudio online/offline com suporte a metadados. |
| `video_player` | `^2.8.2` | Reprodução de vídeos baixados localmente. |
| `chewie` | `^1.8.0` | Controladores de vídeo responsivos e customizados para o Player local. |

---

## 3. Arquitetura e Estrutura de Pastas

A estrutura segue o padrão de **feature -> data, domain, presentation** com injeção de dependências controlada via Riverpod.

```text
lib/
├── core/                         # Infraestrutura compartilhada
│   ├── database/                 # Configuração do Isar Database (IsarService)
│   ├── notification/             # Serviço de Notificações do Android (NotificationService)
│   ├── router/                   # Configuração e definição de rotas do GoRouter
│   └── theme/                    # Tema visual moderno e tokens de design (Dark/Clean)
└── features/

---

## 3.1. Cores Padrão (Design Tokens)
O aplicativo utilizará uma paleta de cores moderna e clean no modo escuro (Dark Mode por padrão):
- **Primary (Primária)**: `#FF0000` (Destaques, botões principais e elementos de ação de alta prioridade)
- **Secondary (Secundária)**: `#38BDF8` (Chips de formato, links, botões alternativos e ações secundárias)
- **Tertiary (Terciária)**: `#22C55E` (Downloads concluídos, ícones de sucesso e confirmações de ação)
- **Neutral (Neutra)**: `#94A3B8` (Textos de suporte, placeholders, bordas e elementos desativados)

---
    ├── explore/                  # Busca de vídeos no YouTube
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── download_setup/           # Configuração de download (formatos, qualidades, conversão de URL)
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── downloader_engine/        # Mecanismo do Extractor e fila de downloads
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── downloads_history/        # Histórico local do Isar & interface de downloads
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── media_player/             # Reprodução de vídeo e música online/offline
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── settings/                 # Tela de ajustes (Cookies, Caminhos padrão)
        ├── data/
        ├── domain/
        └── presentation/
```

---

## 4. Regras de Negócio e Funcionalidades

### R1. Local de Armazenamento
- Os caminhos de salvamento serão:
  - Vídeos: `<ArmazenamentoExterno>/Download/videos`
  - Músicas: `<ArmazenamentoExterno>/Download/musicas`
- Se for especificada uma subpasta personalizada pelo usuário (Ex: `variados`), os caminhos serão:
  - Vídeos: `<ArmazenamentoExterno>/Download/videos/variados`
  - Músicas: `<ArmazenamentoExterno>/Download/musicas/variados`
- Para downloads de **playlists**, o campo da subpasta personalizada deve ser pré-preenchido com o nome da playlist.
- **Validação de Pasta Existente**: Caso o usuário forneça o nome de uma pasta que já existe, o app exibirá uma mensagem/toast:
  - *"A pasta '[nome]' já existe. Novos arquivos de mídia serão adicionados a ela."*

### R2. Conversão de URLs do YouTube Music
- Toda URL que vier de `music.youtube.com` deverá ser reescrita para `youtube.com` para evitar falhas no mecanismo de download.
- Regra de parsing: `url.replaceAll('music.youtube.com', 'youtube.com')`

### R3. Qualidade de Mídia e Algoritmo de Fallback
- No download de vídeo, o usuário escolhe a resolução (`1080p`, `720p`, `480p`, etc.). No áudio, o bitrate (`320kbps`, `192kbps`, `128kbps`, etc.).
- **Algoritmo de Fallback**: Caso um vídeo de uma playlist não tenha a qualidade selecionada (Ex: selecionado `1080p`, mas o vídeo só tem `720p` disponível), o sistema deve automaticamente buscar e baixar na qualidade mais próxima disponível imediatamente inferior.

### R4. Notificações do Sistema Android
- Os downloads ativos exibirão progresso contínuo na bandeja de notificações.
- As notificações exibirão:
  - Título do vídeo.
  - Barra de progresso atualizada dinamicamente.
  - **Ação Interativa**: Botão para "Cancelar" (ou "Pausar" se suportado pelo mecanismo) diretamente na notificação.

### R5. Configuração de Cookies para Vídeos Restritos
- O app terá uma configuração para importar um arquivo `cookies.txt` (formato Netscape) para burlar restrições de idade e bloqueios do YouTube.
- O caminho do arquivo será salvo no `SharedPreferences` para persistência de longo prazo.
- Durante o download, se configurado, o caminho do arquivo de cookies será passado para o cliente `extractor`.

### R6. Incorporação de Thumbnail em Músicas (Metadados)
- Ao realizar o download de um arquivo no formato de **Música (Áudio)**, o aplicativo deve embutir automaticamente a miniatura (thumbnail) do vídeo como arte de capa (album art/artwork) no arquivo final (MP3/M4A).
- O motor de download (`extractor`) utilizará a flag de metadados correspondente do `yt-dlp` (`--embed-thumbnail` ou similar) em conjunto com o `FFmpeg` para realizar a injeção da capa diretamente na faixa de áudio após a conclusão da extração.

### R7. Tela de Player & Detalhes Integrada (Online & Offline)
- **Acesso**: Ao clicar em um vídeo na Home (Explore) ou em um item de histórico de download.
- **Modo Online**: Utiliza `youtube_player_flutter` para fazer o stream do vídeo diretamente do YouTube (ou apenas áudio via `just_audio`). Exibe metadados, descrição, seção de **Vídeos Relacionados** e o botão destacado para "Configurar Download".
- **Modo Offline**: Se a mídia já foi baixada, ao abrir a tela, o player carrega o arquivo local de mídia (`chewie`/`video_player` para vídeo ou `just_audio` para áudio) ao invés do stream do YouTube.
- **Controles**: Barra de progresso, Play/Pause, retroceder/avançar, controle de velocidade e suporte a reprodução de áudio em segundo plano.
- **Navegação de Fila e Controles Globais**:
  - Quando iniciado a partir de uma Playlist ou Lote de links, o player habilita os botões de **Próximo** e **Anterior**.
  - **Autoplay**: Transita de forma automática e transparente para o próximo item da fila ao término da mídia atual.
  - **Painel de Fila (Queue Panel)**: Botão flutuante que abre uma gaveta deslizante (bottom sheet ou drawer) com a lista de faixas da fila atual, permitindo seleção direta.
- **Vídeos Relacionados (Navegação Infinita)**:
  - Exibe uma lista de vídeos relacionados abaixo do player (obtidos do YouTube).
  - Tocar em um relacionado altera a mídia atual do player para reproduzir o novo vídeo online e atualiza a lista de relacionados para permitir navegação contínua.

### R8. Tela de Playlist e Lote (Batch/Multi-Links)
- **Acesso**: Ao colar a URL de uma playlist ou um conjunto de links separados por quebra de linha.
- **Layout**: Exibe metadados da playlist (nome, autor, contagem de mídias) e a lista dos vídeos identificados.
- **Interação**:
  - Tocar em qualquer vídeo da lista inicializa a **Tela de Player & Detalhes** com a lista inteira carregada como a **Fila de Reprodução** ativa, tocando o vídeo selecionado e configurando o comportamento de autoplay.
  - Disponibiliza um botão de ação rápida "Baixar Tudo" que abre a folha de opções de download para todos os itens.
  - Para lote (múltiplos links colados manualmente), funciona como uma lista temporária personalizável.

### R9. Abas de Busca no Explore (Vídeos e Playlists)
- Ao realizar uma pesquisa textual na aba "Explorar", o aplicativo deve disponibilizar duas abas de resultados:
  - **Vídeos**: Exibe resultados filtrados do tipo vídeo (`TypeFilters.video`). Selecionar um vídeo carrega a tela do Player em modo online.
  - **Playlists**: Exibe resultados filtrados do tipo playlist (`TypeFilters.playlist`). Selecionar uma playlist redireciona o usuário para a tela de listagem de playlist correspondente.

---

## 5. Estrutura dos Modelos Isar

### `DownloadTask` (Coleção Isar)
Representa um item na fila de downloads ou histórico.

```dart
import 'package:isar/isar.dart';

part 'download_task.g.dart';

@collection
class DownloadTask {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String youtubeId;
  
  late String title;
  late String url;
  
  @Enumerated(EnumType.name)
  late DownloadType type; // 'video' ou 'audio'
  
  late String requestedQuality;
  late String actualQuality;
  late String targetPath;
  
  late double progress; // 0.0 a 100.0
  late String downloadSpeed;
  late String eta;
  
  @Enumerated(EnumType.name)
  late DownloadStatus status; // 'pending', 'downloading', 'completed', 'failed', 'paused'
  
  String? errorMessage;
  late DateTime createdAt;
}

enum DownloadType { video, audio }
enum DownloadStatus { pending, downloading, completed, failed, paused }
```
