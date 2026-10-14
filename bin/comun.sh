# comun.sh — lo que comparten los gadgets en Linux.
#
# No es un script: lo cargan los demás con `source`. Trae:
#   notificar <título> <texto> [sonido]     aviso de escritorio + sonido (y al celular si no estás)
#   al_celular <título> <texto>             aviso al teléfono por ntfy (si hay NTFY_TEMA)
#   ausente                                 ¿la compu está bloqueada o sin uso hace rato?
#   hablar <texto>                          lo lee en voz alta
#   abrir <archivo|carpeta|url>             con la aplicación que corresponda
#   timer_instalar / timer_desinstalar      trabajos programados (systemd --user)
#   claude_texto <modelo> <pedido>          respuesta de Claude sin herramientas
#   copiar / pegar                          portapapeles (pegar: primero lo seleccionado)
#   ventana <título> <archivo>              muestra un texto, con botón Copiar
#   atajo_instalar / atajo_desinstalar      atajos de teclado (GNOME)
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
  # Si no estás en la compu, el aviso de escritorio no lo ve nadie: va al teléfono.
  if [ -n "${NTFY_TEMA:-}" ] && { [ "${NTFY_SIEMPRE:-0}" = 1 ] || ausente; }; then al_celular "$1" "${2:-}"; fi
  return 0
}

# ── Avisos al celular (ntfy) ─────────────────────────────────────────────────
# Se prende con `claude-celular --instalar`, que define NTFY_TEMA en la config.
ocio_seg() {  # segundos sin tocar teclado ni mouse; falla si no lo puede saber
  local v
  v=$(gdbus call --session --dest org.gnome.Mutter.IdleMonitor --object-path /org/gnome/Mutter/IdleMonitor/Core \
        --method org.gnome.Mutter.IdleMonitor.GetIdletime 2>/dev/null | grep -o '[0-9]\+' | tail -1)
  [ -n "$v" ] && { echo $((v / 1000)); return 0; }
  v=$(gdbus call --session --dest org.freedesktop.ScreenSaver --object-path /org/freedesktop/ScreenSaver \
        --method org.freedesktop.ScreenSaver.GetSessionIdleTime 2>/dev/null | grep -o '[0-9]\+' | tail -1)   # KDE
  [ -n "$v" ] && { echo $((v / 1000)); return 0; }
  command -v xprintidle >/dev/null && v=$(xprintidle 2>/dev/null) && [ -n "$v" ] && { echo $((v / 1000)); return 0; }
  return 1
}

ausente() {  # bloqueada, sin sesión gráfica, o sin uso hace NTFY_OCIO minutos (3 por defecto)
  local s o
  s=$(loginctl show-user "$(id -un)" -p Display --value 2>/dev/null)
  [ -n "$s" ] || return 0
  [ "$(loginctl show-session "$s" -p LockedHint --value 2>/dev/null)" = yes ] && return 0
  o=$(ocio_seg) || return 1
  [ "$o" -ge $(( ${NTFY_OCIO:-3} * 60 )) ]
}

al_celular() {  # título, texto
  [ -n "${NTFY_TEMA:-}" ] && command -v curl >/dev/null && command -v jq >/dev/null || return 1
  local cuerpo
  cuerpo=$(jq -nc --arg t "$NTFY_TEMA" --arg ti "$1" --arg m "${2:-}" '{topic: $t, title: $ti, message: $m, tags: ["sparkles"]}')
  set -- curl -fsS -m 10 ${NTFY_TOKEN:+-H "Authorization: Bearer $NTFY_TOKEN"} -H "Content-Type: application/json" \
    -d "$cuerpo" "${NTFY_SERVIDOR:-https://ntfy.sh}"
  if [ -n "${NTFY_ESPERAR:-}" ]; then "$@" >/dev/null; return; fi   # claude-celular "texto": quiere saber si llegó
  "$@" >/dev/null 2>&1 &
  disown 2>/dev/null
}

hablar() {  # usa BRIEF_VOZ si está definida (voz de speech-dispatcher o de espeak-ng)
  if   command -v spd-say   >/dev/null; then spd-say -w -l es ${BRIEF_VOZ:+-y "$BRIEF_VOZ"} -- "$1"
  elif command -v espeak-ng >/dev/null; then espeak-ng -v "${BRIEF_VOZ:-es-419}" -- "$1"
  else echo "Para leer en voz alta hace falta speech-dispatcher o espeak-ng (sudo apt install espeak-ng)."; return 1
  fi
}

abrir() { xdg-open "$1" >/dev/null 2>&1 & disown 2>/dev/null; }

claude_texto() {  # modelo, pedido → lo que conteste, sin herramientas ni sesión guardada
  claude -p "$2" --no-session-persistence --model "$1" --permission-mode dontAsk --allowedTools "" </dev/null 2>/dev/null
}

# ── Portapapeles ─────────────────────────────────────────────────────────────
copiar() {  # lee de la entrada
  if   [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-copy >/dev/null; then wl-copy
  elif command -v xclip >/dev/null; then xclip -selection clipboard
  elif command -v xsel  >/dev/null; then xsel -b
  else cat >/dev/null; return 1; fi
}
pegar() {  # lo que tengas seleccionado; si no hay nada, lo último que copiaste
  local t=""
  if [ -n "${WAYLAND_DISPLAY:-}" ] && command -v wl-paste >/dev/null; then
    t=$(wl-paste -p -n 2>/dev/null); [ -n "$t" ] || t=$(wl-paste -n 2>/dev/null)
  elif command -v xclip >/dev/null; then
    t=$(xclip -o -selection primary 2>/dev/null); [ -n "$t" ] || t=$(xclip -o -selection clipboard 2>/dev/null)
  elif command -v xsel >/dev/null; then
    t=$(xsel -p 2>/dev/null); [ -n "$t" ] || t=$(xsel -b 2>/dev/null)
  else return 1; fi
  printf '%s' "$t"
}

ventana() {  # título, archivo de texto
  local r
  if command -v zenity >/dev/null; then
    r=$(zenity --text-info --title="$1" --width=700 --height=460 --filename="$2" \
          --ok-label=Cerrar --extra-button=Copiar 2>/dev/null)
    [ "$r" = Copiar ] && copiar < "$2" && notificar "Claude" "Copiado"
  elif command -v kdialog >/dev/null; then kdialog --title "$1" --textbox "$2" 700 460 2>/dev/null
  else abrir "$2"; fi
  return 0
}

# ── Atajos de teclado (GNOME) ────────────────────────────────────────────────
#   atajo_instalar <id> <nombre> <comando> <atajo>     p. ej. '<Shift><Super>c'
_at_esq=org.gnome.settings-daemon.plugins.media-keys
_at_ruta() { echo "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/claude-$1/"; }
atajo_instalar() {
  local r lista; r=$(_at_ruta "$1")
  command -v gsettings >/dev/null && gsettings list-keys $_at_esq >/dev/null 2>&1 || {
    echo "Los atajos los armo sólo en GNOME. En tu escritorio, asigná uno a: $3"; return 1; }
  lista=$(gsettings get $_at_esq custom-keybindings)
  case "$lista" in
    *"'$r'"*) ;;
    "@as []"|"[]") gsettings set $_at_esq custom-keybindings "['$r']" ;;
    *) gsettings set $_at_esq custom-keybindings "${lista%]}, '$r']" ;;
  esac
  gsettings set $_at_esq.custom-keybinding:$r name "$2"
  gsettings set $_at_esq.custom-keybinding:$r command "$3"
  gsettings set $_at_esq.custom-keybinding:$r binding "$4"
}
atajo_desinstalar() {
  local r lista nueva k; r=$(_at_ruta "$1")
  command -v gsettings >/dev/null || return 0
  lista=$(gsettings get $_at_esq custom-keybindings 2>/dev/null) || return 0
  case "$lista" in *"'$r'"*)
    nueva=$(sed "s|, '$r'||; s|'$r', ||; s|'$r'||" <<<"$lista"); [ "$nueva" = "[]" ] && nueva="@as []"
    gsettings set $_at_esq custom-keybindings "$nueva"
    for k in name command binding; do gsettings reset $_at_esq.custom-keybinding:$r $k; done ;;
  esac
  return 0
}

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
  local u="claude-gadgets-$1" x yo=
  # Si lo llama el propio servicio (p. ej. recordar sin pendientes), no hay que
  # pararlo: systemd lo mataría antes de terminar de limpiar.
  grep -q "/$u.service" /proc/self/cgroup 2>/dev/null && yo=1
  # De a una: si alguna no existe, las demás se apagan igual.
  for x in timer path ${yo:+_}service; do
    [ "$x" = _service ] && continue
    systemctl --user disable --now "$u.$x" >/dev/null 2>&1
    systemctl --user stop "$u.$x" >/dev/null 2>&1
  done
  rm -f "$_unidades/$u.service" "$_unidades/$u.timer" "$_unidades/$u.path"
  systemctl --user daemon-reload >/dev/null 2>&1
  systemctl --user reset-failed "$u.timer" "$u.path" "$u.service" >/dev/null 2>&1
  return 0
}
