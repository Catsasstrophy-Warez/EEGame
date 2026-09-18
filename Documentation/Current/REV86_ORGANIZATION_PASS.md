# Rev86 Organization Pass

## What changed
- Replaced the duplicated/stale root README with a concise Rev86 front door.
- Moved superseded Rev73/74/84 handoff material, the Rev84 manifest and Rev85 transition report into `Documentation/History/`.
- Moved current architecture, truth, feature, test, roadmap, safety and navigation documents into `Documentation/Current/`.
- Promoted the Rev86 causal-depth report to `Documentation/Current/`.
- Updated current architecture, simulation truth, roadmap, feature matrix, test matrix, UI navigation, release status and reachability documentation for Rev86.
- Added a capability-oriented `SOURCE_DOMAIN_MAP_REV86.md` to guide Rev87 migration without destructive bulk renames.
- Added `Scripts/validate_all.sh` as the unified validation entry point.
- Added `Scripts/generate_manifest.py` and a fresh Rev86 cross-computer manifest.
- Added the 20-screen Rev86 mockup to `Documentation/VisualReferences/`, explicitly labeled as a mockup rather than a runtime capture.
- Removed transient build artifacts from the release package.

## Preserved intentionally
- Revision-numbered Swift files and public/internal symbols were not bulk renamed.
- Historical documentation was archived, not discarded.
- The existing Xcode project and `project.yml` were preserved.
- No new physical-truth path was introduced.

## Remaining technical debt
The largest organizational debt remains the revision-stratified `ScenarioEngine` and `GameUI` sources. Rev87 should migrate active behavior incrementally behind capability-oriented domains rather than creating more top-level revision files.
