# Claude Code Gadgets para Linux

Accesorios para usar [Claude Code](https://claude.com/claude-code) en Debian, Ubuntu y derivados (y desde el celular).
Se instalan con un comando y se desinstalan con otro. **El catálogo completo, por cómo se usa cada uno: [GADGETS.md](GADGETS.md).** Es el port de
[claude-code-gadgets-macos](https://github.com/Fibonach0/claude-code-gadgets-macos): mismos gadgets, misma config.

| Gadget | Qué hace |
|---|---|
| **Indicador de la bandeja** | `✳ 3% · 45%`: el % de uso de la **sesión** (ventana de 5 h) y de la **semana**, con barra, cuándo se renueva cada uno y las sesiones que te están esperando (🟠). Opcional: si tu servicio responde. |
| **Statusline** | Abajo de cada sesión: `modelo · carpeta (rama*) · ctx 25% · 5h 3% · 7d 45% · $1.23`. Verde, amarillo desde el 50 %, rojo desde el 80 %. |
| **Avisos** (hooks) | Notificación y sonido cuando Claude termina o te necesita, sólo si no estás mirando esa terminal. En X11 anda solo; en Wayland con GNOME 45+ lo resuelve una extensión chiquita de GNOME Shell que instala `install.sh` (publica qué ventana tiene el foco y nada más; si la terminal tiene varias ventanas en un mismo proceso no puede distinguirlas y avisa igual). En otros escritorios Wayland avisa siempre. |
| **Archivos** | Clic derecho sobre un archivo → *Scripts* → **Preguntarle a Claude** (Nautilus, Nemo, Caja; en Dolphin, menú de acciones). Le preguntás algo y la respuesta se abre en tu editor. Claude sólo puede leer. |
| **Go Go Gadget** | `gadget`: el inventario de todo, con qué está prendido. `gadget <nombre>` es atajo de `claude-<nombre>`, y `gadget --menu` (`Súper+Mayús+G` con `gadget --instalar`) abre un menú en pantalla para elegir uno. El mismo menú está en el indicador de la bandeja, en *Gadgets*. |
| **Lo seleccionado → Claude** | `claude-portapapeles`: marcás un texto en cualquier programa, apretás `Súper+Mayús+X` (`--instalar`) y elegís: explicar, resumir, traducir al castellano o al inglés, corregir la redacción, escribir una respuesta u otra cosa. La respuesta sale en una ventana; si es un texto para pegar, ya queda copiado. |
| **Captura → texto** | `claude-captura --texto` (`Súper+Mayús+T`): recortás un pedazo de pantalla y el texto que se ve queda en el portapapeles. OCR sin instalar nada. |
| **Terminal** (bash) | **Ctrl+G**: escribís en castellano lo que querés hacer y la línea se cambia por el comando, sin ejecutarlo. **`ups`**: por qué falló el último comando y cómo arreglarlo (`ups -r` lo corre de nuevo para leer el error). **`comando 2>&1 \| explica`**: explica cualquier salida. `claude-como "…"` devuelve el comando suelto. |
| **Commits** | `claude-commit`: escribe el mensaje a partir de lo que está en stage, con el estilo de los commits anteriores, y pregunta antes de commitear (`-a` suma todo, `-s` no pregunta, `-m` sólo imprime). |
| **Salud de la máquina** | `claude-salud`: disco, memoria y swap, temperatura, batería, servicios caídos, reinicio pendiente y actualizaciones en una pantalla. `--instalar` avisa cuando algo pasa de la raya (una vez por problema); `--consejo` le pide a Claude qué limpiar. |
| **Portero** | `claude-portero --instalar`: aviso cuando alguien entra a la máquina por SSH (quién, desde dónde, cómo) y cuando hay una tanda de intentos fallidos. `PORTERO_CONOCIDAS` evita avisos de tu propia red. |
| **Al terminar** | `claude-alterminar`: espera a que ninguna sesión de Claude Code esté trabajando y avisa (al teléfono, si lo tenés). `claude-alterminar suspender` o `apagar` además suspende o apaga la compu; `claude-alterminar -- comando` corre lo que quieras. Si una sesión quedó esperándote, no apaga: te avisa. |
| **Despierto** | `claude-despierto --instalar`: mientras haya una sesión trabajando, la compu no se suspende sola. No toca tu configuración de energía. |
| **Recordatorios** | `claude-recordar en 20 minutos sacar la pizza`, `claude-recordar mañana a las 9 llamar al contador`. Avisa a la hora, sobrevive a un reinicio y, si no estás, va al teléfono. En Ulauncher: `r mañana 18:30 partido`. |
| **Renombrar con Claude** | Clic derecho → *Scripts* → **Renombrar con Claude** (o `claude-renombrar archivos…`): mira `IMG_4821.jpg` y `descarga (2).pdf` y propone nombres que dicen qué son. Tildás cuáles aceptar; `--deshacer` vuelve atrás. |
| **Avisos al celular** | `claude-celular --instalar`: si Claude te queda esperando, falla un servicio o se acaba el cupo y **no estás en la compu** (pantalla bloqueada o sin tocarla hace 3 minutos), el aviso te llega al teléfono por [ntfy](https://ntfy.sh). Crea un tema secreto al azar y te dice cómo suscribirte. El texto del aviso pasa por ntfy.sh (o por tu servidor: `NTFY_SERVIDOR`). |
| **Control remoto** | `claude-control --instalar` (después de `claude-celular`): le escribís a la compu desde la app ntfy y te contesta en el teléfono. Entiende `estado`, `recordame en 20 minutos …`, `anotá …`, `pendientes`, `decí …` (lo dice en voz alta), `bloquear`, y cualquier otra cosa se la pregunta a Claude **sin herramientas**: no lee tus archivos ni corre comandos. Si tenés `claude-dictar`, también entiende **notas de voz** adjuntas. |
| **Avisame** | `avisame make build`: corre un comando largo y al terminar te avisa (al teléfono si no estás). Si falló, Claude lee el final de la salida y te dice por qué en una frase. Respeta el código de salida. |
| **Vigía de internet** | `claude-red`: el parte de la red (latencia, DNS, router, IP pública, wifi, Tailscale). `--instalar` mira cada minuto y, cuando vuelve internet, te dice cuánto duró el corte; `--cortes` muestra el historial. |
| **Ordenar Descargas** | `claude-descargas`: Claude mira los nombres de lo suelto en Descargas y propone subcarpetas (Facturas, Fotos, Instaladores…). Tildás qué mover; `--deshacer` vuelve todo atrás. No lee el contenido. |
| **Resumir** | `claude-resumir link\|archivo`: resume una página, PDF, Word o texto; `-p "pregunta"` le pregunta algo puntual. También clic derecho → *Scripts* → **Resumir con Claude**, y en el menú de gadgets resume el link copiado. |
| **Dictado por voz** | `claude-dictar --instalar`: `Súper+Mayús+D` empieza a escuchar, otra vez termina, y el texto queda copiado. `Súper+Mayús+A` le pregunta a Claude por voz. `claude-dictar audio.ogg` (o clic derecho → *Transcribir audio*) pasa a texto notas de voz. Todo local con [faster-whisper](https://github.com/SYSTRAN/faster-whisper) (`pip install faster-whisper`, o `DICTAR_PY` apuntando a un venv que lo tenga). |
| **Modelo local** | `claude-local "…"`: la misma idea que una pregunta rápida, pero contesta un modelo de [Ollama](https://ollama.com) en tu compu. Gratis, offline y sin cupo. `LOCAL_MODELO` elige cuál. |
| **Casa** | `claude-casa`: luces y enchufes Tuya / Smart Life por la red local con [TinyTuya](https://github.com/jasonacox/tinytuya), sin pasar por la nube. `claude-casa prender adelante`, `apagar atrás 2`, o en castellano `claude-casa "apagá todo menos atrás"` (Claude traduce la frase a órdenes; las ejecuta el script). También desde el teléfono con `claude-control` y por nota de voz. Necesita las llaves locales una vez (`python -m tinytuya wizard`) y `CASA_PY`/`CASA_DISPOSITIVOS` en la config. |
| **Médico de servicios** | `claude-medico`: cuando una unidad de systemd falla o queda reiniciándose en bucle (del sistema o tuya), Claude lee el journal y te avisa con la causa y qué hacer. `--instalar` lo deja mirando cada 5 minutos; a mano muestra lo que está mal ahora, y `claude-medico nginx` diagnostica una unidad puntual. Avisa una vez por falla y sólo lee. |
| **Captura → Claude** | `claude-captura`: recortás un pedazo de pantalla (un error, un gráfico, un mail), preguntás y la respuesta aparece en una ventanita, con botón para copiarla. `claude-captura --instalar` le pone un atajo en GNOME (`Súper+Mayús+C`; otro: `--instalar '<Control><Alt>c'`). Recorta con lo que tengas: flameshot, gnome-screenshot, spectacle, el portal de escritorio… Claude sólo lee esa imagen. |
| **Ulauncher** | Si usás [Ulauncher](https://ulauncher.io): `c ¿cuánto es 30 dólares en pesos?` + Enter y la respuesta aparece en el lanzador (y como notificación, por si lo cerraste). Enter sobre la respuesta la copia; `c ` a secas muestra la última. La palabra clave se cambia en las preferencias de Ulauncher. Usa `claude-siri`: respuestas cortas, sólo lectura y web. |
| **Desde el celular** | `claude-siri "pregunta"`: una respuesta corta para leer en voz alta. Por SSH desde un Atajo del iPhone ("Oye Siri, consulta Claude") o desde Android (Termux, Tasker). Ver [docs/CELULAR.md](docs/CELULAR.md). |
| **Guardián de deploys** | `claude-guardia`: vigila solo todos tus repos de GitHub (también los que crees después) con lo que Railway, Pages y Actions informan en cada commit. Además, para los que declares, cuando mergeás a main espera a que el cambio llegue de verdad a producción. Si el sitio sigue sirviendo el bundle viejo (build roto que no bloquea el merge) o el servicio no vuelve, te avisa. |
| **Buzón** | `claude-buzon`: dejás una foto, PDF o Excel en una carpeta (si la sincronizás, también desde el celular) y aparece al lado una ficha en `.md` con los datos. |
| **Estado** | `claude-estado`: en una pantalla, servicios arriba o abajo, qué se mergeó hoy, PRs abiertos, deploys en curso y tu cupo de Claude. Va bien para pedirlo desde el celular. |
| **Freno de mano** | Hook `PreToolUse` que frena lo irreversible antes de que pase: push forzado, `rm -rf` con comodín, DROP/TRUNCATE, variables de producción, borrar repos o credenciales, `dd`/`mkfs` sobre un disco. |
| **Guardián de jobs** | `claude-jobs`: una vez por día recorre todos tus servicios de Railway (o la lista `JOBS` que le des) y avisa sólo si un job falló, no corrió o un servicio está caído. |
| **Build de prueba** | `claude-prebuild`: compila el front en una copia aparte, sin pisar tu `build/`. Un hook exige ese build verde antes de mergear un PR que toca el front. |
| **Anotar por voz** | `claude-anotar "…"`: guarda un pendiente con fecha y proyecto (lo clasifica solo). Va bien para dictarlo desde el celular. |
| **Autorizar desde el celular** | `claude-permitir`: deja pasar, una vez y por 10 minutos, el último comando que frenó el freno de mano. Y **aprende**: a la tercera vez te ofrece dejarlo fijo (`--siempre`), así el freno queda para lo raro. |
| **Parte de la mañana** | `claude-brief`: cuatro o cinco frases habladas — cupo, qué se rompió mientras dormías, pendientes y agenda. Se cocina temprano en la compu y el teléfono sólo lo lee; `--decir` lo lee la compu en voz alta. |
| **Parte de horas** | `claude-horas`: cuánto le dedicaste a cada proyecto, por día o por mes, con `--csv` para la planilla. Sale de tus propias sesiones. |
| **Buscador** | `claude-buscar "el WAF que bloqueaba"`: busca en todo lo que ya trabajaste y te contesta, diciendo de qué día y proyecto lo sacó. |
| **Panel** | `claude-panel`: una página local con tiempo por día y por proyecto, pedidos y costo estimado. |
| **Aviso de límite** | `claude-limite`: cuando el cupo semanal pasa 60/80/90%, avisa una vez y sugiere bajar de modelo. |
| **Cola de pedidos** | `claude-cola "…"`: dejás encargues (también desde el celular) y la compu los toma de a uno. Modo lectura por defecto. |
| **Diario** | `claude-diario`: cada noche escribe qué hiciste ese día, por proyecto. |
| **Limpiador** | `claude-limpiar`: qué ocupa disco de lo que deja Claude Code, y cómo liberarlo sin perder la memoria útil. |
| **Costo por PR** | `claude-pr`: cuánto tiempo y cuántos pedidos costó cada PR mergeado. Para presupuestar. |
| **Ritmo** | `claude-ritmo`: horas por semana, qué días rendís y cuánto viven tus PRs abiertos. |
| **Retomar** | `claude-retomar`: tus últimas sesiones con su tema; elegís una y la reabre donde estaba. |
| **Decisiones** | `claude-decisiones`: saca de las sesiones qué decidiste y por qué, a un `DECISIONES.md`. |
| **Credenciales** | Hook que frena que una clave entre a un repo, al escribir un archivo y al commitear. |
| **Vigía** | `claude-vigia`: trabajo sin commitear hace horas, commits sin pushear, ramas viejas y worktrees. |
| **No molestar** | Horario en que los avisos se callan; lo urgente (un servicio caído) suena igual. |
| **Permisos** (opcional) | Deja correr sin preguntar comandos de sólo lectura (`git status/log/diff`, `ls`, `gh pr view`, `railway logs`…). |

## Instalar

```bash
git clone <este repo> ~/claude-code-gadgets-linux
cd ~/claude-code-gadgets-linux
./install.sh                 # todo
./install.sh --con-permisos  # + permisos de sólo lectura
```

Otras opciones: `--sin-barra`, `--sin-archivos`, `--sin-ulauncher`, `--sin-gnome`, `--sin-terminal`. Podés correrlo de nuevo cuando quieras: reemplaza lo suyo y no toca lo demás.

Requisitos: Linux con systemd, Claude Code con login de claude.ai (Pro/Max) y estos paquetes
(el instalador no usa `sudo`: te dice cuáles faltan):

```bash
sudo apt install jq curl git rsync libnotify-bin zenity \
                 python3-gi gir1.2-gtk-3.0 gir1.2-ayatanaappindicator3-0.1
```

Opcionales: `gh` (estado, costo por PR, hook de build), `espeak-ng` o `speech-dispatcher` (`claude-brief --decir`),
`python3-openpyxl` (Excel en el buzón), `x11-utils` (en X11, no avisar si estás mirando la terminal).

Después:
1. Abrí una sesión nueva de Claude Code. En la que ya tenías abierta, usá `/hooks` para recargar.
2. El % aparece en la bandeja en cuanto corre cualquier sesión.

### Según tu escritorio

| Escritorio | Indicador | Archivos |
|---|---|---|
| Ubuntu (GNOME) | Anda tal cual, con el % al lado del ícono. | Nautilus → *Scripts*. |
| Debian con GNOME | Hace falta la extensión: `sudo apt install gnome-shell-extension-appindicator`, y activarla en *Extensiones*. | Nautilus → *Scripts*. |
| KDE Plasma | Ícono y menú. | Dolphin → menú de acciones. |
| Cinnamon / MATE | Ícono y menú. | Nemo / Caja → *Scripts*. |
| XFCE | Ícono y menú. | Thunar: agregá a mano una acción personalizada con `~/.claude/gadgets/bin/claude-archivo %F`. |

El texto con el % al lado del ícono es una extensión de AppIndicator que no todas las bandejas
dibujan. Donde no aparece, el dato está igual: el ícono se pone naranja desde el 50 % y rojo desde el
80 %, y el número está en el menú y al pasar el mouse. Sólo lo probé en Ubuntu 24.04 con GNOME.

En X11 los avisos se callan si la ventana activa es la de Claude. En Wayland el escritorio no le
cuenta a nadie qué ventana tiene el foco: en GNOME 45+ lo resuelve la extensión que instala
`install.sh` (arranca en el siguiente inicio de sesión); en los demás escritorios Wayland los avisos
llegan siempre. La extensión todavía no está probada en una sesión Wayland real.

### Qué toca

- `~/.claude/statusline.sh` y `~/.claude/hooks/` (`avisar.sh`, `frenar.sh`, `prebuild-check.sh`, `secretos.sh`). Si ya tenías versiones distintas de la statusline o de `avisar.sh`, las guarda como `.bak-*`.
- `~/.claude/settings.json`: agrega `statusLine` y hooks en `UserPromptSubmit`, `Notification`, `Stop`, `SessionEnd` y `PreToolUse`. Antes deja un respaldo `settings.json.bak-*`. Todo lo demás queda como estaba.
- `~/.claude/gadgets/`: comandos e indicador. Enlaces en `~/.local/bin/`.
- `~/.config/autostart/claude-gadgets-indicador.desktop`: el indicador arranca al iniciar sesión.
- `~/.local/share/nautilus/scripts/Preguntarle a Claude` (o el equivalente de Nemo, Caja o Dolphin).
- `~/.bashrc`: tres renglones al final (entre marcas `claude-gadgets`) que cargan Ctrl+G, `ups` y `explica`. Antes deja un respaldo `.bashrc.bak-*`.
- Atajos de teclado de GNOME: sólo los que prendas con `--instalar`.
- `~/.local/share/ulauncher/extensions/claude-gadgets/`: sólo si tenés Ulauncher.
- `~/.local/share/gnome-shell/extensions/claude-gadgets@claude-code-gadgets/` y su entrada en las extensiones activas: sólo en GNOME 45 o más nuevo.
- `~/.config/systemd/user/claude-gadgets-*`: sólo los que prendas con `--instalar`.
- `~/.config/claude-gadgets/config`: tu configuración (ver `config/config.ejemplo`).

## Desinstalar

```bash
./uninstall.sh
```

## Cómo funciona el % de uso

Claude Code le pasa a la statusline un JSON que trae `rate_limits.five_hour` y `rate_limits.seven_day` (`used_percentage` y `resets_at`). `statusline.sh` guarda eso en `~/.claude/estado/uso.json` y el indicador lo lee cada medio minuto.

- El dato se actualiza **mientras usás Claude Code**: el menú muestra "dato de hace N min".
- Si la ventana ya se renovó desde el último dato, el indicador muestra 0 %.
- El uso de claude.ai web o de la app no se ve hasta la próxima vez que corra Claude Code. El número exacto está en *Ver uso en claude.ai*, dentro del menú.
- Con API key (sin login de claude.ai) no hay límites, así que no se muestra nada.

## Configuración (`~/.config/claude-gadgets/config`)

```bash
HUB_URL="https://tu-servicio.ejemplo.com/"   # el indicador muestra 🟢/🔴
HUB_NOMBRE="Hub"
LINKS=("Railway=https://railway.com/dashboard")
CLAUDE_SIRI_DIR="$HOME/proyectos"            # dónde trabaja claude-siri
CLAUDE_SIRI_MODELO="sonnet"
CLAUDE_SIRI_EXTRA=("$HOME/otra-carpeta")     # carpetas extra que puede leer

# Guardián de deploys: sin nada, vigila todos tus repos de GitHub (GUARDIA_AUTO=0 lo apaga)
GUARDIA_DUENOS="tu-usuario tu-org"             # opcional: de quién son los repos
GUARDIA_IGNORAR="Supabase Preview"           # chequeos que no son de producción
# Extra, para sitios que no le informan a GitHub: nombre|repo|destino|modo (bundle | salud)
GUARDIA=("hub|$HOME/proyectos/hub|https://hub.ejemplo.com/|bundle"
         "bot|$HOME/proyectos/bot|https://bot.ejemplo.com/|salud")
GUARDIA_ESPERA=15                            # minutos antes de dar el deploy por perdido
GUARDIA_PATRON="^front/"                     # en modo bundle, qué rutas obligan a esperar

BUZON="$HOME/Para Claude"                    # cualquier carpeta; mejor si se sincroniza
NTFY_TOPIC=""                                # opcional: avisos al celular por ntfy.sh
FRENO=1                                      # 0 apaga el freno de mano

# Guardián de trabajos programados (usa el conector de Railway vía Claude).
# Sin JOBS revisa todos los servicios de Railway; con JOBS, sólo esa lista.
JOBS_SERVICIO="el servicio web del proyecto tal"
JOBS=("backup_diario|03:00|guarda el dump" "aviso_precios|08:15|")
JOBS_HORA=10

# Build de prueba antes de mergear front
PREBUILD_DIR="$HOME/proyectos/hub/front"
PREBUILD_PATRON="^front/"                    # qué rutas del PR lo exigen

# Pendientes dictados
PENDIENTES="$HOME/Documentos/Pendientes.md"
ANOTAR_PISTAS="el hub es tal repo; el bot es tal otro"

# Parte hablado de la mañana
BRIEF_HORA=7          # se arma 7:30
BRIEF_AGENDA=1        # incluye la agenda (conector de Google Calendar)
BRIEF_VOZ="female1"   # voz de spd-say (o de espeak-ng) para --decir

# Tus números y la cola
LIMITE_AVISOS="60 80 90"          # en qué % del cupo semanal avisar
COLA_DIR="$HOME/proyectos"        # dónde trabaja la cola
COLA_MODO=seguro                  # "trabajar" la deja editar archivos
DIARIO_DIR="$HOME/Documentos/Diario"
LIMPIAR_DIAS=90                   # qué es "viejo" para el limpiador

# No molestar: de 23 a 8, y los domingos. Lo urgente suena igual.
SILENCIO_DESDE=23
SILENCIO_HASTA=8
SILENCIO_DIAS="dom"
SECRETOS=1                        # 0 apaga el detector de credenciales
VIGIA_HORAS=4                     # horas sin commitear antes de recordarte
VIGIA_RAMAS=14                    # días de una rama sin mergear
```

Los que corren solos, una vez cada uno:

```bash
claude-guardia --instalar    # deploys, cada 2 minutos
claude-buzon --instalar      # la carpeta mágica
claude-jobs --instalar       # los trabajos programados, una vez por día
claude-brief --instalar      # el parte hablado, temprano
claude-limite --instalar     # mira el cupo cada media hora
claude-diario --instalar     # escribe el diario a las 20:00
claude-cola --instalar       # toma un pedido de la cola cada 5 minutos
claude-vigia --instalar      # mira los repos cada 2 horas
```

Cada uno es un timer de systemd del usuario (`systemctl --user list-timers 'claude-gadgets-*'`) y se
apaga con `--desinstalar`. Corren mientras tengas la sesión abierta; para que sigan con la sesión
cerrada (una máquina que hace de servidor): `sudo loginctl enable-linger $USER`. Los que tienen hora
fija se ponen al día al prender si la compu estaba apagada.

> `NTFY_TOPIC` manda los avisos a ntfy.sh, un servicio público: cualquiera que
> adivine el nombre del tema los ve. Usá un nombre largo y al azar, y no pongas
> ahí nada sensible. Vacío = sólo avisos en el escritorio.

## Extras que vienen con Claude Code

- **Remote Control**: seguí desde la app de Claude en el celular una sesión que corre en la compu (`/remote-control`, o `"remoteControlAtStartup": true` en settings).
- **Push al celular**: `/config` → notificaciones al móvil cuando Claude te necesita.
- **Dictado por voz**: `/config` → voz, o `"voice": {"enabled": true}` en settings.
- **`/schedule`**: agentes en la nube con horario fijo, aunque la compu esté apagada.

## Diferencias con la versión de macOS

| En la Mac | Acá |
|---|---|
| SwiftBar en la barra de menú | Indicador propio (Python + AppIndicator) |
| `launchd` | Timers de `systemd --user` |
| `osascript` (notificaciones y diálogos) | `notify-send`, sonidos de freedesktop y `zenity` |
| Acción rápida de Finder | Script de Nautilus / Nemo / Caja y menú de Dolphin |
| `say` | `spd-say` o `espeak-ng` |
| Buzón en iCloud Drive | Cualquier carpeta (Syncthing, Nextcloud, Dropbox…) |
| Build en volumen sensible a mayúsculas | Build en una copia aparte (el disco ya distingue mayúsculas) |
| Token para entrar por SSH (llavero bloqueado) | No hace falta: el login vive en `~/.claude` |

La config (`~/.config/claude-gadgets/config`) es la misma: podés copiar la de la Mac y cambiar las rutas.

## Estructura

```
install.sh / uninstall.sh
claude/statusline.sh          statusline + guarda el uso
claude/hooks/avisar.sh        avisos + estado de sesiones
claude/hooks/frenar.sh        freno de mano (PreToolUse)
claude/hooks/prebuild-check.sh  exige build verde antes de mergear front
claude/hooks/secretos.sh      frena credenciales antes de que entren al repo
indicador/claude-indicador.py indicador de la bandeja
archivos/                     «Preguntarle a Claude» para Nautilus/Nemo/Caja y Dolphin
ulauncher/                    extensión de Ulauncher: «c tu pregunta»
gnome/                        extensión de GNOME Shell: foco de ventana en Wayland
shell/claude-gadgets.bash     Ctrl+G, ups y explica para bash
bin/comun.sh                  avisos, sonidos, voz y timers (lo cargan los demás)
bin/silencio.sh               horario de no molestar
bin/claude-*                  un comando por gadget (ver la tabla de arriba)
bin/tx.py, bin/prs.py         leen tus sesiones y tus PRs (horas, panel, diario, buscar)
config/                       ejemplo de config, hooks, permisos
pruebas/                      casos del freno, credenciales, silencio, vigía y guardián
docs/CELULAR.md               paso a paso para usarlo desde el teléfono
```
