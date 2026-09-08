# config-linux — Project Description

## Overview

**config-linux** é um projeto de **bootstrap/dotfiles** para deixar uma máquina Linux nova (Ubuntu **24.04 ou 26.04**, WSL2 ou bare metal) **utilizável do zero**, replicando o ambiente de desenvolvimento configurado nesta máquina. O público é o próprio desenvolvedor trocando de computador ou reinstalando o sistema — **não** é um projeto multiusuário nem distribuído a terceiros.

O núcleo é um conjunto de **scripts shell (`sh`/`bash`) idempotentes** que: (1) instalam pacotes de sistema e ferramentas (PHP em múltiplas versões, Node.js, Docker, Claude Code CLI, Codex CLI), e (2) copiam/linkam arquivos de configuração (dotfiles, aliases, functions do `.bashrc`, configs de `.claude/` e `.codex/`) para os lugares certos no `$HOME` do usuário novo. O usuário de destino **não é o mesmo usuário desta máquina** — os scripts não podem assumir nome de usuário, UID ou caminhos absolutos que dependam de `romualdoviana`.

**Segredos nunca entram no repositório.** Nenhuma API key, token, `.credentials.json`, `auth.json` ou sessão viva é versionada. Quando a instalação chega num ponto que exige autenticação (Claude Code, Codex, GitHub, etc.), o script **para e instrui o usuário a rodar o comando de login manualmente** (ex.: `claude login`, `codex login`, `gh auth login`) antes de continuar.

O **MVP** cobre: instalação de PHP (versões alvo do projeto: 8.2, 8.3, 8.4, 8.5, via PPA `ondrej/php`) + Composer, Node.js (versão mais recente LTS/stable disponível) via gerenciador padrão, Docker (Engine + Compose plugin), Claude Code CLI e Codex CLI (última versão disponível), cópia de dotfiles (`.bashrc`, `.bashrc_aliases`, funções e aliases customizados), e cópia seletiva de configs de `.claude/` e `.codex/` (excluindo dados sensíveis, sessões, histórico, cache e credenciais). Fora do MVP: sincronização automática/contínua entre máquinas, suporte a distro diferente de Ubuntu/Debian, suporte a múltiplos usuários simultâneos na mesma máquina de destino.

### Key Concepts

- **Bootstrap script:** script de entrada (`install.sh`) que orquestra a instalação completa numa máquina nova, do zero até ambiente utilizável.
- **Módulo de instalação:** unidade de instalação isolada e idempotente (ex.: `php.sh`, `node.sh`, `docker.sh`, `claude-code.sh`, `codex.sh`, `dotfiles.sh`) — pode ser re-executada sem duplicar efeito (usa checks tipo "já instalado? já existe o link?").
- **Dotfile:** arquivo de configuração de shell/ferramenta que vive no `$HOME` (`.bashrc`, `.bashrc_aliases`, etc.) — versionado no repo e copiado/linkado para o `$HOME` do usuário de destino.
- **Config sensível:** qualquer arquivo com credencial, token, chave, sessão viva ou dado pessoal identificável (`.credentials.json`, `auth.json`, `history.jsonl`, `sessions/`, `session-env/`) — **nunca** versionado; explicitamente listado em exclusão.
- **Config replicável:** parte de `.claude/` e `.codex/` que é preferência/comportamento (settings.json sem segredos, skills, agents, commands, hooks, CLAUDE.md, AGENTS.md) — essa sim é versionada e copiada.
- **Versão pinada (PHP):** o projeto fixa a lista de versões de PHP a instalar em 8.2, 8.3, 8.4 e 8.5 (nesta máquina hoje só 8.2/8.3/8.4 estão instaladas; 8.5 entra no bootstrap mesmo sem estar instalada aqui ainda), todas via PPA `ondrej/php`, com `update-alternatives` configurado do mesmo jeito.
- **Extensões por versão (replicadas como estão, não padronizadas):** cada versão de PHP instala exatamente o conjunto de extensões que tem hoje nesta máquina — não é um conjunto único igual pra todas.
  - **8.2:** `cli`, `fpm`, `bz2`, `curl`, `gd`, `imagick`, `intl`, `mbstring`, `mysql` (mysqli + pdo_mysql), `opcache`, `readline`, `xml`, `zip`.
  - **8.3:** `cli`, `fpm`, `bcmath`, `bz2`, `curl`, `intl`, `mbstring`, `mysql`, `opcache`, `readline`, `xml`, `zip` (sem gd/imagick/pgsql/sqlite).
  - **8.4:** `cli`, `fpm`, `bcmath`, `curl`, `intl`, `mbstring`, `mysql`, `opcache`, `pgsql`, `readline`, `sqlite3`, `xml`, `zip` (sem gd/imagick).
  - **8.5:** sem referência local (não instalada nesta máquina); instalar com o conjunto base do pacote (`cli`, `fpm`, `common`) + extensões que o desenvolvedor confirmar quando a versão entrar em uso real.
- **Xdebug (fora do bootstrap padrão):** hoje só existe na 8.2 desta máquina. Não entra na instalação automática de nenhuma versão (evita overhead de performance por padrão); fica documentado como passo manual opcional (`apt install php<versão>-xdebug`) quando o desenvolvedor precisar debugar.
- **`php.ini` sem override customizado:** `memory_limit`, `upload_max_filesize`, `post_max_size` e `max_execution_time` são iguais nas 3 versões instaladas e batem com o default do pacote Ubuntu/ondrej — o bootstrap não precisa aplicar override nenhum nesses valores, só instalar o pacote.
- **Distro alvo:** script detecta em tempo de execução o codename Ubuntu (`24.04` ou `26.04`, via `lsb_release`/`/etc/os-release`) e ajusta a URL da PPA `ondrej/php` e demais fontes conforme o codename detectado — nada hardcoded para "noble" apenas.
- **Última versão disponível (demais ferramentas):** Node.js, Composer, Docker, Claude Code CLI, Codex CLI são instalados sempre na versão mais recente disponível no momento da execução — não são fixados a um número de versão específico.

## Tech Stack

| Layer | Technology |
|---|---|
| Scripting | Bash/POSIX `sh`, scripts idempotentes, sem dependências além de utilitários padrão do Ubuntu |
| SO alvo | Ubuntu 24.04 LTS e 26.04 LTS (compatível WSL2 e bare metal), codename detectado em runtime |
| Gerenciador de pacotes | `apt` + PPA `ondrej/php` para múltiplas versões de PHP, resolvida por codename detectado |
| Runtime PHP | PHP 8.2, 8.3, 8.4, 8.5 (todas via PPA ondrej, `update-alternatives`) + Composer (última versão) |
| Runtime Node | Node.js (última LTS/stable) + npm |
| Containers | Docker Engine + Docker Compose plugin (última versão) |
| CLIs de IA | Claude Code CLI (última versão), Codex CLI (última versão) |
| Controle de versão | Git, repositório remoto privado (GitHub/GitLab) |
| Distribuição | `git clone` do repo privado na máquina nova + execução de `install.sh` |
| Gestão de segredos | Nenhum segredo no repo; login manual pós-instalação para cada ferramenta que exige autenticação |

## Core Workflows

### 1. Setup inicial de uma máquina nova

1. Usuário faz `git clone` do repositório privado na máquina nova (usuário diferente, `$HOME` diferente).
2. Usuário roda `./install.sh` (ou módulos individuais, ex.: `./install/php.sh`).
3. Script detecta a versão/codename do Ubuntu (24.04 ou 26.04); se for outra versão/distro, avisa e para em vez de seguir arriscado.
4. Script detecta o que já está instalado e pula etapas já satisfeitas (idempotência) — pode ser re-executado sem efeito colateral.
5. Script instala, na ordem: dependências base de sistema → PHP 8.2/8.3/8.4 + Composer → Node.js (última) → Docker Engine + Compose → Claude Code CLI → Codex CLI.
6. Script copia/linka dotfiles (`.bashrc`, `.bashrc_aliases`) e configs replicáveis de `.claude/` e `.codex/` para o `$HOME` do usuário atual (detectado via `$HOME`/`$USER` em tempo de execução, nunca hardcoded).
7. Ao chegar em um passo que exige autenticação (Claude Code, Codex, Docker Hub se aplicável, `gh`), o script **para**, imprime instrução clara do comando manual a rodar (ex.: `claude login`), e aguarda o usuário confirmar antes de seguir — ou finaliza a etapa e informa que autenticação é passo manual pendente.
8. Ao final, script imprime um resumo do que foi instalado/copiado e o que ainda precisa de ação manual (logins pendentes).

### 2. Atualização de um módulo isolado

1. Usuário identifica que só quer atualizar/reinstalar uma parte (ex.: só PHP, ou só dotfiles).
2. Roda o módulo individual (`./install/php.sh`, `./install/dotfiles.sh`, etc.) diretamente, sem passar pelo `install.sh` completo.
3. Módulo aplica o mesmo check de idempotência do fluxo completo — seguro rodar quantas vezes for preciso.

### 3. Exportar/curar o que sai desta máquina para o repo

1. Desenvolvedor decide que uma nova config/alias/função passou a fazer parte do setup padrão.
2. Copia manualmente o trecho relevante para o arquivo versionado correspondente no repo (ex.: nova função vai para `dotfiles/bashrc_aliases`).
3. Antes de commitar, revisa que nenhum segredo, caminho pessoal específico desta máquina, ou dado sensível foi incluído.
4. Commita e faz push para o repositório remoto privado.
