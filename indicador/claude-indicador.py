#!/usr/bin/env python3
"""Indicador de la bandeja: % de uso de la sesión (ventana de 5 h) y de la
semana de Claude, las sesiones que te están esperando y, opcional, si tu
servicio responde.

El uso lo deja ~/.claude/statusline.sh en ~/.claude/estado/uso.json cada vez
que corre una sesión de Claude Code; las sesiones las deja hooks/avisar.sh.

Usa AppIndicator (Ayatana): anda tal cual en Ubuntu, KDE, XFCE, Cinnamon y
MATE. En GNOME «puro» (Debian) hace falta la extensión AppIndicator.
"""
import json
import os
import pathlib
import subprocess
import threading
import time
import urllib.request
from datetime import datetime

import gi

gi.require_version("Gtk", "3.0")
try:
    gi.require_version("AyatanaAppIndicator3", "0.1")
    from gi.repository import AyatanaAppIndicator3 as AppIndicator
except (ValueError, ImportError):
    gi.require_version("AppIndicator3", "0.1")
    from gi.repository import AppIndicator3 as AppIndicator
from gi.repository import GLib, Gtk  # noqa: E402

CASA = pathlib.Path.home()
EST = pathlib.Path(os.environ.get("CLAUDE_ESTADO", CASA / ".claude" / "estado"))
CONF = CASA / ".config" / "claude-gadgets" / "config"
ICONOS = pathlib.Path(os.environ.get("XDG_CACHE_HOME", CASA / ".cache")) / "claude-gadgets" / "iconos"
LIMPIAR = CASA / ".claude" / "gadgets" / "bin" / "claude-limpiar-estado"
GADGETS = CASA / ".claude" / "gadgets" / "bin" / "claude-gadgets"
DIAS = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]
CADA = 30          # segundos entre refrescos
CADA_HUB = 60      # segundos entre consultas al servicio

# El ícono normal es «symbolic»: el escritorio lo pinta del color del panel.
SVG = ('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">'
       '<g fill="%s">' + "".join(
           '<rect x="7" y="1.5" width="2" height="13" rx="1" transform="rotate(%d 8 8)"/>' % g
           for g in (0, 45, 90, 135)) + "</g></svg>")
COLORES = {"claude-gadgets-symbolic": "#bebebe", "claude-gadgets-alerta": "#E8590C",
           "claude-gadgets-critico": "#E03131"}


def escribir_iconos():
    ICONOS.mkdir(parents=True, exist_ok=True)
    for nombre, color in COLORES.items():
        (ICONOS / (nombre + ".svg")).write_text(SVG % color)


def leer_config():
    """HUB_URL, HUB_NOMBRE y LINKS salen de la config, que es un archivo de bash."""
    if not CONF.exists():
        return "", "Servicio", []
    guion = '. "$1" 2>/dev/null; printf "%s\\n" "${HUB_URL:-}" "${HUB_NOMBRE:-Servicio}" "${LINKS[@]}"'
    try:
        lineas = subprocess.run(["bash", "-c", guion, "config", str(CONF)], capture_output=True,
                                text=True, timeout=5).stdout.splitlines()
    except (OSError, subprocess.SubprocessError):
        return "", "Servicio", []
    lineas += ["", ""]
    links = [l.split("=", 1) for l in lineas[2:] if "=" in l]
    return lineas[0], lineas[1] or "Servicio", links


def leer_herramientas():
    """El menú de gadgets (id, título) lo define claude-gadgets: una sola lista para todos."""
    try:
        salida = subprocess.run([str(GADGETS), "--lista"], capture_output=True, text=True, timeout=5).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    return [l.split("|", 1) for l in salida.splitlines() if "|" in l]


def a_epoch(v):
    """resets_at puede venir en epoch o en ISO-8601, según la versión."""
    if v in (None, ""):
        return None
    try:
        return int(float(v))
    except (TypeError, ValueError):
        try:
            return int(datetime.fromisoformat(str(v).replace("Z", "+00:00")).timestamp())
        except ValueError:
            return None


def cuando(ts):
    d = datetime.fromtimestamp(ts)
    if d.date() == datetime.now().date():
        return d.strftime("hoy %H:%M")
    return "%s %s" % (DIAS[d.weekday()], d.strftime("%d %H:%M"))


def barra(p):
    llenos = max(0, min(10, int(p) // 10))
    return "▰" * llenos + "▱" * (10 - llenos)


def leer_uso(ahora):
    for nombre in ("uso.json", "statusline-ultimo.json"):
        f = EST / nombre
        try:
            d = json.loads(f.read_text())
        except (OSError, ValueError):
            continue
        rl = d.get("rate_limits") or {}
        if not rl:
            continue
        fila = {"ts": d.get("ts") or int(f.stat().st_mtime)}
        for clave, nombre_v in (("p5", "five_hour"), ("p7", "seven_day")):
            v = rl.get(nombre_v) or {}
            p, r = v.get("used_percentage"), a_epoch(v.get("resets_at"))
            if r and ahora >= r:      # la ventana ya se renovó: el uso volvió a 0
                p, r = 0, None
            fila[clave] = None if p is None else round(float(p))
            fila["r" + clave[1]] = r
        return fila
    return None


def leer_sesiones(ahora):
    filas = []
    for f in sorted(EST.glob("sesion-*.json")):
        try:
            d = json.loads(f.read_text())
            edad = (ahora - int(d.get("ts", ahora))) // 60
        except (OSError, ValueError, TypeError):
            continue
        estado = d.get("estado", "")
        if estado == "trabajando" and edad > 120:   # sesión colgada
            continue
        icono = {"esperando": "🟠", "trabajando": "⚙️"}.get(estado, "✅")
        mensaje = " ".join(str(d.get("mensaje") or "").split()) if estado == "esperando" else ""
        filas.append((icono, d.get("proyecto", "?"), estado, int(edad), mensaje))
    return filas


class Indicador:
    def __init__(self):
        escribir_iconos()
        self.ind = AppIndicator.Indicator.new(
            "claude-gadgets", "claude-gadgets-symbolic", AppIndicator.IndicatorCategory.APPLICATION_STATUS)
        self.ind.set_icon_theme_path(str(ICONOS))
        self.ind.set_title("Claude Code")
        self.ind.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        self.hub_url, self.hub_nombre, self.links = leer_config()
        self.herramientas = leer_herramientas()
        self.hub = None          # último código HTTP, o "sin respuesta"
        self.hub_ts = 0
        self.firma = None
        self.refrescar()
        GLib.timeout_add_seconds(CADA, self.refrescar)

    # ── Servicio propio (opcional): en un hilo, para no congelar el menú ──────
    def mirar_hub(self):
        try:
            pedido = urllib.request.Request(self.hub_url, headers={"Accept": "text/plain"})
            with urllib.request.urlopen(pedido, timeout=5) as r:
                codigo = r.status
        except urllib.error.HTTPError as e:
            codigo = e.code
        except Exception:
            codigo = "sin respuesta"
        self.hub = codigo
        GLib.idle_add(self.pintar)

    def refrescar(self, *_):
        self.hub_url, self.hub_nombre, self.links = leer_config()
        if self.hub_url and time.time() - self.hub_ts >= CADA_HUB:
            self.hub_ts = time.time()
            threading.Thread(target=self.mirar_hub, daemon=True).start()
        if not self.hub_url:
            self.hub = None
        self.pintar()
        return True

    def pintar(self):
        ahora = int(time.time())
        uso, sesiones = leer_uso(ahora), leer_sesiones(ahora)
        esperan = sum(1 for s in sesiones if s[2] == "esperando")
        caido = self.hub is not None and self.hub != 200
        edad_dato = (ahora - int(uso["ts"])) // 60 if uso else None
        firma = (json.dumps(uso, sort_keys=True), sesiones, self.hub, self.hub_url, self.hub_nombre,
                 self.links, edad_dato)
        if firma == self.firma:      # nada cambió: no rehago el menú (se cerraría si lo tenés abierto)
            return False
        self.firma = firma

        # ── Título ────────────────────────────────────────────────────────────
        titulo, peor = "", 0
        if uso and (uso["p5"] is not None or uso["p7"] is not None):
            p5, p7 = uso["p5"] or 0, uso["p7"] or 0
            titulo, peor = "%d%% · %d%%" % (p5, p7), max(p5, p7)
        if esperan:
            titulo = (titulo + "  🟠%d" % esperan).strip()
        if caido:
            titulo = (titulo + "  🔴").strip()
        icono = "claude-gadgets-symbolic"
        if peor >= 80 or caido:
            icono = "claude-gadgets-critico"
        elif peor >= 50 or esperan:
            icono = "claude-gadgets-alerta"
        self.ind.set_icon_full(icono, "Claude Code")
        self.ind.set_label(titulo, "100% · 100%  🟠9")
        self.ind.set_title(("Claude Code · " + titulo) if titulo else "Claude Code")   # donde no hay texto, queda al pasar el mouse

        # ── Menú ──────────────────────────────────────────────────────────────
        menu = Gtk.Menu()

        def texto(t):
            i = Gtk.MenuItem(label=t)
            i.set_sensitive(False)
            menu.append(i)

        def accion(t, fn):
            i = Gtk.MenuItem(label=t)
            i.connect("activate", fn)
            menu.append(i)

        def link(t, url):
            accion(t, lambda *_: subprocess.Popen(["xdg-open", url]))

        texto("Uso de Claude")
        if titulo and uso and (uso["p5"] is not None or uso["p7"] is not None):
            for nombre, clave, r in (("Sesión (5 h)", "p5", "r5"), ("Semana (7 d)", "p7", "r7")):
                p = uso[clave] or 0
                texto("%s   %s  %d%%" % (nombre, barra(p), p))
                if uso[r]:
                    texto("      se renueva %s" % cuando(uso[r]))
            texto("Dato de hace %d min (se actualiza al usar Claude Code)" % edad_dato)
        else:
            texto("Sin datos todavía: abrí una sesión de Claude Code")
        menu.append(Gtk.SeparatorMenuItem())
        texto("Sesiones")
        if not sesiones:
            texto("Ninguna activa")
        for icono_s, proyecto, estado, edad, mensaje in sesiones:
            texto("%s %s — %s (hace %dm)" % (icono_s, proyecto, estado, edad))
            if mensaje:
                texto("      %s" % mensaje[:90])
        if self.hub_url:
            menu.append(Gtk.SeparatorMenuItem())
            if self.hub == 200:
                link("🟢 %s: OK" % self.hub_nombre, self.hub_url)
            else:
                link("🔴 %s: %s" % (self.hub_nombre, self.hub or "consultando…"), self.hub_url)
        for nombre, url in self.links:
            link(nombre, url)
        menu.append(Gtk.SeparatorMenuItem())
        if self.herramientas:
            sub = Gtk.Menu()
            for ident, nombre in self.herramientas:
                i = Gtk.MenuItem(label=nombre)
                i.connect("activate", lambda _w, x=ident: subprocess.Popen([str(GADGETS), "--correr", x],
                                                                           start_new_session=True))
                sub.append(i)
            raiz = Gtk.MenuItem(label="Gadgets")
            raiz.set_submenu(sub)
            menu.append(raiz)
        link("Ver uso en claude.ai", "https://claude.ai/settings/usage")
        accion("Limpiar sesiones colgadas", self.limpiar)
        accion("Refrescar", self.forzar)
        accion("Salir", lambda *_: Gtk.main_quit())
        menu.show_all()
        self.ind.set_menu(menu)
        return False

    def limpiar(self, *_):
        subprocess.run([str(LIMPIAR)], check=False)
        self.forzar()

    def forzar(self, *_):
        self.firma, self.hub_ts = None, 0
        self.refrescar()


if __name__ == "__main__":
    Indicador()
    Gtk.main()
