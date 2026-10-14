"""Claude en Ulauncher: «c ¿cuánto falta para el feriado?» + Enter.

La pregunta la contesta claude-siri (corto, sin markdown, sólo lectura y web).
Con «c » a secas vuelve a mostrar la última respuesta; Enter sobre la
respuesta la copia al portapapeles.

«r en 20 minutos sacar la pizza» + Enter deja un recordatorio (claude-recordar);
«r » a secas muestra los pendientes.
"""
import os
import subprocess
import textwrap
import threading

from ulauncher.api.client.EventListener import EventListener
from ulauncher.api.client.Extension import Extension
from ulauncher.api.shared.Response import Response
from ulauncher.api.shared.action.CopyToClipboardAction import CopyToClipboardAction
from ulauncher.api.shared.action.ExtensionCustomAction import ExtensionCustomAction
from ulauncher.api.shared.action.RenderResultListAction import RenderResultListAction
from ulauncher.api.shared.event import ItemEnterEvent, KeywordQueryEvent
from ulauncher.api.shared.item.ExtensionResultItem import ExtensionResultItem
from ulauncher.api.shared.item.ExtensionSmallResultItem import ExtensionSmallResultItem

ICONO = "images/icon.svg"
BIN = os.path.expanduser("~/.claude/gadgets/bin")
ANCHO = 62         # caracteres por renglón: el lanzador corta los textos largos
RENGLONES = 9
ESPERA = 180       # segundos


def cartel(titulo, detalle=""):
    return RenderResultListAction([ExtensionResultItem(icon=ICONO, name=titulo, description=detalle,
                                                       highlightable=False, on_enter=None)])


def mostrar(pregunta, respuesta):
    renglones = textwrap.wrap(" ".join(respuesta.split()), ANCHO) or ["(sin respuesta)"]
    if len(renglones) > RENGLONES:
        renglones = renglones[:RENGLONES - 1] + ["… (Enter copia la respuesta entera)"]
    copiar = CopyToClipboardAction(respuesta)
    items = [ExtensionSmallResultItem(icon=ICONO, name=r, highlightable=False, on_enter=copiar) for r in renglones]
    return RenderResultListAction(items)


def preguntar(pregunta):
    try:
        r = subprocess.run([os.path.join(BIN, "claude-siri"), pregunta], capture_output=True, text=True,
                           timeout=ESPERA, stdin=subprocess.DEVNULL)
        return r.stdout.strip() or r.stderr.strip() or "Claude no contestó nada."
    except subprocess.TimeoutExpired:
        return "Claude tardó demasiado y corté la espera."
    except OSError:
        return "No encuentro claude-siri: ¿están instalados los gadgets?"


def correr(comando, *args):
    try:
        r = subprocess.run([os.path.join(BIN, comando), *args], capture_output=True, text=True,
                           timeout=60, stdin=subprocess.DEVNULL)
        return [l.strip() for l in (r.stdout or r.stderr).splitlines() if l.strip()]
    except (OSError, subprocess.SubprocessError):
        return ["No pude correr %s: ¿están instalados los gadgets?" % comando]


def renglones(lineas):
    return RenderResultListAction([ExtensionSmallResultItem(icon=ICONO, name=l[:90], highlightable=False, on_enter=None)
                                   for l in lineas[:RENGLONES]])


class Claude(Extension):
    def __init__(self):
        super().__init__()
        self.ultima = None      # (pregunta, respuesta)
        self.subscribe(KeywordQueryEvent, AlEscribir())
        self.subscribe(ItemEnterEvent, AlEnter())

    def recordar(self, evento, pedido):
        self._client.send(Response(evento, renglones(correr("claude-recordar", *pedido.split())[-1:])))

    def contestar(self, evento, pregunta):
        respuesta = preguntar(pregunta)
        self.ultima = (pregunta, respuesta)
        # Si mientras tanto cambiaste lo escrito o cerraste el lanzador, Ulauncher descarta esto…
        self._client.send(Response(evento, mostrar(pregunta, respuesta)))
        # …y por eso también va como notificación.
        if self.preferences.get("notificar", "si") == "si":
            subprocess.Popen(["bash", "-c", '. "$1/comun.sh" && notificar "$2" "$3"', "claude", BIN,
                              pregunta[:80], respuesta])


class AlEscribir(EventListener):
    def on_event(self, event, extension):
        pregunta = (event.get_argument() or "").strip()
        if event.get_keyword() == extension.preferences.get("recordar", "r"):
            if not pregunta:
                return renglones(correr("claude-recordar"))
            return RenderResultListAction([ExtensionResultItem(
                icon=ICONO, name="Recordarme", description=pregunta, highlightable=False,
                on_enter=ExtensionCustomAction({"recordar": pregunta}, keep_app_open=True))])
        if not pregunta:
            if extension.ultima:
                return mostrar(*extension.ultima)
            return cartel("Preguntale a Claude", "Escribí la pregunta y apretá Enter")
        return RenderResultListAction([ExtensionResultItem(
            icon=ICONO, name="Preguntarle a Claude", description=pregunta, highlightable=False,
            on_enter=ExtensionCustomAction(pregunta, keep_app_open=True))])


class AlEnter(EventListener):
    def on_event(self, event, extension):
        pregunta = event.get_data()
        if isinstance(pregunta, dict):
            threading.Thread(target=extension.recordar, args=(event, pregunta["recordar"]), daemon=True).start()
            return cartel("Anotando el recordatorio…", pregunta["recordar"])
        # En un hilo: si no, el lanzador queda sordo hasta que Claude termine.
        threading.Thread(target=extension.contestar, args=(event, pregunta), daemon=True).start()
        return cartel("Claude está pensando…", pregunta)


if __name__ == "__main__":
    Claude().run()
