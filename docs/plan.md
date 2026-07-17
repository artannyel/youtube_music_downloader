# Plano Geral de Desenvolvimento - YouTube Music & Video Downloader

Este documento define o plano geral de implementação, organizando o projeto em funcionalidades principais. Cada funcionalidade possui seu próprio plano de implementação detalhado e sua respectiva lista de tarefas.

---

## Fases de Desenvolvimento

O projeto foi segmentado nas seguintes fases e funcionalidades:

### 1. Infraestrutura & Configurações Iniciais
- **Foco**: Dependências, permissões Android, roteamento GoRouter, tema moderno do aplicativo e inicialização do banco de dados local.
- **Documento**: [Configuração Inicial](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_0_infra.md)

### 2. Feature 1: Exploração e Busca de Vídeos (Explore)
- **Foco**: Criação do serviço de busca utilizando `youtube_explode_dart`, e construção da interface moderna com barra de pesquisa e grid de resultados.
- **Documento**: [Plano da Feature 1: Explore](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_1_explore.md)

### 3. Feature 2: Tela de Configuração de Download (Download Setup)
- **Foco**: Parser de links com conversão do YouTube Music, carregamento de metadados, seleção de formatos e qualidades, campos de subpastas, e alertas de diretórios já existentes.
- **Documento**: [Plano da Feature 2: Download Setup](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_2_download_setup.md)

### 4. Feature 3: Motor de Downloads e Cookies (Downloader Engine)
- **Foco**: Inicialização e chamadas do cliente `extractor` (`yt-dlp`), injeção de arquivo de cookies persistido e lógica de fallback de qualidades de vídeo e áudio.
- **Documento**: [Plano da Feature 3: Downloader Engine](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_3_downloader_engine.md)

### 5. Feature 4: Sincronização de Notificações com Ações (Notifications)
- **Foco**: Notificações persistentes de progresso de download no Android com botões para cancelar ou pausar a operação ativamente.
- **Documento**: [Plano da Feature 4: Notifications](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_4_notifications.md)

### 6. Feature 5: Banco de Dados (Isar) e Histórico de Downloads (Downloads History)
- **Foco**: Integração do Isar para salvar tarefas, sincronização de estado, tela de downloads ativos/concluídos e abertura direta dos arquivos locais.
- **Documento**: [Plano da Feature 5: Downloads History](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_5_downloads_history.md)

### 7. Feature 6: Tela de Ajustes (Settings)
- **Foco**: Seleção e persistência do arquivo de cookies e controle de caminhos padrão do aplicativo.
- **Documento**: [Plano da Feature 6: Settings](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_6_settings.md)

### 8. Feature 7: Player de Mídia Integrado (Media Player)
- **Foco**: Player integrado para reprodução de áudio e vídeo online (via streaming) e offline (arquivos baixados) no aplicativo.
- **Documento**: [Plano da Feature 7: Media Player](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/features/feature_7_media_player.md)

---

## Fluxo de Execução
Cada item deve ser implementado de forma sequencial, com validação e testes individuais antes de passar para a próxima etapa.
Para cada funcionalidade, consulte o plano de feature correspondente.
- **Especificação de Referência**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md)
