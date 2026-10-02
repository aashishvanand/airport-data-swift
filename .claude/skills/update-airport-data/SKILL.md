---
name: update-airport-data
description: Sync data/airports.json from airport-data-js into airport-data-swift, regenerate derived data files, check dependencies, bump the patch version and release. Use when the user says the JS library has new airport data, asks to update/sync airports, or asks for a data release.
---

# Update airport data (airport-data-swift)

`airport-data-js` is the source of truth for the dataset. This repo ships a copy of it.
Work from the repo root (`/Users/aashishvanand/Code/airport-data-swift`).

## 1. Get the new data

```bash
git checkout main && git pull --ff-only
git -C ../airport-data-js fetch origin
git -C ../airport-data-js show origin/main:data/airports.json > data/airports.json
git diff --stat data/airports.json   # nothing changed? stop, there is nothing to release
```

## 2. Scan field types before touching code

Upstream sometimes changes value types (for example, `""` became `null` for missing
`elevation_ft` / `runway_length` in JS 4.0.0). Compare old against new for every field:

```bash
git show HEAD:data/airports.json > /tmp/old_airports.json
python3 - <<'EOF'
import json
from collections import Counter
o = json.load(open('/tmp/old_airports.json')); n = json.load(open('data/airports.json'))
print('count', len(o), '->', len(n))
for f in n[0]:
    co = Counter(type(a.get(f)).__name__ for a in o); cn = Counter(type(a.get(f)).__name__ for a in n)
    if co.keys() != cn.keys():
        print(f, dict(co), '->', dict(cn))
old = {(a['iata'], a['icao']) for a in o}
print('added', [(a['iata'], a['icao'], a['airport']) for a in n if (a['iata'], a['icao']) not in old])
EOF
```

If a field gains a new type (`NoneType`, `str` in a numeric field, and so on), check that the decoder below handles it
and add a test for it. Also read the top of `../airport-data-js/CHANGELOG.md` for data fixes and breaking type changes.

Decoder: `AirportDataStore` loads the bundled resource with `JSONSerialization` and reads numbers with `as? NSNumber`,
so `null` becomes `nil`.

## 3. Regenerate derived files

The bundled resource is a compact, normalized copy of the data, with `utc`/`latitude`/`longitude` as floats, `scheduled_service` as a bool and missing ints as null.
Regenerate it with:
```bash
python3 scripts/generate_resource.py   # writes Sources/AirportData/Resources/airports.json
```
If you change the script, make sure it still reproduces the previous resource byte-for-byte from the previous `data/airports.json`.

## 4. Check for dependency updates

There are no package dependencies. Check `.github/workflows/*.yml` action versions and open dependabot PRs (`gh pr list`).

## 5. Bump the version (patch for data-only updates)

There's no version file. The version comes from the commit message on `release` (see step 8).
Check the existing tags with `git ls-remote --tags origin`. They have no `v` prefix, for example `1.0.1`.

## 6. Verify locally (same checks as CI)

```bash
swift build
swift test
```

If a test fails, confirm the failure comes from a real data change (new airport count, corrected
coordinates, and so on) before you update the expected value.

## 7. Commit and push main, then wait for CI

Stage explicit paths only. Never use `git add .`, because there are untracked local files.

```bash
git add data/airports.json Sources/AirportData/Resources/airports.json
git commit -m "feat: sync airport data with airport-data-js and bump version to X.Y.Z"
git push origin main
gh run list --branch main --limit 1        # then: gh run watch <id> --exit-status
```

## 8. Release (only after CI on main is green; publishing is irreversible)

The workflow reads `X.Y.Z` from the latest commit message on `release`, then tags it and creates a GitHub Release:
```bash
git checkout release && git pull --ff-only && git merge --ff-only main
git commit --allow-empty -m "Release X.Y.Z"
git push origin release
git checkout main
```
If `git pull` complains that there's no tracking information, run `git branch --set-upstream-to=origin/release release` first.
