# Claude desde el celular

El teléfono entra por SSH a la compu, corre `claude-siri "<lo que dijiste>"` y te lee la respuesta.
Lo mismo sirve para `claude-anotar`, `claude-cola`, `claude-estado`, `claude-brief` y `claude-permitir`.

## 1. En la compu: activar SSH (una vez)

```bash
sudo apt install openssh-server
sudo systemctl enable --now ssh
```

Para probarlo desde la misma máquina: `ssh $(whoami)@localhost claude-siri "hola"`.

A diferencia de la Mac, acá no hace falta un token aparte: el login de Claude Code vive en
`~/.claude` y por SSH se encuentra igual. Si entrás con otro usuario o desde un contenedor, sí:
`claude setup-token` y guardá el resultado en `~/.config/claude-gadgets/token` (con `chmod 600`).
Ese token es como una contraseña: no lo compartas ni lo subas a ningún repo.

Los conectores de claude.ai (Calendar, Railway…) no están disponibles por SSH. Por eso `claude-jobs`
y `claude-brief --generar` corren en la compu con un timer, y el teléfono sólo lee el resultado.

## 2. Desde afuera de casa: Tailscale (opcional, recomendado)

1. Instalá Tailscale en la compu (`curl -fsSL https://tailscale.com/install.sh | sh`, después `sudo tailscale up`) y en el teléfono.
2. Iniciá sesión con la misma cuenta en los dos.
3. Anotá el nombre de la compu en Tailscale, por ejemplo `mi-compu`, o su IP `100.x.y.z`.

Así anda desde cualquier red, sin abrir puertos. Si sólo lo vas a usar en tu wifi, alcanza con la IP local.

> Para que conteste, la compu tiene que estar prendida y sin suspender. Si es una notebook, revisá
> *Configuración → Energía → Suspensión automática*.

## 3a. iPhone: el Atajo

App **Atajos** → **+** → nombralo **Consulta Claude** (esa frase es la que le decís a Siri).

> No lo llames "Preguntale a Claude" ni "Mandale a…": Siri entiende "preguntale a X" como un mensaje a un contacto y abre WhatsApp o Mensajes en vez del Atajo.

1. Acción **Dictar texto** (idioma: Español).
2. Acción **Ejecutar script por SSH**:
   - Anfitrión: `mi-compu` (Tailscale) o la IP
   - Puerto: `22`
   - Usuario: tu usuario de Linux, exacto (lo ves con `whoami`)
   - Autenticación: **Clave SSH**. Tocá "Clave SSH" → *Generar* → *Compartir clave pública*, y agregá esa línea en la compu, en `~/.ssh/authorized_keys` (ver abajo).
   - Script: `~/.local/bin/claude-siri` (sólo eso, sin comillas ni variables)
   - Entrada: **Texto dictado**. La pregunta le llega a `claude-siri` por la entrada, así no se rompe con comillas o apóstrofes.
3. Acción **Mostrar resultado** con el *Resultado del shell*. Lanzado por voz, Siri lo lee en voz alta.

> No uses **Leer texto** como último paso: lanzado desde Siri muchas veces no suena y Siri sólo dice "Hecho".

## 3b. Android

No lo probé en un teléfono; es el mismo comando por SSH, así que cualquiera de estas dos formas alcanza:

- **Termux** (F-Droid): `pkg install openssh`, `ssh-keygen`, y copiá `~/.ssh/id_ed25519.pub` a la compu.
  Después `ssh usuario@mi-compu claude-siri "¿qué se mergeó ayer?"`. Con *Termux:Widget* queda como
  botón en la pantalla de inicio, y con *Termux:API* (`termux-speech-to-text`, `termux-tts-speak`)
  lo dictás y te lo lee.
- **Tasker** o **HTTP Shortcuts** con un plugin de SSH: dictado → comando → leer el resultado.

## Agregar la clave en la compu

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
echo 'ssh-ed25519 AAAA… la clave pública del teléfono' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

## 4. Probar

"Oye Siri, consulta Claude" → "¿qué cambió hoy en mi-proyecto?"

`claude-siri` usa Sonnet (rápido) y sólo puede **leer**: archivos de tus proyectos, la web, y git en modo lectura (`git -C <repo> log/status/diff/show/branch`, `gh pr list/view`), con la ruta de cada repo fija en el permiso. No puede modificar archivos ni correr otros comandos. Tarda unos 5 a 20 segundos.

En la config: `CLAUDE_SIRI_DIR` (carpeta principal, por defecto `~/proyectos`), `CLAUDE_SIRI_EXTRA` (carpetas extra) y `CLAUDE_SIRI_MODELO`.

## Seguridad

- La clave SSH del teléfono da acceso a tu usuario. Si perdés el teléfono, borrala de `~/.ssh/authorized_keys`.
- Con Tailscale, la compu no queda expuesta a internet; sólo la ven tus dispositivos.
- Conviene apagar el login por contraseña: `PasswordAuthentication no` en `/etc/ssh/sshd_config`.

## Al revés: que la compu te avise al teléfono

`claude-celular --instalar` hace que los avisos (Claude te espera, falló un servicio, se acaba el cupo) te lleguen al teléfono por [ntfy](https://ntfy.sh) cuando la compu está bloqueada o sin uso. No necesita SSH ni Tailscale: sólo la app ntfy suscripta al tema que te muestra el comando.
