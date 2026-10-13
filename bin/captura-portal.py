#!/usr/bin/env python3
"""Saca una captura con el portal de escritorio (anda en Wayland: GNOME, KDE…)
y escribe en la salida la ruta del archivo. Sin argumentos te deja elegir el
recorte; con --entera saca la pantalla completa sin preguntar.
Sale con 1 si cancelaste o no hay portal."""
import sys
import urllib.parse

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
ficha = "claude%d" % GLib.random_int_range(1, 1 << 30)
remitente = bus.get_unique_name()[1:].replace(".", "_")
pedido = "/org/freedesktop/portal/desktop/request/%s/%s" % (remitente, ficha)
bucle = GLib.MainLoop()
salida = {"codigo": 1}


def respuesta(_bus, _remitente, _ruta, _interfaz, _senal, parametros):
    codigo, datos = parametros.unpack()
    if codigo == 0 and datos.get("uri"):
        print(urllib.parse.unquote(urllib.parse.urlparse(datos["uri"]).path))
        salida["codigo"] = 0
    bucle.quit()


bus.signal_subscribe("org.freedesktop.portal.Desktop", "org.freedesktop.portal.Request", "Response",
                     pedido, None, Gio.DBusSignalFlags.NONE, respuesta)
opciones = {"handle_token": GLib.Variant("s", ficha),
            "interactive": GLib.Variant("b", "--entera" not in sys.argv)}
try:
    bus.call_sync("org.freedesktop.portal.Desktop", "/org/freedesktop/portal/desktop",
                  "org.freedesktop.portal.Screenshot", "Screenshot",
                  GLib.Variant("(sa{sv})", ("", opciones)), None, Gio.DBusCallFlags.NONE, 5000, None)
except GLib.Error:
    sys.exit(1)
GLib.timeout_add_seconds(300, bucle.quit)
bucle.run()
sys.exit(salida["codigo"])
