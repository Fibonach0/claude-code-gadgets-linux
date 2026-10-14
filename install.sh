#!/bin/bash
# Claude Code Gadgets — instalador para Linux (Debian, Ubuntu y derivados).
#   ./install.sh                 instala todo
#   ./install.sh --con-permisos  además permite comandos de sólo lectura sin preguntar
#   ./install.sh --sin-barra     no instala el indicador de la bandeja
#   ./install.sh --sin-archivos  no instala «Preguntarle a Claude» en el administrador de archivos
#   ./install.sh --sin-ulauncher no instala la extensión de Ulauncher
#   ./install.sh --sin-terminal  no toca tu ~/.bashrc (Ctrl+G, ups, explica)
#   ./install.sh --sin-gnome     no instala la extensión de GNOME Shell (foco en Wayland)
# Se puede correr de nuevo sin problema: reemplaza lo suyo y no toca lo demás.
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
GADGETS="$CLAUDE_DIR/gadgets"
SETTINGS="$CLAUDE_DIR/settings.json"
CONF_DIR="$HOME/.config/claude-gadgets"

CON_PERMISOS=0; SIN_BARRA=0; SIN_ARCHIVOS=0; SIN_ULAUNCHER=0; SIN_GNOME=0; SIN_TERMINAL=0
for a in "$@"; do case "$a" in
  --con-permisos) CON_PERMISOS=1 ;;
  --sin-barra)    SIN_BARRA=1 ;;
  --sin-archivos|--sin-finder) SIN_ARCHIVOS=1 ;;
  --sin-ulauncher) SIN_ULAUNCHER=1 ;;
  --sin-gnome)     SIN_GNOME=1 ;;
  --sin-terminal)  SIN_TERMINAL=1 ;;
  -h|--help) sed -n 2,10p "$0"; exit 0 ;;
  *) echo "Opción desconocida: $a"; exit 1 ;;
esac; done

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
paso() { printf '\n\033[1m%s\033[0m\n' "$*"; }
ojo()  { printf '  \033[33m!\033[0m %s\n' "$*"; }

[ "$(uname)" = Linux ] || { echo "Esto es para Linux. Para la Mac: claude-code-gadgets-macos."; exit 1; }

# ── 1. Dependencias ──────────────────────────────────────────────────────────
paso "1. Dependencias"
command -v claude >/dev/null || [ -x "$HOME/.local/bin/claude" ] \
  || ojo "No encontré Claude Code. Instalalo primero: https://claude.com/claude-code"
# No instalo paquetes del sistema por mi cuenta: digo cuáles faltan y cómo ponerlos.
faltan=()
necesita() { command -v "$1" >/dev/null || faltan+=("$2"); }   # comando, paquete
necesita jq jq; necesita curl curl; necesita git git; necesita python3 python3
necesita notify-send libnotify-bin; necesita rsync rsync
[ $SIN_ARCHIVOS = 0 ] && { command -v zenity >/dev/null || command -v kdialog >/dev/null || faltan+=(zenity); }
if [ $SIN_BARRA = 0 ]; then
  python3 -c 'import gi
gi.require_version("Gtk", "3.0")
try: gi.require_version("AyatanaAppIndicator3", "0.1")
except ValueError: gi.require_version("AppIndicator3", "0.1")' 2>/dev/null \
    || faltan+=(python3-gi gir1.2-gtk-3.0 gir1.2-ayatanaappindicator3-0.1)
fi
if [ ${#faltan[@]} -gt 0 ]; then
  ojo "Faltan paquetes: ${faltan[*]}"
  echo "    sudo apt install ${faltan[*]}"
  command -v jq >/dev/null || { echo "Sin jq no puedo seguir. Instalalo y volvé a correr."; exit 1; }
fi
command -v gh >/dev/null || ojo "Sin gh (GitHub CLI) no andan claude-estado, claude-pr ni el hook de build."
ok "jq $(jq --version)"

# ── 2. Scripts ───────────────────────────────────────────────────────────────
paso "2. Scripts"
mkdir -p "$GADGETS/bin" "$GADGETS/indicador" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/estado"
respaldar() {  # guarda una copia si existe y es distinto
  if [ -f "$2" ] && ! cmp -s "$1" "$2"; then cp "$2" "$2.bak-$(date +%Y%m%d%H%M%S)"; ojo "Respaldé tu $(basename "$2") anterior"; fi
}
respaldar "$AQUI/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"
install -m 755 "$AQUI/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"
respaldar "$AQUI/claude/hooks/avisar.sh" "$CLAUDE_DIR/hooks/avisar.sh"
install -m 755 "$AQUI/claude/hooks/avisar.sh" "$CLAUDE_DIR/hooks/avisar.sh"
install -m 755 "$AQUI/claude/hooks/frenar.sh" "$CLAUDE_DIR/hooks/frenar.sh"
install -m 755 "$AQUI/claude/hooks/prebuild-check.sh" "$CLAUDE_DIR/hooks/prebuild-check.sh"
install -m 755 "$AQUI/claude/hooks/secretos.sh" "$CLAUDE_DIR/hooks/secretos.sh"
for f in "$AQUI"/bin/*; do [ -f "$f" ] && install -m 755 "$f" "$GADGETS/bin/"; done
mkdir -p "$HOME/.local/bin"
for c in claude-siri claude-estado claude-guardia claude-buzon claude-anotar claude-permitir claude-jobs claude-prebuild \
         claude-horas claude-buscar claude-panel claude-limite claude-cola claude-diario claude-limpiar \
         claude-pr claude-ritmo claude-retomar claude-decisiones claude-vigia claude-brief claude-captura claude-medico claude-celular \
         claude-portapapeles claude-explica claude-como claude-commit claude-salud claude-portero claude-recordar claude-renombrar claude-gadgets claude-alterminar claude-despierto claude-control claude-avisame; do
  ln -sf "$GADGETS/bin/$c" "$HOME/.local/bin/$c"
done
ln -sf "$GADGETS/bin/claude-gadgets" "$HOME/.local/bin/gadget"     # Go Go Gadget: `gadget salud`, `gadget --menu`
ln -sf "$GADGETS/bin/claude-avisame" "$HOME/.local/bin/avisame"   # avisame make build
ok "statusline, hooks y comandos en $GADGETS/bin (enlazados en ~/.local/bin)"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) ojo "~/.local/bin no está en tu PATH: agregalo en ~/.profile para usar los comandos" ;; esac

mkdir -p "$CONF_DIR"
if [ ! -f "$CONF_DIR/config" ]; then cp "$AQUI/config/config.ejemplo" "$CONF_DIR/config"; ok "Config creada: $CONF_DIR/config"
else ok "Config existente respetada: $CONF_DIR/config"; fi

# ── 3. settings.json ─────────────────────────────────────────────────────────
paso "3. Configuración de Claude Code"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
jq empty "$SETTINGS" 2>/dev/null || { echo "Tu $SETTINGS no es JSON válido; arreglalo y reintentá."; exit 1; }
cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d%H%M%S)"
permisos='[]'; [ $CON_PERMISOS = 1 ] && permisos=$(cat "$AQUI/config/permisos-lectura.json")
tmp=$(mktemp)
jq --argjson eventos "$(cat "$AQUI/config/hooks.json")" --argjson permisos "$permisos" '
  .statusLine = {type:"command", command:"~/.claude/statusline.sh", padding:0}
  | .hooks = (.hooks // {})
  | .hooks.PreToolUse = (
      [ (.hooks.PreToolUse // [])[]
        | .hooks = [ .hooks[] | select((.command // "") | test("hooks/(frenar|prebuild-check|secretos)\\.sh") | not) ]
        | select(.hooks | length > 0) ]
      + [ {matcher:"Bash", hooks:[
            {type:"command", command:"~/.claude/hooks/frenar.sh", timeout:10},
            {type:"command", command:"~/.claude/hooks/prebuild-check.sh", if:"Bash(gh pr merge:*)", timeout:60}]},
          {matcher:"Write|Edit|NotebookEdit", hooks:[
            {type:"command", command:"~/.claude/hooks/secretos.sh", timeout:10}]} ])
  | reduce ($eventos | to_entries[]) as $e (.;
      .hooks[$e.key] = (
        [ (.hooks[$e.key] // [])[]
          | .hooks = [ .hooks[] | select((.command // "") | contains("hooks/avisar.sh") | not) ]
          | select(.hooks | length > 0) ]
        + [ {hooks:[{type:"command", command:("~/.claude/hooks/avisar.sh " + $e.value), timeout:5}]} ]
      ))
  | if ($permisos | length) > 0
    then .permissions.allow = ((.permissions.allow // []) + $permisos | unique) else . end
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
ok "statusLine y hooks (avisos + freno de mano en PreToolUse) en settings.json"
[ $CON_PERMISOS = 1 ] && ok "Permisos de sólo lectura agregados ($(jq length "$AQUI/config/permisos-lectura.json"))"
ok "Respaldo: $SETTINGS.bak-*"

# ── 4. Indicador de la bandeja ───────────────────────────────────────────────
if [ $SIN_BARRA = 0 ]; then
  paso "4. Indicador de la bandeja"
  install -m 755 "$AQUI/indicador/claude-indicador.py" "$GADGETS/indicador/claude-indicador.py"
  mkdir -p "$HOME/.config/autostart"
  cat > "$HOME/.config/autostart/claude-gadgets-indicador.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Claude Code Gadgets
Comment=Uso de Claude y sesiones en la bandeja
Exec=$GADGETS/indicador/claude-indicador.py
Icon=dialog-information
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF
  pkill -f "$GADGETS/indicador/claude-indicador.py" 2>/dev/null || true
  if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
    setsid -f "$GADGETS/indicador/claude-indicador.py" >/dev/null 2>&1 </dev/null \
      && ok "Indicador abierto: vas a ver ✳ con el % de sesión · semana (y arranca solo al iniciar sesión)"
  else
    ok "Indicador instalado: aparece la próxima vez que inicies sesión en el escritorio"
  fi
  case "${XDG_CURRENT_DESKTOP:-}" in
    *GNOME*) gnome-extensions list --enabled 2>/dev/null | grep -qiE 'appindicator' \
      || ojo "GNOME no muestra indicadores sin la extensión AppIndicator: sudo apt install gnome-shell-extension-appindicator (y activala)" ;;
  esac
fi

# ── 5. Administrador de archivos ─────────────────────────────────────────────
if [ $SIN_ARCHIVOS = 0 ]; then
  paso "5. «Preguntarle a Claude» en el administrador de archivos"
  puestos=""
  for par in "nautilus|$HOME/.local/share/nautilus/scripts" "nemo|$HOME/.local/share/nemo/scripts" "caja|$HOME/.config/caja/scripts"; do
    command -v "${par%%|*}" >/dev/null || continue
    mkdir -p "${par#*|}"
    install -m 755 "$AQUI/archivos/Preguntarle a Claude" "${par#*|}/Preguntarle a Claude"
    install -m 755 "$AQUI/archivos/Renombrar con Claude" "${par#*|}/Renombrar con Claude"
    puestos+=" ${par%%|*}"
  done
  if command -v dolphin >/dev/null; then
    mkdir -p "$HOME/.local/share/kio/servicemenus"
    install -m 755 "$AQUI/archivos/claude-gadgets.desktop" "$HOME/.local/share/kio/servicemenus/claude-gadgets.desktop"
    puestos+=" dolphin"
  fi
  if [ -n "$puestos" ]; then ok "Clic derecho sobre un archivo → Scripts → Preguntarle a Claude · Renombrar con Claude (${puestos# })"
  else ojo "No encontré Nautilus, Nemo, Caja ni Dolphin. Desde la terminal: ~/.claude/gadgets/bin/claude-archivo <archivo>"; fi
fi

# ── 6. Ulauncher (sólo si lo tenés) ──────────────────────────────────────────
if [ $SIN_ULAUNCHER = 0 ] && command -v ulauncher >/dev/null; then
  paso "6. Claude en Ulauncher"
  ext="${XDG_DATA_HOME:-$HOME/.local/share}/ulauncher/extensions/claude-gadgets"
  mkdir -p "$ext/images"
  install -m 644 "$AQUI/ulauncher/manifest.json" "$AQUI/ulauncher/main.py" "$ext/"
  install -m 644 "$AQUI/ulauncher/images/icon.svg" "$ext/images/"
  ok "Extensión instalada: abrí Ulauncher y escribí «c tu pregunta» + Enter"
  if pgrep -f 'bin/ulauncher' >/dev/null 2>&1; then
    ojo "Ulauncher carga las extensiones al arrancar: cerralo y abrilo de nuevo (pkill -f bin/ulauncher; setsid -f ulauncher --hide-window)"
  fi
fi

# ── 7. Extensión de GNOME Shell: avisos que se callan en Wayland ─────────────
uuid=claude-gadgets@claude-code-gadgets
gnome_v=$(gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)
if [ $SIN_GNOME = 0 ] && [ "${gnome_v:-0}" -ge 45 ]; then
  paso "7. Extensión de GNOME Shell"
  ext="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$uuid"
  mkdir -p "$ext"
  install -m 644 "$AQUI/gnome/$uuid/metadata.json" "$AQUI/gnome/$uuid/extension.js" "$ext/"
  if ! gnome-extensions enable "$uuid" 2>/dev/null; then
    # GNOME todavía no la vio (las descubre al iniciar sesión): la dejo anotada como activa.
    lista=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || echo "@as []")
    case "$lista" in
      *"'$uuid'"*) ;;
      "@as []"|"[]") gsettings set org.gnome.shell enabled-extensions "['$uuid']" ;;
      *) gsettings set org.gnome.shell enabled-extensions "${lista%]}, '$uuid']" ;;
    esac
  fi
  if gnome-extensions info "$uuid" 2>/dev/null | grep -qE 'ACTIVE|ENABLED'; then
    ok "Extensión activa: en Wayland no te aviso si estás mirando esa terminal"
  else
    ok "Extensión instalada: empieza a andar la próxima vez que inicies sesión"
  fi
fi

# ── 8. La terminal: Ctrl+G, ups y explica ────────────────────────────────────
if [ $SIN_TERMINAL = 0 ]; then
  paso "8. Terminal (bash)"
  mkdir -p "$GADGETS/shell"
  install -m 644 "$AQUI/shell/claude-gadgets.bash" "$GADGETS/shell/"
  if grep -qF 'claude-gadgets.bash' "$HOME/.bashrc" 2>/dev/null; then ok "Tu ~/.bashrc ya los carga"
  else
    [ -f "$HOME/.bashrc" ] && cp "$HOME/.bashrc" "$HOME/.bashrc.bak-$(date +%Y%m%d%H%M%S)"
    printf '\n# >>> claude-gadgets >>>\n[ -f ~/.claude/gadgets/shell/claude-gadgets.bash ] && . ~/.claude/gadgets/shell/claude-gadgets.bash\n# <<< claude-gadgets <<<\n' >> "$HOME/.bashrc"
    ok "Agregué tres renglones a ~/.bashrc (con respaldo .bak-*): en una terminal nueva tenés Ctrl+G, ups y explica"
  fi
fi

# ── Listo ────────────────────────────────────────────────────────────────────
paso "Listo ✳"
cat <<EOF
  • Abrí una sesión nueva de Claude Code para ver la statusline y los hooks
    (en una sesión abierta: /hooks para recargar).
  • El % de uso aparece en la bandeja apenas corra una sesión (hace falta login
    con cuenta de claude.ai; con API key no hay límites que mostrar).
  • Desde el celular: seguí docs/CELULAR.md (SSH + Tailscale + Atajo o Termux).
  • Opcional: editá $CONF_DIR/config para vigilar tu servicio.
  • Guardián de deploys y buzón (opcionales, se prenden a mano):
      claude-guardia --instalar     (antes: definí GUARDIA en la config)
      claude-buzon --instalar       (crea la carpeta «Para Claude» en tu home)
  • Todo lo que hay y qué está prendido: gadget        (menú en pantalla: gadget --menu)
  • Atajos de teclado (GNOME): claude-captura --instalar, claude-portapapeles --instalar,
    gadget --instalar
  • Avisos al teléfono cuando no estás en la compu: claude-celular --instalar
  • Vigilancia de la máquina: claude-salud --instalar, claude-portero --instalar
  • Estado de todo en una pantalla: claude-estado
  • Tus números: claude-horas · claude-panel · claude-buscar "…" · claude-limpiar
  • Los que corren solos (opcionales): claude-limite --instalar,
    claude-diario --instalar, claude-cola --instalar, claude-brief --instalar,
    claude-medico --instalar (diagnóstico cuando falla un servicio de systemd)
  • Para desinstalar: ./uninstall.sh
EOF
