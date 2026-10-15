"""Audio → texto con faster-whisper, local. Lo usa claude-dictar.
   python transcribir.py <modelo> <idioma> <archivo>"""
import sys
from faster_whisper import WhisperModel

modelo, idioma, archivo = sys.argv[1:4]
m = WhisperModel(modelo, device="cpu", compute_type="int8")
partes, _ = m.transcribe(archivo, language=None if idioma == "auto" else idioma, vad_filter=True, beam_size=5)
print(" ".join(p.text.strip() for p in partes).strip())
