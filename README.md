# config-linux

Bootstrap idempotente de máquina de desenvolvimento (Ubuntu 24.04/26.04).

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
