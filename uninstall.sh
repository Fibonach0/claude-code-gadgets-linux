#!/bin/bash
# Desinstala Claude Code Gadgets. Deja los paquetes del sistema y tu config
# (~/.config/claude-gadgets); borralos a mano si querés.
set -euo pipefail
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak-$(date +%Y%m%d%H%M%S)"
  tmp=$(mktemp)
  jq '
    (if (.statusLine.command // "") == "~/.claude/statusline.sh" then del(.statusLine) else . end)
    | if .hooks then
        .hooks |= (with_entries(.value |= [ .[]
            | .hooks = [ .hooks[] | select((.command // "") | test("hooks/(avisar|frenar|prebuild-check|secretos)\\.sh") | not) ]
            | select(.hooks | length > 0) ])
          | with_entries(select(.value | length > 0)))
      else . end
    | if .hooks == {} then del(.hooks) else . end
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "✓ Saqué statusLine y hooks de settings.json (respaldo: settings.json.bak-*)"
  echo "  Los permisos de --con-permisos quedan; revisalos con /permissions si querés."
fi

"$CLAUDE_DIR/gadgets/bin/claude-guardia" --desinstalar 2>/dev/null || true
"$CLAUDE_DIR/gadgets/bin/claude-buzon" --desinstalar 2>/dev/null || true
"$CLAUDE_DIR/gadgets/bin/claude-jobs" --desinstalar 2>/dev/null || true
for g in claude-limite claude-diario claude-cola claude-brief claude-vigia claude-captura claude-medico \
         claude-portapapeles claude-gadgets claude-salud claude-portero claude-recordar claude-despierto claude-control; do
  "$CLAUDE_DIR/gadgets/bin/$g" --desinstalar 2>/dev/null || true
done
rm -f "$CLAUDE_DIR/statusline.sh" "$CLAUDE_DIR/hooks/avisar.sh" "$CLAUDE_DIR/hooks/frenar.sh" "$CLAUDE_DIR/hooks/prebuild-check.sh" "$CLAUDE_DIR/hooks/secretos.sh"
for c in claude-siri claude-estado claude-guardia claude-buzon claude-anotar claude-permitir claude-jobs claude-prebuild \
         claude-horas claude-buscar claude-panel claude-limite claude-cola claude-diario claude-limpiar claude-brief \
         claude-pr claude-ritmo claude-retomar claude-decisiones claude-vigia claude-captura claude-medico claude-celular \
         claude-portapapeles claude-explica claude-como claude-commit claude-salud claude-portero claude-recordar claude-renombrar claude-gadgets claude-alterminar claude-despierto claude-control claude-avisame gadget avisame; do rm -f "$HOME/.local/bin/$c"; done
pkill -f "$CLAUDE_DIR/gadgets/indicador/claude-indicador.py" 2>/dev/null || true
rm -f "$HOME/.config/autostart/claude-gadgets-indicador.desktop" \
      "$HOME/.local/share/nautilus/scripts/Preguntarle a Claude" \
      "$HOME/.local/share/nautilus/scripts/Renombrar con Claude" \
      "$HOME/.local/share/nemo/scripts/Renombrar con Claude" \
      "$HOME/.config/caja/scripts/Renombrar con Claude" \
      "$HOME/.local/share/nemo/scripts/Preguntarle a Claude" \
      "$HOME/.config/caja/scripts/Preguntarle a Claude" \
      "$HOME/.local/share/kio/servicemenus/claude-gadgets.desktop"
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/ulauncher/extensions/claude-gadgets"
[ -f "$HOME/.bashrc" ] && sed -i '/^# >>> claude-gadgets >>>$/,/^# <<< claude-gadgets <<<$/d' "$HOME/.bashrc"
uuid=claude-gadgets@claude-code-gadgets
if command -v gsettings >/dev/null && lista=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null); then
  gnome-extensions disable "$uuid" 2>/dev/null || true
  case "$lista" in *"'$uuid'"*)
    nueva=$(sed "s|, '$uuid'||; s|'$uuid', ||; s|'$uuid'||" <<<"$lista"); [ "$nueva" = "[]" ] && nueva="@as []"
    gsettings set org.gnome.shell enabled-extensions "$nueva" ;;
  esac
fi
rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$uuid"
rm -rf "$CLAUDE_DIR/gadgets" "${XDG_CACHE_HOME:-$HOME/.cache}/claude-gadgets"
echo "✓ Scripts, indicador y acción del administrador de archivos borrados"
