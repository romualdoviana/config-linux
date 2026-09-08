# config-linux

Bootstrap idempotente de máquina de desenvolvimento (Ubuntu 24.04/26.04).

## Como levar uma config nova pro repo

Quando uma nova config, alias ou função passa a fazer parte do setup padrão desta máquina:

1. Copie manualmente o trecho relevante para o arquivo versionado correspondente no repo (ex.: nova função de shell vai para `dotfiles/bashrc_aliases`; preferência/comportamento de `.claude/`/`.codex/` vai pra config replicável equivalente dentro do repo).
2. **Revise visualmente o diff antes de commitar** — confirme que nenhum segredo, token, sessão viva, caminho pessoal específico desta máquina ou dado sensível foi incluído (ver `.gitignore` na raiz para os padrões que já são bloqueados automaticamente).
3. Commit e push pro repositório remoto privado.

## Debug (xdebug) — manual

O xdebug não entra na instalação automática de nenhuma versão de PHP (evita
overhead de performance por padrão). Quando precisar debugar, instale
manualmente pra versão em uso:

```bash
sudo apt install php<versão>-xdebug
```

Exemplo pra PHP 8.2:

```bash
sudo apt install php8.2-xdebug
```
