# config-linux — Database Schema

<!-- inputs: project-description.md@sha256:580c3eda7e10 user-stories.md@sha256:144a307ac271 -->

## Overview

**config-linux não tem banco de dados.** É um conjunto de scripts shell idempotentes que instalam pacotes de sistema e copiam/linkam arquivos de configuração no `$HOME` — não existe camada de persistência, ORM, nem framework de aplicação. Todo "estado" do projeto vive em três lugares: **arquivos versionados no repo** (dotfiles, configs replicáveis, os próprios scripts), **estado do sistema operacional de destino** (pacotes apt instalados, `update-alternatives`, arquivos em `$HOME`), e **arquivos de marcação de execução opcionais** no filesystem (ex.: log/flag de que um módulo já rodou), usados só para a checagem de idempotência local — nunca um banco.

Nenhum Key Concept do projeto (bootstrap script, módulo de instalação, dotfile, config sensível/replicável, versões de PHP, extensões, xdebug, distro alvo) é modelado como tabela. Este documento existe apenas para fechar a cadeia `/bc-harness:init` — não há schema a declarar.

## Schema (DBML)

```dbml
// Sem banco de dados neste projeto — nenhuma Table declarada.
// Ver "Notes & Conventions" para onde cada Key Concept realmente vive.
```

## Relationships

- Não há relacionamentos de banco — não há banco.

## Lookup Table Seeds

- Não aplicável — não há lookup tables.

## Notes & Conventions

- **Bootstrap script / Módulo de instalação:** vivem como arquivos `.sh` versionados no repositório (`install.sh`, `install/*.sh`) — não persistidos em banco.
- **Dotfile / Config replicável:** vivem como arquivos versionados no repo (`dotfiles/`, configs de `.claude/`/`.codex/`) e são copiados/linkados para `$HOME` na máquina de destino.
- **Config sensível:** nunca é persistida em lugar nenhum do projeto — explicitamente excluída via `.gitignore`/lista de exclusão (US-3.2).
- **Versão pinada (PHP), extensões por versão, xdebug fora do bootstrap, `php.ini` sem override, distro alvo:** são todos **parâmetros fixos nos próprios scripts** (variáveis/arrays no shell script do módulo `php.sh`), não dados de configuração dinâmica nem registros de banco.
- **Idempotência (US-2.1):** se o projeto precisar de "memória" de execução (ex.: marcar que um módulo já rodou), isso é um arquivo simples no filesystem de destino (ex.: `~/.config/config-linux/state`), não um banco — fora do escopo deste documento por não ser um schema relacional.

## Coverage — Key Concepts → Tables

| Key Concept | Table(s) |
|---|---|
| Bootstrap script | — not persisted: vive como arquivo `.sh` versionado no repo |
| Módulo de instalação | — not persisted: vive como arquivo `.sh` versionado no repo |
| Dotfile | — not persisted: vive como arquivo versionado no repo, copiado pro `$HOME` |
| Config sensível | — not persisted: excluída por design, nunca versionada nem armazenada |
| Config replicável | — not persisted: vive como arquivo versionado no repo |
| Versão pinada (PHP) | — not persisted: constante fixa no script `php.sh` |
| Extensões por versão | — not persisted: constante fixa no script `php.sh` |
| Xdebug (fora do bootstrap padrão) | — not persisted: comportamento fixo do script, não dado |
| `php.ini` sem override customizado | — not persisted: ausência de ação é a própria regra |
| Distro alvo | — not persisted: detectada em runtime via `lsb_release`/`/etc/os-release`, nunca armazenada |
| Última versão disponível (demais ferramentas) | — not persisted: resolvida em runtime contra o repositório do pacote/PPA |
