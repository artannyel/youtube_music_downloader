# Plano de Feature - Exploração e Busca de Vídeos (Explore)

Este documento detalha o plano de desenvolvimento e as subtarefas para a funcionalidade de Exploração e Busca de vídeos.

---

## 🔍 Referências de Documentação
- **Especificação Principal**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md) (Seções: *4. Regras de Negócio: Feature 1 - Explore & Search*, *5. UI/UX Concept*)

---

## 🎯 Objetivo
Permitir a busca de vídeos e músicas do YouTube utilizando a API pública do `youtube_explode_dart`. O usuário digitará um termo de busca e visualizará uma lista/grid moderna de resultados com informações relevantes antes de selecionar o item para baixar.

---

## 📈 Plano de Desenvolvimento

1. **Camada de Dados (Data)**:
   - Criar `YoutubeExplodeService` para buscar vídeos e mapeá-los para entidades do domínio.
2. **Camada de Domínio (Domain)**:
   - Definir a entidade `YoutubeVideoResult` contendo dados essenciais (ID do vídeo, título, autor, duração, thumbnail, visualizações).
   - Definir a interface `ExploreRepository` para gerenciar as buscas.
3. **Camada de Apresentação (Presentation & State)**:
   - Implementar `ExploreNotifier` usando Riverpod para controlar o estado da pesquisa (Idle, Carregando, Sucesso, Erro).
   - Construir a tela `ExploreScreen` com uma barra de busca moderna estilo glassmorphism, esqueleto de carregamento (shimmers) e cards de resultado responsivos.
   - Navegar para `/download-setup` ao clicar em um resultado, passando o ID ou a URL do vídeo.

---

## 📋 Lista de Tarefas (Subtasks)

- [x] **T1.1. Criar Entidade `YoutubeVideoResult`**
  - Implementar classe em `lib/features/explore/domain/entities/youtube_video_result.dart`:
    - `id`: String (Video ID).
    - `title`: String.
    - `author`: String (Nome do canal).
    - `duration`: Duration.
    - `thumbnailUrl`: String.
    - `viewCount`: int.
- [x] **T1.2. Implementar `ExploreRepository` e Service**
  - Criar `lib/features/explore/domain/repositories/explore_repository.dart` (interface).
  - Criar `lib/features/explore/data/repositories/explore_repository_impl.dart` (implementação usando `youtube_explode_dart`).
- [x] **T1.3. Configurar Gerenciamento de Estado Riverpod**
  - Criar `lib/features/explore/presentation/providers/explore_provider.dart`:
    - `exploreSearchProvider` (StateNotifier ou AsyncNotifier para buscar termos e gerenciar paginação de resultados).
- [x] **T1.4. Desenhar Tela `ExploreScreen`**
  - Construir layout em `lib/features/explore/presentation/pages/explore_page.dart`:
    - Barra de busca superior moderna (limpa, com borda neon/gradiente suave).
    - Lista de resultados ou grid responsivo.
    - Componentes de shimmer para feedback visual de carregamento.
    - Redirecionamento amigável para a tela de configurações de download.
- [x] **T1.5. Paginação de Resultados (Scroll Infinito)**
  - Atualizar repositório para expor `nextSearchPage()`.
  - Atualizar notifier para controlar `ExploreState` paginado.
  - Implementar `ScrollController` e indicador de carregamento inferior na UI.

