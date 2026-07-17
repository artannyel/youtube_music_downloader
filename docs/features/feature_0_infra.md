# Plano de Feature - Infraestrutura e Configuração Inicial

Este documento detalha o plano de desenvolvimento e as subtarefas para configurar a infraestrutura de base do aplicativo.

---

## 🔍 Referências de Documentação
- **Especificação Principal**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md) (Seções: *2. Tecnologias*, *3. Arquitetura*, *5. Modelos Isar*)

---

## 🎯 Objetivo
Configurar o ambiente de desenvolvimento, habilitar permissões de sistema necessárias no Android, preparar a arquitetura de pastas, implementar o sistema de rotas (GoRouter) e inicializar a persistência local (Isar).

---

## 📈 Plano de Desenvolvimento

1. **Configuração de Pacotes**:
   - Ajustar o arquivo `pubspec.yaml` para incluir as dependências essenciais do projeto e gerar as versões necessárias dos pacotes de geração (Isar, Riverpod).
2. **Definição de Permissões Nativas**:
   - Inserir as diretivas no manifesto Android para permitir acessos à internet, gravação em armazenamento e notificações do sistema.
3. **Criação do Design System**:
   - Definir o arquivo de tema (`core/theme/theme.dart`) com estilos escuros, modernos e limpos.
4. **Infraestrutura de Rotas**:
   - Implementar o roteador declarativo GoRouter com suporte a sub-rotas e passagem de argumentos para a tela de download.
5. **Configuração do Banco Isar**:
   - Criar uma classe gerenciadora `IsarService` que inicializa o banco de dados Isar na inicialização da aplicação (`main.dart`).

---

## 📋 Lista de Tarefas (Subtasks)

- [x] **T0.1. Ajuste do pubspec.yaml**
  - Adicionar as seguintes dependências em `dependencies`:
    - `flutter_riverpod: ^2.5.1`
    - `go_router: ^14.2.0`
    - `youtube_explode_dart: ^2.2.2`
    - `extractor: ^1.0.0`
    - `isar: ^3.1.0`
    - `isar_flutter_libs: ^3.1.0`
    - `flutter_local_notifications: ^17.1.2`
    - `path_provider: ^2.1.3`
    - `permission_handler: ^11.3.1`
    - `shared_preferences: ^2.2.3`
    - `file_picker: ^8.0.0`
    - `youtube_player_flutter: ^9.1.1`
    - `just_audio: ^0.9.38`
    - `video_player: ^2.8.2`
    - `chewie: ^1.8.0`
  - Adicionar em `dev_dependencies`:
    - `isar_generator: ^3.1.0`
    - `build_runner: ^2.4.9`
  - Executar `flutter pub get`.
- [x] **T0.2. Permissões Android (`AndroidManifest.xml`)**
  - Adicionar no arquivo `android/app/src/main/AndroidManifest.xml` dentro da tag `<manifest>`:
    ```xml
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    ```
  - Configurar dentro da tag `<application>`:
    ```xml
    android:extractNativeLibs="true"
    ```
- [x] **T0.3. Implementar Tema Moderno (`lib/core/theme/theme.dart`)**
  - Criar classe `AppTheme` definindo `ColorScheme.dark` utilizando as cores padrão:
    - Primary: `#FF0000`
    - Secondary: `#38BDF8`
    - Tertiary: `#22C55E`
    - Neutral: `#94A3B8`
- [x] **T0.4. Implementar GoRouter (`lib/core/router/router.dart`)**
  - Configurar `GoRouter` definindo rotas para:
    - `/explore` (Página inicial de busca).
    - `/download-setup` (Configurações de formatos de áudio/vídeo).
    - `/downloads` (Fila de downloads ativos e históricos).
    - `/settings` (Configurações de cookies e diretórios).
    - `/player` (Reprodução de mídia integrada online e offline).
    - `/playlist` (Visualização detalhada de playlists e lotes de URLs).
- [x] **T0.5. Configurar Isar Database (`lib/core/database/isar_service.dart`)**
  - Implementar classe `IsarService` que inicializa o banco Isar e gerencia a criação de instâncias para a coleção `DownloadTask`.
