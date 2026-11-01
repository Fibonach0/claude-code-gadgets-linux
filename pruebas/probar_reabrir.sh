#!/bin/bash
# claude-reabrir: qué reabre tras un reinicio, en un HOME de mentira.
# gnome-terminal es un doble que anota lo que le piden: no abre nada de verdad.
set -u
aqui=$(cd "$(dirname "$0")/.." && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fallas=0
ok() { if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "MAL  $1: esperaba «$2», dio «$3»"; fallas=$((fallas+1)); fi; }

export HOME=$t/casa
mkdir -p "$HOME/.claude/estado" "$HOME/.claude/sessions" "$HOME/.claude/projects/-otra-carpeta" "$t/bin" "$HOME/obra"
clave=$(printf %s "$HOME/obra" | sed 's/[^[:alnum:]]/-/g')
mkdir -p "$HOME/.claude/projects/$clave"
cat > "$t/bin/gnome-terminal" <<EOF
#!/bin/bash
echo "\$*" >> "$t/abiertas"
EOF
chmod +x "$t/bin/gnome-terminal"
export PATH="$t/bin:$PATH"
foto=$HOME/.claude/estado/sesiones-abiertas.json
touch "$HOME/.claude/projects/$clave/uno.jsonl" "$HOME/.claude/projects/$clave/dos.jsonl"
echo '{"cwd":"'"$HOME/obra"'"}' > "$HOME/.claude/projects/-otra-carpeta/movida.jsonl"

poner_foto() {
  cat > "$foto" <<EOF
{"boot":"$1","sesiones":[
 {"id":"uno","cwd":"$HOME/obra","nombre":"A"},
 {"id":"dos","cwd":"$HOME/obra","nombre":"B"},
 {"id":"sin-conversacion","cwd":"$HOME/obra","nombre":"C"},
 {"id":"movida","cwd":"/otra/carpeta","nombre":"D"}]}
EOF
}
reabrir() { rm -f "$t/abiertas"; python3 "$aqui/bin/claude-reabrir" --restaurar; }
contar() { [ -f "$t/abiertas" ] && wc -l < "$t/abiertas" || echo 0; }

poner_foto "arranque-anterior"
python3 "$aqui/bin/claude-reabrir" --guardar
ok "la foto pendiente no se pisa" 3 "$(python3 -c "
import json;print(len([s for s in json.load(open('$foto'))['sesiones'] if s['id']!='sin-conversacion']))")"

reabrir
ok "reabre las que tienen conversación" 3 "$(contar)"
ok "la primera abre ventana" 1 "$(grep -c -- '--window' "$t/abiertas")"
ok "las demás, pestañas" 2 "$(grep -c -- '--tab' "$t/abiertas")"
ok "la movida vuelve a su carpeta" 1 "$(grep -c "working-directory=$HOME/obra.*--resume movida" "$t/abiertas")"

reabrir
ok "no reabre dos veces en el mismo arranque" 0 "$(contar)"

poner_foto "$(cat /proc/sys/kernel/random/boot_id)"
reabrir
ok "sin reinicio no hace nada" 0 "$(contar)"

sleep 300 & vivo=$!
inicio=$(awk '{print $NF}' <<<"$(cut -d' ' -f22 /proc/$vivo/stat)")
cat > "$HOME/.claude/sessions/$vivo.json" <<EOF
{"pid":$vivo,"procStart":"$inicio","sessionId":"uno","cwd":"$HOME/obra","kind":"interactive"}
EOF
poner_foto "arranque-anterior"
reabrir
ok "la que sigue viva no se duplica" 0 "$(grep -c 'resume uno' "$t/abiertas")"
kill $vivo

python3 -c 'import time; time.sleep(300)' --resume dos & espera=$!
poner_foto "$(cat /proc/sys/kernel/random/boot_id)"
python3 "$aqui/bin/claude-reabrir" --guardar
ok "la que espera confirmación sigue en la foto" 1 \
  "$(python3 -c "import json;print(len([s for s in json.load(open('$foto'))['sesiones'] if s['id']=='dos']))")"
kill $espera
wait $espera 2>/dev/null
python3 "$aqui/bin/claude-reabrir" --guardar
ok "la que se cerró sale de la foto" 0 \
  "$(python3 -c "import json;print(len(json.load(open('$foto'))['sesiones']))")"

cat > "$t/bin/gnome-terminal" <<'EOF'
#!/bin/bash
exit 1
EOF
poner_foto "arranque-anterior"
python3 "$aqui/bin/claude-reabrir" --restaurar 2>/dev/null
ok "si no pudo abrir, conserva la foto para reintentar" "arranque-anterior" \
  "$(python3 -c "import json;print(json.load(open('$foto'))['boot'])")"

[ "$fallas" = 0 ] && echo "Todo bien." || { echo "$fallas fallas"; exit 1; }
