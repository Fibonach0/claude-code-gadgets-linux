# Claude Code Gadgets en la terminal (bash). Lo carga tu ~/.bashrc.
#   ups              por qué falló el último comando y cómo arreglarlo
#   Ctrl+G           escribís en castellano lo que querés hacer y la línea se
#                    cambia por el comando (no lo ejecuta: lo revisás vos)
#   … | explica      atajo de claude-explica
case $- in *i*) ;; *) return 0 2>/dev/null ;; esac

alias explica=claude-explica

# Guardo el código de salida del último comando para `ups`.
__claude_guardar() { __claude_ult=$?; }
case ";${PROMPT_COMMAND:-};" in
  *";__claude_guardar;"*) ;;
  *) PROMPT_COMMAND="__claude_guardar${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

ups() {
  local codigo=${__claude_ult:-0} cmd salida
  cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
  [ -n "$cmd" ] || { echo "No hay comando anterior."; return 1; }
  if [ "${1:-}" = -r ]; then      # -r: lo corre de nuevo para leer el error (¡sólo si es seguro repetirlo!)
    salida=$(eval "$cmd" 2>&1 | tail -c 20000)
  fi
  printf 'Comando: %s\nCódigo de salida: %s\n%s\n' "$cmd" "$codigo" "${salida:+Salida:
$salida}" | EXPLICA_CONTEXTO="carpeta $PWD" claude-explica "Este comando falló. ¿Por qué y cómo lo arreglo? Si con estos datos no alcanza, decime qué mirar."
}

__claude_como() {
  [ -n "${READLINE_LINE// /}" ] || return
  local pedido=$READLINE_LINE cmd
  printf '\r\033[2m✳ pensando el comando…\033[0m\033[K' >&2
  cmd=$(claude-como "$pedido")
  printf '\r\033[K' >&2
  [ -n "$cmd" ] || return
  history -s "# $pedido"          # el pedido queda en el historial, por si querés reformularlo
  READLINE_LINE=$cmd; READLINE_POINT=${#cmd}
}
bind -x '"\C-g": __claude_como' 2>/dev/null
