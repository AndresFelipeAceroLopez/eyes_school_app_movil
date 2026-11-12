"""Genera el CSV para importar en Azure Boards los defectos de la app móvil (PR-07).

Fuentes (no se escriben datos a mano aquí, salvo el estado, el origen y la ronda de cada defecto):
  - Defectos conocidos DEF-029 a DEF-035: tabla de la sección 4 de planeacion-gestion-defectos-app.md
  - Defectos nuevos N-xx: tabla 7.2 del informe de resultados

    python planeacion/test/GestionDefectos/generar_csv_azure_boards.py

Reglas de la importación por CSV de Azure Boards (learn.microsoft.com, «Import or update work items
in bulk by using CSV files»):
  - Los elementos nuevos necesitan «Work Item Type» y «Title».
  - Todo elemento nuevo entra en el estado inicial (New); el estado no se puede fijar al importar.
    Por eso los que ya están corregidos y verificados llevan la etiqueta `cerrar-done`: después de
    importar se filtran por esa etiqueta y se pasan a Done en bloque.
  - Se dejan fuera ID, Assigned To y State en los elementos nuevos.
  - Los campos admiten HTML; los saltos de línea se escriben con <p>…</p>.

Se excluyen los defectos solo del backend (N-04, N-13, N-23): el backend gestiona los suyos en GitHub
Issues. R-N1 es un riesgo, no un defecto. El CSV no contiene credenciales.
"""

from __future__ import annotations

import csv
import html
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[3]
PLAN = RAIZ / "planeacion/test/GestionDefectos/planeacion-gestion-defectos-app.md"
INFORME = RAIZ / "planeacion/test/Resultados/INFORME_RESULTADOS_PRUEBAS_APP.md"
DESTINO = RAIZ / "planeacion/test/Resultados/evidencias/PR-07/defectos_azure_boards_app.csv"

SEVERIDAD = {"Crítica": "1 - Critical", "Alta": "2 - High", "Media": "3 - Medium", "Baja": "4 - Low"}
# Prioridad propuesta por QA (sección 3 de la planeación); el PO la confirma o la cambia.
PRIORIDAD = {"Crítica": "1", "Alta": "2", "Media": "3", "Baja": "4"}

SOLO_BACKEND = {"N-04", "N-13", "N-23"}

# Dónde se encontró cada defecto (etiqueta de origen de la sección 1 de la planeación).
ORIGEN = {
    **{f"DEF-0{n}": "revision-codigo" for n in range(29, 36)},
    "N-01": "pruebas-integracion", "N-02": "revision-codigo", "N-03": "revision-codigo",
    "N-05": "pruebas-integracion", "N-06": "revision-codigo", "N-07": "pruebas-integracion",
    "N-08": "pruebas-integracion", "N-09": "pruebas-integracion", "N-10": "revision-codigo",
    "N-11": "pruebas-sistema", "N-12": "pruebas-sistema", "N-14": "pruebas-sistema",
    "N-15": "pruebas-sistema", "N-16": "pruebas-sistema", "N-17": "pruebas-sistema",
    "N-18": "pruebas-sistema", "N-19": "pruebas-sistema", "N-20": "pruebas-sistema",
    "N-21": "pruebas-sistema", "N-22": "pruebas-sistema", "N-24": "pruebas-sistema",
    "N-25": "pruebas-sistema", "N-26": "pruebas-sistema", "N-27": "uat", "N-28": "uat",
    "N-29": "uat", "N-30": "uat", "N-31": "pruebas-sistema",
}

# Ronda en que se encontró: S1 (11/11, develop f253eb0), S2 (regresión 12/11), S3 (12/11).
RONDA = {"N-25": "S2", "N-26": "S2", "N-27": "S3", "N-28": "S3", "N-29": "S3", "N-30": "S3", "N-31": "S3"}

CORREGIDO_S2 = "Corregido en develop (PR #16) y verificado en la regresión S2 (sección 8.2 del informe)."
CORREGIDO_S3 = "Corregido en develop (PR #31) con su prueba; verificado en el emulador con el APK de QA (sección 10)."
# Estado al 12/11/2026 y si ya puede pasar a Done.
ESTADO: dict[str, tuple[str, bool]] = {
    "DEF-029": ("Parcial: la firma de release está corregida y publicada (v1.1.0); el applicationId "
                "definitivo sigue pendiente por decisión del equipo (requiere registrar el paquete en Firebase).", False),
    **{d: (CORREGIDO_S2, True) for d in ("DEF-030", "DEF-031", "DEF-032", "DEF-033", "DEF-034", "DEF-035")},
    **{n: (CORREGIDO_S2, True) for n in (
        "N-01", "N-02", "N-03", "N-05", "N-06", "N-08", "N-09", "N-11", "N-12", "N-14", "N-15",
        "N-16", "N-17", "N-18", "N-19", "N-20", "N-21", "N-22", "N-24", "N-25")},
    "N-07": ("App corregida (PR #16) y datos de QA corregidos (scripts/qa/corregir_datos_asistencia.sql); "
             "verificado.", True),
    "N-10": ("Resuelto antes de llegar a un commit: la URL quedó con https (verificado el 11/11).", True),
    "N-26": ("Corregido en el workflow (PR #28) y APK arm64 retirado del release v1.1.0 (verificado).", True),
    **{n: (CORREGIDO_S3, True) for n in ("N-27", "N-28", "N-29", "N-30")},
    "N-31": ("Abierto: la API no distingue una cuenta pendiente de una desactivada (solo envía estado).", False),
}


def _limpia(texto: str) -> str:
    """Quita el formato Markdown de una celda (negritas, código, enlaces)."""
    texto = re.sub(r"\*\*(.+?)\*\*", r"\1", texto)
    texto = re.sub(r"`([^`]*)`", r"\1", texto)
    texto = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", texto)
    return texto.strip()


def _severidad(celda: str) -> str:
    for nivel in SEVERIDAD:
        if nivel in celda:
            return nivel
    raise SystemExit(f"Severidad no reconocida: {celda!r}")


def _filas(md: Path, prefijo: str, seccion: str) -> list[list[str]]:
    """Filas de la tabla bajo el encabezado [seccion], hasta el siguiente encabezado."""
    filas, dentro = [], False
    for linea in md.read_text(encoding="utf-8").splitlines():
        if linea.startswith("#"):
            dentro = linea.lstrip("#").strip().startswith(seccion)
            continue
        if dentro and linea.startswith(f"| {prefijo}"):
            filas.append([c.strip() for c in linea.strip().strip("|").split("|")])
    if not filas:
        raise SystemExit(f"No se encontró la tabla «{seccion}» en {md.name}")
    return filas


def defectos() -> list[dict[str, str]]:
    salida = []
    # Conocidos: | ID | Corrección | Título | Severidad | Prioridad | Caso | Asignado | Identificado | Sprint |
    for c in _filas(PLAN, "DEF-", "4. Defectos ya conocidos"):
        id_qa, correccion, titulo, sev, _prio, caso, _asig, fecha, _sprint = c[:9]
        salida.append({
            "id": id_qa, "titulo": titulo, "sev": _severidad(sev),
            "evidencia": f"Identificado el {fecha} en la revisión de código. Corrección planeada: {correccion}.",
            "caso": caso, "ronda": "S1",
        })
    # Nuevos (tabla 7.2): | ID | Título | Evidencia | Severidad | Componente |
    for c in _filas(INFORME, "N-", "7.2 Nuevos"):
        id_qa, titulo, evidencia, sev, componente = c[:5]
        if id_qa in SOLO_BACKEND:
            continue
        titulo = re.sub(r"\s*\((?:\*\*)?corregido[^)]*\)", "", titulo, flags=re.I)
        salida.append({
            "id": id_qa, "titulo": _limpia(titulo), "sev": _severidad(sev),
            "evidencia": f"{_limpia(evidencia).rstrip('.')}. Componente: {_limpia(componente)}.",
            "caso": "", "ronda": RONDA.get(id_qa, "S1"),
        })
    return salida


def main() -> None:
    filas = defectos()
    faltan = [d["id"] for d in filas if d["id"] not in ESTADO or d["id"] not in ORIGEN]
    if faltan:
        raise SystemExit(f"Sin estado u origen definido: {faltan}")

    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    columnas = ["Work Item Type", "Title", "Severity", "Priority", "Tags", "Repro Steps", "System Info"]
    with DESTINO.open("w", encoding="utf-8-sig", newline="") as f:
        w = csv.writer(f)
        w.writerow(columnas)
        for d in filas:
            estado, cerrar = ESTADO[d["id"]]
            etiquetas = ["app-movil", ORIGEN[d["id"]], f"qa-{d['ronda'].lower()}"]
            if cerrar:
                etiquetas.append("cerrar-done")
            repro = "".join(
                f"<p>{html.escape(p)}</p>"
                for p in (
                    f"ID de QA (PR-07): {d['id']}",
                    f"Evidencia: {d['evidencia']}",
                    *( [f"Caso que lo verifica: {d['caso']}"] if d["caso"] else [] ),
                    f"Estado al 12/11/2026: {estado}",
                    "Detalle: planeacion/test/Resultados/INFORME_RESULTADOS_PRUEBAS_APP.md",
                )
            )
            info = {
                "S1": "Android 13 (emulador API 33) · APK de QA de develop f253eb0 · 11/11/2026",
                "S2": "Android 13 (emulador API 33) · develop tras PR #16 · 12/11/2026",
                "S3": "Android 13 (emulador API 33) · APK de QA 1.0.9 (develop + PR #31) · 12/11/2026",
            }[d["ronda"]]
            w.writerow([
                "Bug", f"[{d['id']}] {d['titulo']}", SEVERIDAD[d["sev"]], PRIORIDAD[d["sev"]],
                "; ".join(etiquetas), repro, info,
            ])
    cerrar = sum(1 for d in filas if ESTADO[d["id"]][1])
    print(f"{len(filas)} defectos en {DESTINO.relative_to(RAIZ)} ({cerrar} con la etiqueta cerrar-done)")


if __name__ == "__main__":
    main()
