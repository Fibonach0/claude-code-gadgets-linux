"""Luces y enchufes Tuya / Smart Life por la red de casa (TinyTuya). Lo usa claude-casa.
   python casa.py <devices.json> [snapshot.json] estado
   python casa.py <devices.json> [snapshot.json] lista              nombres, para Claude
   python casa.py <devices.json> [snapshot.json] on|off|cambiar <nombre> [tecla]
devices.json: el que arma `python -m tinytuya wizard` (id, name, key, ip, version).
snapshot.json (opcional): el de `tinytuya scan`, para completar IP y versión."""
import json, signal, sys, unicodedata
signal.signal(signal.SIGPIPE, signal.SIG_DFL)   # `claude-casa | head` sin errores
import tinytuya

TIPO = {"kg": "llave", "cz": "enchufe", "pc": "zapatilla", "dj": "luz", "dd": "tira de luz", "fs": "ventilador", "pir": "sensor"}

def plano(s):
    return "".join(c for c in unicodedata.normalize("NFD", (s or "").lower()) if unicodedata.category(c) != "Mn").strip()

def cargar(dev_f, snap_f):
    devs = json.load(open(dev_f))
    snap = {}
    if snap_f:
        try:
            raw = json.load(open(snap_f)); raw = raw.get("devices", raw) if isinstance(raw, dict) else raw
            snap = {d["id"]: d for d in raw if d.get("id")}
        except (OSError, ValueError):
            pass
    nombres = [d.get("name") or d["id"] for d in devs]
    out = []
    for d, n in zip(devs, nombres):
        s = snap.get(d["id"], {})
        tipo = TIPO.get(d.get("category"), d.get("category") or "")
        etiqueta = n if nombres.count(n) == 1 else f"{n} ({tipo})"
        out.append(dict(d, etiqueta=etiqueta, tipo=tipo,
                        ip=d.get("ip") or s.get("ip"),
                        ver=float(d.get("version") or d.get("ver") or s.get("ver") or s.get("version") or 3.3)))
    return out

def conectar(d):
    dev = tinytuya.Device(d["id"], d["ip"], d["key"], version=d["ver"])
    dev.set_socketTimeout(4); dev.set_socketRetryLimit(1)
    return dev

def teclas(dps, categoria):
    if categoria in ("dj", "dd") and "20" in dps:
        return ["20"]
    return sorted((k for k, v in dps.items() if isinstance(v, bool) and k.isdigit() and int(k) <= 8), key=int)

def buscar(devs, nombre):
    q = plano(nombre)
    exactos = [d for d in devs if plano(d["etiqueta"]) == q or plano(d.get("name")) == q]
    if len(exactos) == 1: return exactos[0]
    parciales = [d for d in devs if q and q in plano(d["etiqueta"])]
    if len(parciales) == 1: return parciales[0]
    if exactos or parciales:
        sys.exit("¿Cuál? " + " · ".join(d["etiqueta"] for d in (exactos or parciales)))
    sys.exit(f"No conozco «{nombre}». Tengo: " + " · ".join(d["etiqueta"] for d in devs))

def estado(devs):
    for d in devs:
        if d.get("category") == "pir" or not d.get("ip") or not d.get("key"):
            print(f"  · {d['etiqueta']}: {d['tipo'] or 'sin control local'}"); continue
        st = conectar(d).status()
        dps = st.get("dps") if isinstance(st, dict) else None
        if not dps:
            print(f"  ✗ {d['etiqueta']}: no contesta (¿sin corriente o cambió de IP?)"); continue
        ts = teclas(dps, d.get("category"))
        if len(ts) == 1:
            print(f"  {'●' if dps[ts[0]] else '○'} {d['etiqueta']}: {'prendida' if dps[ts[0]] else 'apagada'}")
        else:
            print(f"  {'●' if any(dps[t] for t in ts) else '○'} {d['etiqueta']}: " + ", ".join(f"tecla {t} {'prendida' if dps[t] else 'apagada'}" for t in ts))

def mover(devs, accion, nombre, tecla=None):
    d = buscar(devs, nombre)
    if not d.get("ip") or not d.get("key"):
        sys.exit(f"{d['etiqueta']}: no lo puedo manejar por la red de casa.")
    dev = conectar(d)
    st = dev.status(); dps = st.get("dps") if isinstance(st, dict) else None
    if not dps:
        sys.exit(f"{d['etiqueta']}: no contesta (¿sin corriente?)")
    ts = teclas(dps, d.get("category"))
    if tecla:
        if tecla not in ts: sys.exit(f"{d['etiqueta']} tiene teclas {', '.join(ts)}")
        ts = [tecla]
    hechas = []
    for t in ts:
        nuevo = {"on": True, "off": False}.get(accion, not dps[t])
        dev.set_value(int(t), nuevo) if t != "20" else dev.set_value(20, nuevo)
        hechas.append(nuevo)
    que = "prendí" if all(hechas) else "apagué" if not any(hechas) else "cambié"
    print(f"✓ {que.capitalize()} {d['etiqueta']}" + (f" (tecla {tecla})" if tecla else ""))

if __name__ == "__main__":
    a = sys.argv[1:]
    dev_f = a.pop(0)
    snap_f = a.pop(0) if a and a[0].endswith(".json") else None
    devs = cargar(dev_f, snap_f)
    orden = a.pop(0) if a else "estado"
    if orden == "estado": estado(devs)
    elif orden == "lista":
        for d in devs: print(f"{d['etiqueta']}\t{d['tipo']}")
    elif orden in ("on", "off", "cambiar") and a:
        tecla = a.pop() if len(a) > 1 and a[-1].isdigit() else None
        mover(devs, orden, " ".join(a), tecla)
    else:
        sys.exit(__doc__)
