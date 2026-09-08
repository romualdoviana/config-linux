# config-linux — Project Phases

<!-- inputs: project-description.md@sha256:580c3eda7e10 user-stories.md@sha256:144a307ac271 database-schema.md@sha256:186c1a86f0be -->

## Overview

Build em **9 fases**, foundation-first: a Fase 1 entrega a biblioteca shell compartilhada (log/erro, detecção de distro, idempotência) que todo módulo depende. Fases 2–6 implementam cada módulo de instalação isolado (PHP, Node, Docker, Claude Code CLI, Codex CLI), cada um idempotente e executável sozinho desde que nasce. Fase 7 cobre dotfiles e replicação de config. Fase 8 é o orquestrador `install.sh` que amarra tudo na ordem certa com stop-on-failure e resumo final. Fase 9 fecha a rede de segurança de curadoria (exclusão de config sensível + doc do fluxo de contribuição). Repositório está vazio hoje — todas as tasks começam `[ ]`. **A Fase 8 é o corte de MVP**: com ela pronta, `install.sh` já cobre o fluxo completo de setup numa máquina nova (US-1.1 a US-1.4, US-2.1, US-2.2). Fase 9 é follow-up de disciplina de repositório, não bloqueia uso do bootstrap.

Lógica com ramificação real (resolução de codename→PPA, seleção de extensão por versão de PHP, idempotência, propagação de erro, allow-list de config replicável, exclusão de config sensível) ganha testes em **bats-core**. Todo `.sh` do repositório passa por **shellcheck** antes de qualquer fase ser considerada pronta.

**Conventions:**
- `[ ]` pending · `[x]` done in the codebase.
- Phases and sub-phases are numbered (`Phase 1`, `Phase 5.3`) for reference by AI agents.
- Business-logic tasks list the **feature tests** (bats) to generate; mechanical/wiring tasks list only **acceptance criteria**.

---

## Phase 1: Foundation — biblioteca shell compartilhada

**Goal:** dar a todo módulo os mesmos primitivos de log/erro, detecção de distro e idempotência. · **Depends on:** none · **Covers:** US-1.2, US-1.3, US-2.1; key concepts "Distro alvo", "Bootstrap script"

### Phase 1.1: Esqueleto do repositório

- [ ] **Task:** criar layout do repositório (`install.sh` na raiz, `install/` pros módulos, `lib/` pras funções compartilhadas, `tests/` pros specs bats, `scripts/lint.sh` e `scripts/test.sh`)
  - **Acceptance criteria:**
    - `install.sh` existe na raiz e é executável (`chmod +x`).
    - Diretórios `install/`, `lib/`, `tests/`, `scripts/` existem.
    - `scripts/lint.sh` roda `shellcheck` em todo `.sh` versionado e sai com código de erro se qualquer script falhar o lint.
    - `scripts/test.sh` roda todos os arquivos `.bats` em `tests/`.
  - **Traces:** US-1.1

### Phase 1.2: Log e propagação de erro (stop-on-failure)

- [ ] **Task:** criar `lib/common.sh` com `set -euo pipefail`, funções `log_info`/`log_warn`/`log_error`, e um trap de erro que imprime qual comando/módulo falhou antes de abortar
  - **Acceptance criteria:**
    - Qualquer script que faz `source lib/common.sh` aborta no primeiro comando com erro (`set -e` efetivo mesmo dentro de função chamada por outro script).
    - Mensagem de erro identifica o comando que falhou e o exit code.
  - **Feature tests:** `common_abort_on_error.bats` — um comando fake com exit 1 dentro de uma função sourcing `common.sh` aborta o script chamador sem executar o comando seguinte; a mensagem de erro contém o nome do comando que falhou.
  - **Traces:** US-1.3

### Phase 1.3: Detecção de distro (codename → PPA)

- [ ] **Task:** criar `lib/os-detect.sh` com `detect_ubuntu_codename()` (lê `/etc/os-release`), `is_supported_codename(codename)` (true só para o codename de 24.04 e de 26.04) e `resolve_php_ppa_url(codename)`
  - **Acceptance criteria:**
    - `detect_ubuntu_codename` lê de um `/etc/os-release` passado por variável/arquivo injetável (pra ser testável sem depender do SO real).
    - `is_supported_codename` retorna verdadeiro só para os dois codenames suportados; qualquer outro (incluindo outra distro) retorna falso.
    - `resolve_php_ppa_url` devolve a URL da PPA `ondrej/php` parametrizada pelo codename recebido.
  - **Feature tests:** `os_detect.bats` — fixtures de `/etc/os-release` pra 24.04, 26.04, um Ubuntu não suportado (ex: 22.04) e uma distro não-Ubuntu (ex: Debian); cada fixture deve casar com o resultado esperado de `is_supported_codename` e, quando suportado, com a URL correta de `resolve_php_ppa_url`.
  - **Traces:** US-1.2

### Phase 1.4: Idempotência

- [ ] **Task:** criar `lib/idempotent.sh` com `mark_done(marker)`, `is_already_done(marker)` (usando um diretório de estado em `~/.config/config-linux/state`, criado se não existir)
  - **Acceptance criteria:**
    - `mark_done` seguido de `is_already_done` pro mesmo marker retorna verdadeiro.
    - Markers diferentes são independentes entre si.
    - Chamar `mark_done` duas vezes pro mesmo marker não gera erro.
  - **Feature tests:** `idempotent.bats` — marca um marker e confirma `is_already_done` true; confirma que um marker nunca marcado retorna false; confirma que markers distintos não se afetam; confirma que `mark_done` é seguro de chamar 2x seguidas.
  - **Traces:** US-2.1

---

## Phase 2: Módulo PHP (8.2 a 8.5, extensões por versão)

**Goal:** instalar as 4 versões de PHP com o conjunto de extensões correto por versão, sem padronizar entre elas. · **Depends on:** Phase 1 · **Covers:** US-1.1, US-2.1, US-2.2; key concepts "Versão pinada (PHP)", "Extensões por versão", "Xdebug fora do bootstrap padrão", "`php.ini` sem override customizado"

### Phase 2.1: Matriz de versões e extensões

- [x] **Task:** em `install/php.sh`, declarar a lista de versões alvo (`8.2 8.3 8.4 8.5`) e, pra cada uma, a lista exata de pacotes de extensão a instalar: 8.2 → `bz2 curl gd imagick intl mbstring mysql opcache readline xml zip` (+ `cli fpm common`); 8.3 → `bcmath bz2 curl intl mbstring mysql opcache readline xml zip` (+ `cli fpm common`); 8.4 → `bcmath curl intl mbstring mysql opcache pgsql readline sqlite3 xml zip` (+ `cli fpm common`); 8.5 → só `cli fpm common` (sem referência local ainda)
  - **Acceptance criteria:**
    - A lista de pacotes por versão bate exatamente com o Key Concept "Extensões por versão" do `project-description.md` — nenhuma extensão a mais, nenhuma a menos.
    - `php8.2-xdebug` não aparece em nenhuma lista (xdebug é sempre manual, ver Phase 2.4).
    - `shellcheck` passa em `install/php.sh`.
  - **Feature tests:** `php_extension_matrix.bats` — pra cada versão (8.2/8.3/8.4/8.5), a função que retorna a lista de pacotes daquela versão bate byte-a-byte com a lista esperada acima; nenhuma lista contém `xdebug`.
  - **Traces:** US-1.1

### Phase 2.2: Instalação e `update-alternatives`

- [x] **Task:** função `install_php_version(version)` que garante a PPA `ondrej/php` adicionada (via `resolve_php_ppa_url` da Fase 1.3), roda `apt-get install` com a lista de pacotes da versão (Fase 2.1), e ajusta `update-alternatives --install`/`--set` pro binário `php` conforme a versão mais recente instalada
  - **Acceptance criteria:**
    - Rodar `install_php_version 8.4` numa máquina limpa deixa `php -v` reportando 8.4 (ou a versão mais recente instalada, se mais de uma).
    - PPA é adicionada uma única vez mesmo se `install_php_version` for chamada pra várias versões na mesma execução.
  - **Feature tests:** `php_install.bats` — com um wrapper fake de `apt-get`/`add-apt-repository` que só registra os argumentos recebidos (sem instalar de verdade), `install_php_version 8.2` deve pedir exatamente os pacotes da lista 8.2 (Fase 2.1), nem mais nem menos; chamar pra duas versões na mesma sessão não duplica a chamada de adicionar a PPA.
  - **Traces:** US-1.1

### Phase 2.3: Idempotência e execução standalone

- [x] **Task:** `install/php.sh` faz `source lib/common.sh lib/os-detect.sh lib/idempotent.sh`, itera as versões alvo pulando (via `is_already_done`) a combinação versão+extensões já satisfeita, e é executável tanto standalone (`./install/php.sh`) quanto chamado de dentro de `install.sh`
  - **Acceptance criteria:**
    - Rodar `./install/php.sh` duas vezes seguidas na mesma máquina não chama `apt-get install` de novo pra uma versão já instalada com o conjunto de extensões esperado.
    - Rodar `./install/php.sh` isoladamente (sem passar por `install.sh`) produz o mesmo resultado que rodar dentro do fluxo completo.
  - **Feature tests:** `php_idempotent.bats` — marca a versão 8.2 como já feita (via `lib/idempotent.sh`) e confirma que `install_php_version` não é chamada de novo pra ela numa segunda execução do módulo.
  - **Traces:** US-2.1, US-2.2

### Phase 2.4: Xdebug fica manual

- [x] **Task:** garantir que `install/php.sh` nunca instala `php<versão>-xdebug` por padrão, e documentar no `README.md` uma seção "Debug (xdebug) — manual" com o comando exato (`sudo apt install php<versão>-xdebug`) pra quando o desenvolvedor precisar debugar
  - **Acceptance criteria:**
    - `grep -r xdebug install/php.sh` não encontra nenhuma instalação automática (só pode aparecer, se aparecer, em comentário/doc).
    - `README.md` tem a seção "Debug (xdebug) — manual" com o comando de instalação manual.
  - **Traces:** US-1.1

---

## Phase 3: Módulo Node.js

**Goal:** instalar Node.js na versão mais recente disponível, de forma idempotente e standalone. · **Depends on:** Phase 1 · **Covers:** US-1.1, US-2.1, US-2.2

### Phase 3.1: Instalação do Node

- [x] **Task:** `install/node.sh` adiciona o repositório oficial NodeSource resolvido pelo codename detectado (Fase 1.3) e instala o pacote `nodejs` (última versão disponível no repositório), sourcing `lib/common.sh`, `lib/os-detect.sh`, `lib/idempotent.sh`
  - **Acceptance criteria:**
    - Depois de rodar, `node -v` e `npm -v` funcionam.
    - Rodar `./install/node.sh` duas vezes seguidas não reinstala se `node`/`npm` já estão presentes (idempotência via `lib/idempotent.sh`).
    - Executável standalone (`./install/node.sh`) e a partir de `install.sh`.
    - `shellcheck` passa em `install/node.sh`.
  - **Traces:** US-1.1, US-2.1, US-2.2

---

## Phase 4: Módulo Docker

**Goal:** instalar Docker Engine + Compose plugin e liberar o usuário de destino pra usar Docker sem sudo. · **Depends on:** Phase 1 · **Covers:** US-1.1, US-2.1, US-2.2

### Phase 4.1: Instalação do Docker Engine + Compose

- [x] **Task:** `install/docker.sh` adiciona o repositório oficial do Docker resolvido pelo codename detectado, instala `docker-ce docker-ce-cli containerd.io docker-compose-plugin`, e adiciona `$USER` (detectado em runtime, nunca hardcoded) ao grupo `docker`
  - **Acceptance criteria:**
    - `docker --version` e `docker compose version` funcionam após a instalação.
    - `$USER` (o usuário que rodou o script, não um nome fixo) é adicionado ao grupo `docker`.
    - Rodar duas vezes seguidas não falha nem duplica a adição ao grupo (idempotência via `lib/idempotent.sh` + checagem `id -nG "$USER" | grep -qw docker`).
    - Executável standalone e a partir de `install.sh`.
    - `shellcheck` passa em `install/docker.sh`.
  - **Traces:** US-1.1, US-2.1, US-2.2

---

## Phase 5: Módulo Claude Code CLI

**Goal:** instalar a última versão do Claude Code CLI e deixar claro que o login é passo manual. · **Depends on:** Phase 1 · **Covers:** US-1.1, US-1.4, US-2.1, US-2.2

### Phase 5.1: Instalação

- [x] **Task:** `install/claude-code.sh` instala a última versão do Claude Code CLI pelo método oficial de instalação, sourcing `lib/common.sh`, `lib/idempotent.sh`
  - **Acceptance criteria:**
    - `claude --version` funciona após a instalação.
    - Rodar duas vezes seguidas não reinstala se o binário já está presente.
    - Executável standalone e a partir de `install.sh`.
    - `shellcheck` passa em `install/claude-code.sh`.
  - **Traces:** US-1.1, US-2.1, US-2.2

### Phase 5.2: Login manual pendente

- [x] **Task:** depois de instalar, o módulo imprime a instrução exata (`claude login`) e registra um marker de "login pendente" (ex.: `~/.config/config-linux/pending-logins/claude`) sem travar esperando input interativo
  - **Acceptance criteria:**
    - O script nunca lê nem copia `.credentials.json`/`auth.json` do repo pra máquina de destino.
    - Módulo termina com sucesso mesmo sem o login ter sido feito.
    - Marker de "login pendente" pra `claude` é criado uma única vez mesmo rodando o módulo várias vezes.
  - **Feature tests:** `claude_pending_login.bats` — rodar o passo de marcação de login pendente duas vezes resulta em um único marker (sem duplicar); o marker desaparece/não é recriado se o desenvolvedor já confirmou o login (função de "limpar pendência" fica idempotente).
  - **Traces:** US-1.4

---

## Phase 6: Módulo Codex CLI

**Goal:** instalar a última versão do Codex CLI e deixar claro que o login é passo manual. · **Depends on:** Phase 1 · **Covers:** US-1.1, US-1.4, US-2.1, US-2.2

### Phase 6.1: Instalação

- [x] **Task:** `install/codex.sh` instala a última versão do Codex CLI pelo método oficial de instalação, sourcing `lib/common.sh`, `lib/idempotent.sh`
  - **Acceptance criteria:**
    - `codex --version` funciona após a instalação.
    - Rodar duas vezes seguidas não reinstala se o binário já está presente.
    - Executável standalone e a partir de `install.sh`.
    - `shellcheck` passa em `install/codex.sh`.
  - **Traces:** US-1.1, US-2.1, US-2.2

### Phase 6.2: Login manual pendente

- [x] **Task:** mesmo padrão da Fase 5.2, com `codex login` e marker `~/.config/config-linux/pending-logins/codex`
  - **Acceptance criteria:**
    - O script nunca lê nem copia `auth.json`/`config.toml` com segredo do repo pra máquina de destino.
    - Marker de "login pendente" pra `codex` é criado uma única vez mesmo rodando o módulo várias vezes.
  - **Feature tests:** `codex_pending_login.bats` — mesmo formato do `claude_pending_login.bats` (Fase 5.2), aplicado ao marker `codex`.
  - **Traces:** US-1.4

---

## Phase 7: Dotfiles e replicação de config

**Goal:** copiar dotfiles e a parte replicável de `.claude`/`.codex` pro `$HOME` de destino, sem nunca tocar em config sensível. · **Depends on:** Phase 1 · **Covers:** US-1.1, US-2.1, US-3.2; key concepts "Dotfile", "Config replicável", "Config sensível"

### Phase 7.1: Dotfiles (`.bashrc`, `.bashrc_aliases`)

- [ ] **Task:** `install/dotfiles.sh` copia `dotfiles/bashrc_aliases` versionado pra `~/.bashrc_aliases` do usuário de destino, e garante (idempotentemente) uma linha `source ~/.bashrc_aliases` no `~/.bashrc`, sem duplicar a linha se rodado de novo
  - **Acceptance criteria:**
    - Depois de rodar, `~/.bashrc_aliases` existe com o conteúdo versionado.
    - `~/.bashrc` contém exatamente uma linha `source ~/.bashrc_aliases` mesmo depois de rodar o módulo várias vezes.
  - **Feature tests:** `dotfiles_append.bats` — chamar a função de "adicionar linha de source se não existir" duas vezes seguidas num `.bashrc` fake resulta em uma única ocorrência da linha; chamar num `.bashrc` que já tem a linha não duplica.
  - **Traces:** US-1.1, US-2.1

### Phase 7.2: Config replicável de `.claude`/`.codex` (nunca sensível)

- [ ] **Task:** `install/dotfiles.sh` (ou módulo dedicado `install/ai-config.sh`) copia só o allow-list de "config replicável" (`settings.json` sem segredo, `skills/`, `agents/`, `commands/`, `hooks/`, `CLAUDE.md`, `AGENTS.md`) de dentro do repo pra `~/.claude` e `~/.codex`, com um exclude-list explícito cobrindo tudo que é "config sensível" (`.credentials.json`, `auth.json`, `history.jsonl`, `sessions/`, `session-env/`, cache, `*.sqlite*`, logs)
  - **Acceptance criteria:**
    - Função `copy_replicable_config(src, dest)` só copia caminhos presentes no allow-list; qualquer arquivo/pasta no exclude-list nunca é copiado, mesmo que esteja fisicamente presente na origem.
    - `shellcheck` passa no módulo.
  - **Feature tests:** `replicable_config.bats` — dada uma árvore fixture com arquivos tanto do allow-list quanto do exclude-list (ex.: `settings.json`, `skills/foo.md`, `.credentials.json`, `history.jsonl`), rodar `copy_replicable_config` só materializa os arquivos do allow-list no destino; nenhum arquivo do exclude-list aparece no destino.
  - **Traces:** US-1.1, US-3.2

---

## Phase 8: Orquestrador `install.sh`

**Goal:** amarrar todos os módulos na ordem certa, com stop-on-failure e resumo final — este é o corte de MVP. · **Depends on:** Phase 1, Phase 2, Phase 3, Phase 4, Phase 5, Phase 6, Phase 7 · **Covers:** US-1.1, US-1.2, US-1.3, US-1.4

`Suite: completa`

### Phase 8.1: Gate de distro e execução em ordem

- [ ] **Task:** `install.sh` faz `source lib/common.sh lib/os-detect.sh`, checa `is_supported_codename` **antes** de qualquer instalação (aborta com mensagem clara se não suportado), e então chama, nesta ordem, `install/php.sh` → `install/node.sh` → `install/docker.sh` → `install/claude-code.sh` → `install/codex.sh` → `install/dotfiles.sh`, abortando imediatamente (via o trap de erro da Fase 1.2) se qualquer um retornar erro
  - **Acceptance criteria:**
    - Numa fixture de codename não suportado, `install.sh` sai com erro antes de chamar qualquer módulo.
    - Numa fixture de codename suportado, os módulos são chamados exatamente na ordem especificada.
  - **Feature tests:** `install_orchestration.bats` — com os 6 módulos substituídos por stubs que só registram se foram chamados: (1) fixture de distro não suportada → nenhum stub é chamado; (2) todos os stubs retornando sucesso → todos são chamados na ordem certa; (3) o terceiro stub (docker) retornando erro → os stubs 4/5/6 (claude-code, codex, dotfiles) **não** são chamados.
  - **Traces:** US-1.1, US-1.2, US-1.3

### Phase 8.2: Resumo final

- [ ] **Task:** `install.sh` acumula, por módulo, o status (`instalado` / `já estava instalado — pulado` / `falhou`) e, ao final, imprime um resumo consolidado incluindo a lista de logins pendentes coletados dos markers criados nas Fases 5.2 e 6.2
  - **Acceptance criteria:**
    - Resumo final lista o status de cada um dos 6 módulos.
    - Se houver marker de login pendente pra `claude` e/ou `codex`, o resumo lista exatamente essas ferramentas como pendentes; se não houver nenhum marker, a seção de pendências fica vazia/ausente.
  - **Feature tests:** `install_summary.bats` — com markers de pendência fixture (nenhum, um, os dois), a função de montar o resumo final lista exatamente as pendências esperadas em cada caso.
  - **Traces:** US-1.1, US-1.4

---

## Phase 9: Curadoria e rede de segurança contra config sensível

**Goal:** tornar estruturalmente difícil versionar segredo por engano, e documentar como levar uma config nova pro repo. · **Depends on:** Phase 7 · **Covers:** US-3.1, US-3.2

### Phase 9.1: `.gitignore` cobrindo toda config sensível

- [ ] **Task:** criar `.gitignore` na raiz do repositório listando todo padrão do Key Concept "Config sensível" (`*.credentials.json`, `auth.json`, `history.jsonl`, `sessions/`, `session-env/`, `cache/`, `*.sqlite*`, `logs/`) de forma que qualquer cópia acidental de uma árvore real de `~/.claude`/`~/.codex` pro repo não consiga ser staged
  - **Acceptance criteria:**
    - `git check-ignore` retorna "ignorado" pra um arquivo de exemplo de cada padrão sensível listado.
    - `git check-ignore` **não** ignora um arquivo de exemplo de config replicável (ex.: `settings.json`, `CLAUDE.md`).
  - **Feature tests:** `gitignore_sensitive.bats` — pra cada padrão sensível (lista acima), criar um arquivo de exemplo com esse nome dentro de uma cópia de teste do repo e confirmar `git check-ignore -q <arquivo>` retorna sucesso (ignorado); pra um arquivo allow-list de exemplo, confirmar que `git check-ignore -q <arquivo>` retorna falha (não ignorado).
  - **Traces:** US-3.2

### Phase 9.2: Documentação do fluxo de curadoria

- [ ] **Task:** seção no `README.md` "Como levar uma config nova pro repo" descrevendo o Workflow 3 do `project-description.md`: copiar o trecho pro arquivo versionado certo (`dotfiles/bashrc_aliases`, configs de `.claude`/`.codex`), revisar visualmente antes do commit que nada sensível/pessoal entrou, e então commit + push pro remoto privado
  - **Acceptance criteria:**
    - Seção existe no `README.md` e referencia os caminhos reais do repositório (`dotfiles/bashrc_aliases`, etc.).
    - Seção menciona explicitamente o passo de revisão antes do commit.
  - **Traces:** US-3.1
