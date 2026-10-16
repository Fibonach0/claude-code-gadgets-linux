# Go Go Gadget: el catálogo

Todos los gadgets, qué hace cada uno y cómo se usa. Para ver cuáles están prendidos en tu
compu: `gadget` en una terminal. Para elegir uno desde un menú: `Súper+Mayús+G`.

Lo de abajo está agrupado por **cómo lo usás**: con un atajo, solo, desde el teléfono, en la
terminal, sobre archivos o a pedido.

---

## ⌨️ Con un atajo de teclado

| Atajo | Gadget | Qué hace |
|---|---|---|
| `Súper+Mayús+G` | **Go Go Gadget** (`claude-gadgets --menu`) | Menú en pantalla con todos los gadgets. El mismo menú está en el ícono de la bandeja, en *Gadgets*. |
| `Súper+Mayús+X` | **Lo seleccionado → Claude** (`claude-portapapeles`) | Marcás un texto en cualquier programa y elegís: explicar, resumir, traducir al castellano o al inglés, corregir, escribir una respuesta, leerlo en voz alta u otra cosa. Si el resultado es para pegar, ya queda copiado. |
| `Súper+Mayús+C` | **Captura → Claude** (`claude-captura`) | Recortás un pedazo de pantalla (un error, un gráfico, un mail), preguntás y la respuesta aparece en una ventanita con botón *Copiar*. |
| `Súper+Mayús+D` | **Dictado** (`claude-dictar`) | Apretás, hablás, apretás de nuevo: lo que dijiste queda copiado para pegar con `Ctrl+V`. Transcribe **en la compu** (faster-whisper): el audio no sale a internet. |
| `Súper+Mayús+A` | **Preguntar por voz** (`claude-dictar --preguntar`) | Igual que el dictado, pero lo que dijiste se lo pregunta a Claude y la respuesta aparece en una ventana. |
| `Súper+Mayús+T` | **Captura → texto** (`claude-captura --texto`) | Recortás la pantalla y el texto que se ve queda en el portapapeles. Sirve para copiar de imágenes, PDFs escaneados o videos. |

Los atajos se prenden con `--instalar` en cada gadget (`claude-captura --instalar '<Control><Alt>c'` para usar otro).

---

## 🤖 Corren solos (en segundo plano)

Se prenden con `claude-<nombre> --instalar` y se apagan con `--desinstalar`. Avisan con una
notificación; si no estás en la compu y tenés **avisos al celular**, el aviso va al teléfono.

| Gadget | Qué vigila | Cada cuánto |
|---|---|---|
| **Indicador de la bandeja** | `✳ 3% · 45%`: cuánto usaste de la sesión (5 h) y de la semana, cuándo se renueva y qué sesiones te esperan (🟠). | Siempre |
| **Avisos** (hooks) | Notificación y sonido cuando Claude termina o te necesita, si no estás mirando esa terminal. | Siempre |
| **Aviso de límite** (`claude-limite`) | Cuando el cupo semanal pasa 60/80/90 %, avisa una vez y sugiere bajar de modelo. | 30 min |
| **Médico** (`claude-medico`) | Si un servicio de systemd se cae o se reinicia en bucle, Claude lee el journal y te dice la causa y qué hacer. | 5 min |
| **Salud** (`claude-salud`) | Disco, memoria, temperatura, batería, servicios caídos, reinicio pendiente. Avisa una vez por problema. | 15 min |
| **Portero** (`claude-portero`) | Quién entra por SSH (usuario, desde dónde) y tandas de intentos fallidos. | 2 min |
| **Vigía de internet** (`claude-red`) | Cuando internet se corta y vuelve, te dice cuánto duró el corte. `claude-red --cortes` muestra el historial. | 1 min |
| **Despierto** (`claude-despierto`) | Que la compu no se suspenda mientras una sesión de Claude está trabajando. | 1 min |
| **Buzón** (`claude-buzon`) | Dejás una foto, PDF o Excel en la carpeta «Para Claude» y aparece al lado una ficha `.md` con los datos. | Al soltar el archivo |
| **Vigía** (`claude-vigia`) | Trabajo sin commitear hace horas, commits sin pushear, ramas y worktrees olvidados. | 2 h |
| **Cola** (`claude-cola`) | Toma los encargues que dejaste (`claude-cola "…"`) y los hace de a uno. Por defecto sólo lee y deja escrito qué haría. | 5 min |
| **Diario** (`claude-diario`) | Cada noche escribe qué hiciste ese día, por proyecto. | 20:00 |
| **Parte de la mañana** (`claude-brief`) | Arma temprano un parte de 4 o 5 frases: cupo, qué se rompió, pendientes y agenda. `claude-brief --decir` lo lee en voz alta. | 7:30 |
| **Recordatorios** (`claude-recordar`) | `claude-recordar en 20 minutos sacar la pizza` · `mañana a las 9 llamar al contador`. Sobreviven a un reinicio. | A la hora |
| **Guardián de deploys** (`claude-guardia`) | Vigila **todos** tus repos de GitHub, incluidos los nuevos, sin configurar nada. Cuando entra un merge a la rama principal, espera lo que informan Railway, GitHub Pages o Actions. Si llegó a producción te avisa en la compu; si falló o se trabó, también en el celular. Con `GUARDIA=(…)` además mira sitios que no informan a GitHub (bundle o salud). | 2 min |
| **Guardián de jobs** (`claude-jobs`) | Recorre **todos** los proyectos y servicios de Railway, también los nuevos. Busca jobs programados que fallaron, deploys caídos y errores repetidos de las últimas 24 h. Solo mira, no toca nada. Con `JOBS=(…)` revisa una lista fija. | 1 vez por día (10:00) |
| **Freno de mano** (hook) | Frena lo irreversible antes de que pase: push forzado, `rm -rf` con comodín, DROP/TRUNCATE, variables de producción, `dd`/`mkfs`. | Cada comando de Claude |
| **Credenciales** (hook) | Frena que una clave entre a un repo, al escribir un archivo y al commitear. | Cada archivo y commit |
| **Build de prueba** (hook + `claude-prebuild`) | Exige un build verde del front antes de mergear un PR que lo toca. | Al mergear |
| **No molestar** | De noche (o los días que digas) los avisos se callan; lo urgente suena igual. | Siempre |

---

## 📱 Desde el teléfono

| Gadget | Qué hace |
|---|---|
| **Avisos al celular** (`claude-celular --instalar`) | Si Claude te queda esperando, falla un servicio, se corta internet o se acaba el cupo **y no estás en la compu**, te llega al teléfono por la app [ntfy](https://ntfy.sh). |
| **Control remoto** (`claude-control --instalar`) | Le escribís a la compu desde la app ntfy y te contesta. Entiende: `casa`, `prendé la luz de …`, `apagá todo`, `estado`, `red`, `recordame en 20 minutos …`, `anotá …`, `pendientes`, `decí …` (lo dice en voz alta en la compu), `bloquear`, `ayuda`. Cualquier otra cosa se la pregunta a Claude, que contesta **sin herramientas**: no lee tus archivos ni corre comandos. **También le podés mandar una nota de voz** (el clip de la app ntfy): la transcribe en la compu y hace lo que dijiste. |
| **Pregunta rápida** (`claude-siri "…"`) | Respuesta corta para leer en voz alta, por SSH desde un Atajo del iPhone o desde Android (Termux, Tasker). Ver [docs/CELULAR.md](docs/CELULAR.md). |
| **Estado** (`claude-estado`) | Servicios, qué se mergeó hoy, PRs abiertos y cupo, en una pantalla corta. |
| **Anotar** (`claude-anotar "…"`) | Guarda un pendiente con fecha y proyecto; lo clasifica solo. Para dictar. |
| **Autorizar** (`claude-permitir`) | Deja pasar una vez el último comando que frenó el freno de mano. A la tercera te ofrece dejarlo fijo. |

---

## 🏠 Casa

| Gadget | Qué hace |
|---|---|
| **Luces y enchufes** (`claude-casa`) | Maneja las llaves de luz y enchufes Tuya / Smart Life **por la red de casa**, sin la nube. `claude-casa` muestra cómo está todo; `claude-casa prender adelante`, `apagar atrás 2` (sólo la tecla 2), `cambiar dormitorio`; o en castellano: `claude-casa "apagá todo menos atrás"`. Desde el teléfono: `casa`, `prendé la luz de adelante`, también con nota de voz. En el menú: *Luces y enchufes de casa*. Las llaves locales salen una sola vez de tu cuenta de iot.tuya.com. |

---

## 💻 En la terminal

Hace falta abrir una terminal nueva después de instalar.

| Qué escribís | Qué hace |
|---|---|
| `Ctrl+G` | Escribís en castellano lo que querés hacer («comprimí esta carpeta sin los node_modules»), apretás `Ctrl+G` y la línea se cambia por el comando. No lo ejecuta: lo revisás vos. |
| `ups` | Por qué falló el último comando y cómo arreglarlo. `ups -r` lo corre de nuevo para leer el error. |
| `comando 2>&1 \| explica` | Explica la salida de cualquier comando. |
| `avisame comando…` | Corre un comando largo y te avisa cuando termina (al teléfono si no estás). Si falla, te dice por qué en una frase. |
| `claude-commit` | Escribe el mensaje de commit con el estilo del repo a partir de lo que está en stage, y pregunta antes de commitear. |
| `claude-como "…"` | «¿Cómo hago…?» → el comando suelto. |
| `claude-local "…"` | Le pregunta al **modelo local** (Ollama) en vez de a Claude: gratis, sin internet y sin gastar cupo. Más limitado, pero para traducir o una duda rápida alcanza. `cat texto \| claude-local "resumilo"`. |
| `claude-alterminar [suspender\|apagar]` | Espera a que ninguna sesión de Claude esté trabajando y avisa, suspende o apaga. |

---

## 📁 Sobre archivos y textos

| Gadget | Cómo | Qué hace |
|---|---|---|
| **Preguntarle a Claude** | Clic derecho → *Scripts* | Le preguntás algo sobre un archivo; la respuesta se abre en tu editor. |
| **Renombrar con Claude** | Clic derecho → *Scripts*, o `claude-renombrar archivos…` | Mira `IMG_4821.jpg` o `descarga (2).pdf` y propone nombres que dicen qué son. Tildás cuáles aceptar; `--deshacer` vuelve atrás. |
| **Resumir con Claude** | Clic derecho → *Scripts*, o `claude-resumir link\|archivo` | Resume una página web, PDF, documento de Word o texto en 3 a 6 puntos. `-p "¿qué plazos hay?"` le pregunta algo puntual. Desde el menú, resume el link que tengas copiado. |
| **Transcribir audio** | Clic derecho → *Scripts*, o `claude-dictar audio.ogg` | Pasa a texto una nota de voz de WhatsApp, una grabación o una reunión, local. El texto queda copiado. |
| **Ordenar Descargas** | `claude-descargas` o el menú | Propone en qué subcarpeta va cada cosa suelta (Facturas, Fotos, Instaladores…). Sólo mira nombres y tipos, no el contenido. Tildás qué mover; `--deshacer` vuelve todo atrás. |
| **Buzón** | Carpeta «Para Claude» | Ver *Corren solos*. |

---

## 📊 Tus números con Claude Code

| Comando | Qué muestra |
|---|---|
| `claude-horas` | Cuánto le dedicaste a cada proyecto, por día o mes (`--csv` para la planilla). |
| `claude-panel` | Una página local con tiempo por día y proyecto, pedidos y costo estimado. |
| `claude-buscar "…"` | Busca en todo lo que ya trabajaste y te dice de qué día y proyecto lo sacó. |
| `claude-retomar` | Tus últimas sesiones con su tema; elegís una y la reabre. |
| `claude-pr` | Tiempo y pedidos que costó cada PR mergeado. |
| `claude-ritmo` | Horas por semana, qué días rendís y cuánto viven tus PRs. |
| `claude-decisiones` | Saca de las sesiones qué decidiste y por qué, a un `DECISIONES.md`. |
| `claude-limpiar` | Qué ocupa disco de lo que deja Claude Code y cómo liberarlo. |

---

## 🚀 Lanzador y escritorio

| Gadget | Qué hace |
|---|---|
| **Ulauncher** | `c ¿cuánto es 30 dólares en pesos?` + Enter: la respuesta en el lanzador. `r mañana 18:30 partido`: un recordatorio. |
| **Statusline** | Abajo de cada sesión: `modelo · carpeta (rama*) · ctx 25% · 5h 3% · 7d 45% · $1.23`. |
| **Extensión de GNOME** | En Wayland, le cuenta a los avisos qué ventana tiene el foco, para no avisarte de lo que estás mirando. |

---

*Este archivo se actualiza cada vez que se suma un gadget. Lo que está prendido en tu compu lo dice `gadget`.*
