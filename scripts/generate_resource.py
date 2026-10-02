#!/usr/bin/env python3
"""Generate Sources/AirportData/Resources/airports.json from data/airports.json.

The bundled resource is a compact, normalized copy of the source dataset:
- `utc`, `latitude` and `longitude` are always floats (missing values become 0.0)
- `scheduled_service` is a bool ("TRUE" -> true)
- `elevation_ft` / `runway_length` are ints, or null when missing

Run from the package root:
    python3 scripts/generate_resource.py
"""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "data" / "airports.json"
DEST = ROOT / "Sources" / "AirportData" / "Resources" / "airports.json"


def to_float(value):
    if value is None or value == "":
        return 0.0
    return float(value)


def to_int_or_none(value):
    if value is None or value == "":
        return None
    if isinstance(value, str):
        value = value.replace(",", "")
    return int(float(value))


def normalize(airport):
    out = dict(airport)
    out["utc"] = to_float(airport.get("utc"))
    out["latitude"] = to_float(airport.get("latitude"))
    out["longitude"] = to_float(airport.get("longitude"))
    out["scheduled_service"] = str(airport.get("scheduled_service", "")).upper() == "TRUE"
    out["elevation_ft"] = to_int_or_none(airport.get("elevation_ft"))
    out["runway_length"] = to_int_or_none(airport.get("runway_length"))
    return out


def main():
    airports = json.loads(SRC.read_text(encoding="utf-8"))
    result = [normalize(a) for a in airports]
    DEST.write_text(json.dumps(result, separators=(",", ":")), encoding="ascii")
    print(f"Wrote {len(result)} airports to {DEST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
