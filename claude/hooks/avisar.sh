#!/bin/bash
# Hook de avisos: notificación + sonido en el escritorio, y deja el estado de
# cada sesión en ~/.claude/estado/ para el indicador de la bandeja.
# Uso: avisar.sh <prompt|necesita|listo|fin>   (JSON del hook por stdin)
evento="$1"
input=$(cat)
[ -f ~/.config/claude-gadgets/config ] && . ~/.config/claude-gadgets/config
[ -f $HOME/.claude/gadgets/bin/comun.sh ] && . $HOME/.claude/gadgets/bin/comun.sh   # avisos y no molestar
sid=$(jq -r '.session_id // "x"' <<<"$input")
cwd=$(jq -r '.cwd // ""' <<<"$input")
msg=$(jq -r '.message // empty' <<<"$input")
proyecto=$(basename "${cwd:-?}")
dir=~/.claude/estado; mkdir -p "$dir"
f="$dir/sesion-$sid.json"

guardar() { jq -n --arg e "$1" --arg p "$proyecto" --arg c "$cwd" --arg m "$msg" \
  '{estado:$e, proyecto:$p, cwd:$c, mensaje:$m, ts:(now|floor)}' > "$f"; }

# Sólo aviso si no estás mirando la terminal donde corre Claude. Eso se puede
# saber en X11 (la ventana activa contra $WINDOWID); en Wayland el escritorio no
# le cuenta a nadie qué ventana tiene el foco, así que ahí aviso siempre.
mirando() {
  [ "${XDG_SESSION_TYPE:-}" = x11 ] && [ -n "${WINDOWID:-}" ] && command -v xprop >/dev/null || return 1
  local activa
  activa=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | grep -oE '0x[0-9a-fA-F]+' | head -1)
  [ -n "$activa" ] && [ "$((activa))" = "$WINDOWID" ]
}
avisar() {  # titulo, texto, sonido[, "urgente"]
  mirando && return
  # En horario de silencio sólo pasa lo que te está bloqueando.
  declare -f en_silencio >/dev/null && en_silencio "${4:-}" && return
  declare -f notificar >/dev/null && notificar "$1" "$2" "$3"
}

case "$evento" in
  prompt)   guardar trabajando ;;
  necesita) guardar esperando; avisar "Claude · $proyecto" "${msg:-Te necesita}" aviso urgente ;;
  listo)    guardar listo;     avisar "Claude · $proyecto" "Terminó" listo ;;
  fin)      rm -f "$f" ;;
esac
# Limpio sesiones viejas (más de 1 día sin actividad).
find "$dir" -name 'sesion-*.json' -mtime +1 -delete 2>/dev/null
exit 0
