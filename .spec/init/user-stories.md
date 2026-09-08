# config-linux — User Stories

<!-- inputs: project-description.md@sha256:580c3eda7e10 -->

## Overview

**config-linux** é um bootstrap/dotfiles para deixar uma máquina Linux (Ubuntu 24.04 ou 26.04) utilizável do zero, replicando o ambiente de desenvolvimento desta máquina — PHP multi-versão, Node, Docker, Claude Code CLI, Codex CLI, dotfiles e configs replicáveis. Não é multiusuário nem distribuído a terceiros: existe um único tipo de usuário, o próprio desenvolvedor operando em máquinas diferentes.

**User Types:**
- **Desenvolvedor** - dono do projeto; roda o bootstrap numa máquina nova (usuário/`$HOME` diferentes do original), mantém o repo atualizado com o que sai desta máquina, e decide o que entra ou não no setup padrão.

---

## 1. Setup inicial de uma máquina nova

### US-1.1: Rodar o bootstrap completo numa máquina nova
**As a** Desenvolvedor
**I want to** clonar o repositório e rodar `install.sh` numa máquina Ubuntu nova
**So that** a máquina fique com PHP, Node, Docker, Claude Code CLI, Codex CLI e meus dotfiles configurados sem repetir passo manual um por um

**Acceptance Criteria:**
- [ ] `git clone` do repositório privado funciona em qualquer usuário/`$HOME`, sem caminho hardcoded pra `romualdoviana`.
- [ ] `./install.sh` executa, em ordem, os módulos: sistema base → PHP (8.2, 8.3, 8.4, 8.5) + Composer → Node.js (última) → Docker Engine + Compose → Claude Code CLI → Codex CLI → dotfiles/configs.
- [ ] Script detecta `$HOME`/`$USER` em tempo de execução; nenhum caminho absoluto do usuário original aparece nos arquivos copiados/linkados.
- [ ] Ao final, imprime um resumo com o que foi instalado/copiado e quais logins manuais ainda estão pendentes.

**Expected Result:** máquina nova com PHP 8.2/8.3/8.4/8.5, Node, Docker, Claude Code CLI e Codex CLI instalados, dotfiles e configs replicáveis no lugar, e um resumo final listando pendências de login manual.

---

### US-1.2: Detectar e recusar distro/versão não suportada
**As a** Desenvolvedor
**I want to** que o script identifique o codename do Ubuntu antes de instalar qualquer coisa
**So that** eu não corra risco de rodar o bootstrap numa distro incompatível e deixar a máquina num estado quebrado

**Acceptance Criteria:**
- [ ] Script lê o codename via `lsb_release`/`/etc/os-release` antes do primeiro passo de instalação.
- [ ] Se o codename for de Ubuntu 24.04 ou 26.04, segue normalmente.
- [ ] Se for qualquer outra versão do Ubuntu ou outra distro, o script para imediatamente, sem instalar nada, e imprime mensagem clara dizendo qual codename foi detectado e quais são os suportados.

**Expected Result:** rodar o script numa distro não suportada não instala nada e explica o motivo; rodar em 24.04 ou 26.04 segue o fluxo normal com a PPA `ondrej/php` resolvida pro codename certo.

---

### US-1.3: Parar imediatamente quando um passo falha
**As a** Desenvolvedor
**I want to** que o bootstrap aborte assim que um módulo falhar (ex: pacote não baixa, PPA fora do ar)
**So that** eu saiba exatamente o que já foi instalado e o que não, em vez de ter uma máquina "meio configurada" sem perceber

**Acceptance Criteria:**
- [ ] Qualquer módulo (`php.sh`, `node.sh`, `docker.sh`, `claude-code.sh`, `codex.sh`, `dotfiles.sh`) que retornar erro interrompe a execução do `install.sh` imediatamente — não segue pro próximo módulo.
- [ ] Mensagem de erro identifica qual módulo/comando falhou e o exit code.
- [ ] Módulos já concluídos antes da falha permanecem instalados (nada é desfeito/rollback automático).
- [ ] Reexecutar `./install.sh` depois de corrigir o problema retoma do zero mas pula o que já está instalado (idempotência, ver US-2.1).

**Expected Result:** uma falha no meio do bootstrap para tudo na hora, com mensagem clara de causa, sem tentar continuar os módulos seguintes.

---

### US-1.4: Autenticar manualmente as ferramentas que exigem login
**As a** Desenvolvedor
**I want to** que o script me avise exatamente quando e como autenticar (Claude Code, Codex, `gh`, Docker Hub se aplicável)
**So that** nenhuma credencial real precise estar no repositório e eu não esqueça de nenhum login pendente

**Acceptance Criteria:**
- [ ] O script nunca tenta ler nem copiar `.credentials.json`, `auth.json`, tokens ou sessões vivas do repo pra máquina nova.
- [ ] Ao chegar num passo que exige autenticação, imprime o comando exato a rodar (ex: `claude login`, `codex login`, `gh auth login`) e segue para o próximo módulo sem travar esperando input interativo de login.
- [ ] O resumo final (US-1.1) lista cada login pendente que ainda não foi confirmado.

**Expected Result:** setup completo sem nenhum segredo tocar o repositório; toda autenticação fica registrada como pendência clara no resumo final até o desenvolvedor rodar o login manualmente.

---

## 2. Manutenção e atualização

### US-2.1: Reexecutar o bootstrap sem duplicar efeito
**As a** Desenvolvedor
**I want to** rodar `./install.sh` de novo numa máquina onde parte do setup já existe
**So that** eu possa corrigir/atualizar sem me preocupar em duplicar instalação, sobrescrever link ou quebrar algo já configurado

**Acceptance Criteria:**
- [ ] Cada módulo verifica se seu alvo já está satisfeito (pacote já instalado na versão esperada, link/arquivo já no lugar certo) antes de agir.
- [ ] Rodar `./install.sh` duas vezes seguidas na mesma máquina produz o mesmo estado final da primeira vez, sem erro e sem efeito colateral (ex: alias duplicado no `.bashrc`, PPA adicionada duas vezes).
- [ ] Módulos que já estão satisfeitos são reportados como "já instalado / pulado", não re-executados do zero.

**Expected Result:** `install.sh` é seguro de rodar quantas vezes for preciso; segunda execução não altera nada que já estava correto.

---

### US-2.2: Atualizar/reinstalar um único módulo
**As a** Desenvolvedor
**I want to** rodar só `./install/php.sh` ou só `./install/dotfiles.sh` isoladamente
**So that** eu não precise rodar o bootstrap inteiro quando só uma parte específica mudou

**Acceptance Criteria:**
- [ ] Cada módulo (`php.sh`, `node.sh`, `docker.sh`, `claude-code.sh`, `codex.sh`, `dotfiles.sh`) pode ser executado diretamente, fora do `install.sh`.
- [ ] Módulo isolado aplica o mesmo check de idempotência do fluxo completo (US-2.1).
- [ ] Módulo isolado não depende de estado que só o `install.sh` completo configuraria (cada módulo é autocontido).

**Expected Result:** qualquer módulo roda sozinho, do mesmo jeito e com a mesma segurança de idempotência que teria dentro do bootstrap completo.

---

## 3. Curadoria do repositório

### US-3.1: Levar uma nova config/alias desta máquina pro repo
**As a** Desenvolvedor
**I want to** copiar manualmente um alias, função ou config nova pro arquivo versionado correspondente
**So that** o próximo bootstrap em outra máquina já inclua essa novidade

**Acceptance Criteria:**
- [ ] Existe um arquivo versionado por categoria (ex: `dotfiles/bashrc_aliases`, `claude/settings.json`) onde a novidade é adicionada manualmente.
- [ ] Antes do commit, o desenvolvedor confirma visualmente que nenhum segredo, token, caminho pessoal específico desta máquina (`/home/romualdoviana/...`) ou dado sensível foi incluído.
- [ ] Commit e push seguem pro repositório remoto privado.

**Expected Result:** o repositório reflete a config mais atual desejada, sem nunca carregar segredo ou caminho hardcoded desta máquina específica.

---

### US-3.2: Nunca versionar config sensível por engano
**As a** Desenvolvedor
**I want to** que exista uma lista explícita do que é sempre excluído (`.credentials.json`, `auth.json`, `history.jsonl`, `sessions/`, `session-env/`, cache)
**So that** eu não corra risco de vazar segredo ou dado pessoal ao copiar configs de `.claude/`/`.codex/` pro repo

**Acceptance Criteria:**
- [ ] Repositório mantém um `.gitignore` (ou lista equivalente documentada) cobrindo todo arquivo/pasta classificado como "config sensível" no projeto.
- [ ] Tentar adicionar um desses arquivos ao git é bloqueado ou pelo menos sinalizado antes do commit.
- [ ] Apenas o que está classificado como "config replicável" (settings sem segredo, skills, agents, commands, hooks, CLAUDE.md, AGENTS.md) é versionado de `.claude/`/`.codex/`.

**Expected Result:** é estruturalmente difícil commitar por acidente um segredo ou dado sensível — a exclusão é explícita e documentada, não depende só de atenção manual.

---

## Appendix: User Story Status

| ID | Story | Priority | Status |
|----|-------|----------|--------|
| US-1.1 | Rodar o bootstrap completo numa máquina nova | High | Pending |
| US-1.2 | Detectar e recusar distro/versão não suportada | High | Pending |
| US-1.3 | Parar imediatamente quando um passo falha | High | Pending |
| US-1.4 | Autenticar manualmente as ferramentas que exigem login | High | Pending |
| US-2.1 | Reexecutar o bootstrap sem duplicar efeito | High | Pending |
| US-2.2 | Atualizar/reinstalar um único módulo | High | Pending |
| US-3.1 | Levar uma nova config/alias desta máquina pro repo | Medium | Pending |
| US-3.2 | Nunca versionar config sensível por engano | High | Pending |
