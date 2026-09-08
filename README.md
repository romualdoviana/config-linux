# Linux Dev Configuration

Configuração de máquina de desenvolvimento Linux (Ubuntu 24.04 e 26.04). Um `git clone` + `./install.sh` deixa a máquina pronta com PHP (múltiplas versões), Node.js, Docker, Claude Code CLI e Codex CLI, além de dotfiles e configs replicadas — sem nunca versionar segredo nenhum.

Feito pra uso pessoal em troca de máquina/reinstalação. Sinta-se livre pra fazer fork e adaptar pro seu próprio setup (ver [LICENSE](LICENSE)).

## O que faz

- Detecta o codename do Ubuntu (`/etc/os-release`) e recusa rodar em distro/versão não suportada, em vez de seguir arriscado.
- Instala tudo de forma **idempotente**: rodar `./install.sh` de novo a qualquer momento não duplica nem quebra nada, só completa o que falta.
- **Para na hora** se qualquer módulo falhar — nunca deixa a máquina "meio instalada" em silêncio.
- **Nenhum segredo entra no repositório.** Login de ferramentas que exigem autenticação (Claude Code, Codex) é sempre um passo manual, sinalizado no resumo final.

## Requisitos

- Ubuntu 24.04 (noble) ou 26.04 (resolute), WSL2 ou bare metal.
- `bash`, `apt`, `sudo`.
- `shellcheck` e [`bats-core`](https://github.com/bats-core/bats-core) só se for rodar lint/testes localmente.

## Uso

```bash
git clone https://github.com/<seu-usuario>/config-linux.git
cd config-linux
./install.sh
```

Ao final, o script imprime um resumo com o status de cada módulo (instalado / já estava instalado / falhou) e a lista de logins manuais pendentes, se houver.

### Rodando um módulo isolado

Cada módulo é autocontido e pode rodar sozinho, sem passar pelo `install.sh` inteiro:

```bash
./install/php.sh
./install/dotfiles.sh
```

### Módulos (ordem de execução)

| Módulo | O que instala |
|---|---|
| `install/php.sh` | PHP 8.2, 8.3, 8.4 e 8.5 via PPA [`ondrej/php`](https://launchpad.net/~ondrej/+archive/ubuntu/php), com um conjunto de extensões próprio por versão |
| `install/node.sh` | Node.js na versão mais recente disponível |
| `install/docker.sh` | Docker Engine + Compose plugin |
| `install/claude-code.sh` | [Claude Code CLI](https://claude.com/claude-code) (login via `claude login` fica manual) |
| `install/codex.sh` | Codex CLI (login via `codex login` fica manual) |
| `install/dotfiles.sh` | Dotfiles (`.bashrc_aliases`) e config replicável de `.claude`/`.codex` |

### Debug (xdebug) — manual

Xdebug não entra na instalação automática de nenhuma versão de PHP (evita overhead de performance por padrão). Quando precisar debugar, instale manualmente pra versão em uso:

```bash
sudo apt install php8.2-xdebug
```

## Testes e lint

```bash
./scripts/lint.sh   # shellcheck em todo .sh versionado
./scripts/test.sh   # suíte bats em tests/
```

## Estrutura

```
install.sh          # orquestrador: detecta distro, roda os módulos em ordem, imprime resumo
install/             # um script por módulo, idempotente e executável sozinho
lib/                 # biblioteca compartilhada (log/erro, detecção de distro, idempotência)
dotfiles/             # dotfiles versionados, copiados pro $HOME na instalação
tests/               # suíte bats-core
scripts/             # lint.sh e test.sh
```

## Contribuindo com o próprio setup

Quando uma config, alias ou função nova passa a fazer parte do setup padrão:

1. Copie o trecho pro arquivo versionado correspondente (ex.: nova função de shell vai pra `dotfiles/bashrc_aliases`; preferência de `.claude`/`.codex` vai pra config replicável equivalente).
2. **Revise o diff antes de commitar** — confirme que nenhum segredo, token, sessão viva ou caminho pessoal da máquina foi incluído (o `.gitignore` já bloqueia os padrões conhecidos de config sensível).
3. Commit e push.

## Licença

[MIT](LICENSE).
