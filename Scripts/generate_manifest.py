from __future__ import annotations
from pathlib import Path
import hashlib, json, datetime

root = Path(__file__).resolve().parents[1]
out = root / "Documentation" / "Manifests" / "CROSS_COMPUTER_MANIFEST_REV86.json"
exclude_parts = {".build", ".git", "xcuserdata", "DerivedData"}
rows = []
for p in sorted(root.rglob("*")):
    if not p.is_file():
        continue
    rel = p.relative_to(root)
    if any(part in exclude_parts for part in rel.parts):
        continue
    if p == out:
        continue
    data = p.read_bytes()
    rows.append({
        "path": rel.as_posix(),
        "bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
    })
payload = {
    "revision": "Rev86",
    "purpose": "Cross-computer integrity manifest for organized causal-depth Xcode handoff",
    "generated_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "file_count": len(rows),
    "total_bytes": sum(r["bytes"] for r in rows),
    "files": rows,
}
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(payload, indent=2) + "\n")
print(f"Wrote {out.relative_to(root)}: {payload['file_count']} files, {payload['total_bytes']} bytes")
