# Plano de Feature - Tela de Ajustes (Settings)

Este documento detalha o plano de desenvolvimento e as subtarefas para a funcionalidade de Configurações do Aplicativo.

---

## 🔍 Referências de Documentação
- **Especificação Principal**: [spec.md](file:///home/artannyel/Documentos/Projetos/youtube_music_downloader/docs/spec.md) (Seções: *4. Regras de Negócio: Feature 5 - Cookies Integration*, *R5. Cookies para Conteúdo Restrito*)

---

## 🎯 Objetivo
Oferecer uma interface limpa e intuitiva para gerenciar as configurações persistentes da aplicação, incluindo a seleção e armazenamento do caminho de arquivos de cookies (essencial para burlar restrições de idade nos vídeos do YouTube) e a verificação do diretório de downloads ativo.

---

## 📈 Plano de Desenvolvimento

1. **Camada de Dados (Shared Preferences)**:
   - Criar chaves persistentes para armazenar o caminho absoluto do arquivo `cookies.txt` importado.
2. **Integração de Importação de Arquivos (Data/Domain)**:
   - Utilizar o pacote `file_picker` para permitir que o usuário navegue no armazenamento e selecione o arquivo de cookies.
   - Validar se o arquivo selecionado é do formato `.txt` antes de persistir o caminho.
3. **Camada de Apresentação (Presentation UI)**:
   - Criar a tela `SettingsScreen` com estilo minimalista e moderno contendo:
     - Bloco de configuração de Cookies: Exibe se o arquivo está "Configurado" ou "Não Configurado" com o caminho atual.
     - Botão para "Selecionar Arquivo de Cookies" e "Remover Cookies".
     - Informações de armazenamento do dispositivo (exibindo a pasta pública onde os vídeos e músicas estão sendo salvos).

---

## 📋 Lista de Tarefas (Subtasks)

- [ ] **T6.1. Criar Repositório de Configurações (`SettingsRepository`)**
  - Implementar em `lib/features/settings/data/repositories/settings_repository_impl.dart`:
    - `Future<void> setCookiesPath(String path)`: Salva o path no SharedPreferences.
    - `Future<String?> getCookiesPath()`: Recupera o path do SharedPreferences.
    - `Future<void> clearCookies()`: Remove a chave do SharedPreferences.
- [ ] **T6.2. Implementar Provedor Riverpod de Ajustes**
  - Criar `lib/features/settings/presentation/providers/settings_provider.dart`:
    - `settingsStateProvider` (gerencia o estado atual das configurações e notifica a tela em caso de alterações).
- [ ] **T6.3. Desenhar Tela `SettingsScreen`**
  - Implementar em `lib/features/settings/presentation/pages/settings_page.dart`:
    - Seção de cookies com indicação visual de status (ícone verde de ativo se configurado, vermelho se inativo).
    - Integração com `file_picker` ao pressionar o botão de importação.
    - Seção com informações de caminhos padrão (`/Download/videos` e `/Download/musicas`).
