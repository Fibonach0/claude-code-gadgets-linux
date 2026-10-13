# comun.sh — lo que comparten los gadgets en Linux.
#
# No es un script: lo cargan los demás con `source`. Trae:
#   notificar <título> <texto> [sonido]     aviso de escritorio + sonido
#   hablar <texto>                          lo lee en voz alta
#   abrir <archivo|carpeta|url>             con la aplicación que corresponda
#   timer_instalar / timer_desinstalar      trabajos programados (systemd --user)
#   en_silencio                             horario de no molestar (silencio.sh)
#   $DOCS                                   tu carpeta de Documentos (XDG)

_aqui=$(dirname "${BASH_SOURCE[0]}")
[ -f "$_aqui/silencio.sh" ] && . "$_aqui/silencio.sh"

# Desde un timer o por SSH no siempre están las variables de la sesión gráfica.
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"; export XDG_RUNTIME_DIR
[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "$XDG_RUNTIME_DIR/bus" ] \
  && export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

DOCS=$(xdg-user-dir DOCUMENTS 2>/dev/null); [ -d "$DOCS" ] && [ "$DOCS" != "$HOME" ] || { [ -d "$HOME/Documents" ] && DOCS="$HOME/Documents" || DOCS="$HOME/Documentos"; }

sonar() {  # aviso | listo | error | ok | alerta | recordatorio
  local s
  case "${1:-}" in
    aviso) s=message-new-instant ;;  listo) s=complete ;;        error) s=dialog-error ;;
    ok)    s=message ;;              alerta) s=dialog-warning ;; recordatorio) s=bell ;;
    *) return 0 ;;
  esac
  local f=/usr/share/sounds/freedesktop/stereo/$s.oga
  if   [ -f "$f" ] && command -v paplay  >/dev/null; then paplay  "$f" >/dev/null 2>&1 &
  elif [ -f "$f" ] && command -v pw-play >/dev/null; then pw-play "$f" >/dev/null 2>&1 &
  elif command -v canberra-gtk-play >/dev/null; then canberra-gtk-play -i "$s" >/dev/null 2>&1 &
  fi
  disown 2>/dev/null
}

notificar() {  # título, texto[, sonido]
  # En segundo plano: ni un hook ni un timer deben quedar colgados esperando.
  if command -v notify-send >/dev/null; then
    notify-send -a "Claude Code" -i dialog-information -- "$1" "${2:-}" >/dev/null 2>&1 &
    disown 2>/dev/null
  fi
  sonar "${3:-}"
}

hablar() {  # usa BRIEF_VOZ si está definida (voz de speech-dispatcher o de espeak-ng)
  if   command -v spd-say   >/dev/null; then spd-say -w -l es ${BRIEF_VOZ:+-y "$BRIEF_VOZ"} -- "$1"
  elif command -v espeak-ng >/dev/null; then espeak-ng -v "${BRIEF_VOZ:-es-419}" -- "$1"
  else echo "Para leer en voz alta hace falta speech-dispatcher o espeak-ng (sudo apt install espeak-ng)."; return 1
  fi
}

abrir() { xdg-open "$1" >/dev/null 2>&1 & disown 2>/dev/null; }

# ── Trabajos programados: unidades de systemd del usuario ────────────────────
#   timer_instalar <nombre> cada:<segundos> [argumentos…]
#   timer_instalar <nombre> hora:<HH:MM>    [argumentos…]
# Corre ~/.claude/gadgets/bin/claude-<nombre> con esos argumentos. Si
# TIMER_VIGILAR tiene una carpeta, además corre cada vez que cambia.
_unidades="$HOME/.config/systemd/user"

timer_instalar() {
  local nombre=$1 cuando=$2; shift 2
  command -v systemctl >/dev/null && systemctl --user show-environment >/dev/null 2>&1 || {
    echo "No hay systemd de usuario en esta sesión: no puedo programar claude-$nombre."
    echo "Podés ponerlo en tu crontab: $HOME/.claude/gadgets/bin/claude-$nombre $*"; return 1; }
  local u="claude-gadgets-$nombre" args="" a
  for a in "$@"; do args+=" $a"; done
  mkdir -p "$_unidades" "$HOME/.claude/estado"
  cat > "$_unidades/$u.service" <<UNIDAD
[Unit]
Description=Claude Code Gadgets: $nombre

[Service]
Type=oneshot
ExecStart=%h/.claude/gadgets/bin/claude-$nombre$args
StandardError=append:%h/.claude/estado/$nombre.err
UNIDAD
  {
    printf '[Unit]\nDescription=Claude Code Gadgets: %s\n\n[Timer]\n' "$nombre"
    case "$cuando" in
      cada:*) printf 'OnActiveSec=15\nOnUnitActiveSec=%s\nAccuracySec=15\n' "${cuando#cada:}" ;;
      hora:*) printf 'OnCalendar=*-*-* %s:00\nPersistent=true\n' "${cuando#hora:}" ;;
      *) echo "timer_instalar: no entiendo «$cuando»" >&2; return 1 ;;
    esac
    printf '\n[Install]\nWantedBy=timers.target\n'
  } > "$_unidades/$u.timer"
  systemctl --user disable --now "$u.path" >/dev/null 2>&1   # por si antes vigilaba una carpeta
  rm -f "$_unidades/$u.path"
  if [ -n "${TIMER_VIGILAR:-}" ]; then
    printf '[Unit]\nDescription=Claude Code Gadgets: %s (carpeta)\n\n[Path]\nPathChanged=%s\nUnit=%s.service\n\n[Install]\nWantedBy=default.target\n' \
      "$nombre" "${TIMER_VIGILAR//%/%%}" "$u" > "$_unidades/$u.path"
  fi
  systemctl --user daemon-reload || return 1
  systemctl --user enable --now "$u.timer" >/dev/null 2>&1 || return 1
  [ -f "$_unidades/$u.path" ] && { systemctl --user enable "$u.path" >/dev/null 2>&1; systemctl --user restart "$u.path" || return 1; }
  return 0
}

timer_desinstalar() {
  local u="claude-gadgets-$1" x
  # De a una: si alguna no existe, las demás se apagan igual.
  for x in timer path service; do
    systemctl --user disable --now "$u.$x" >/dev/null 2>&1
    systemctl --user stop "$u.$x" >/dev/null 2>&1
  done
  rm -f "$_unidades/$u.service" "$_unidades/$u.timer" "$_unidades/$u.path"
  systemctl --user daemon-reload >/dev/null 2>&1
  systemctl --user reset-failed "$u.timer" "$u.path" "$u.service" >/dev/null 2>&1
  return 0
}
