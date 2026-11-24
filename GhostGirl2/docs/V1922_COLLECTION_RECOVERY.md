# v1.92.2 — Collection recovery

M0 stability slice. No rarity, visual art, combat, affix, or loot-generation changes.

## Changed
- `scripts/inventory.gd`: extracted save-data assembly and restoration, retains unavailable/overflow backpack records, retries them on reload, validates top-level containers, guards against overwriting unreadable/invalid saves, backs up old v2 grid data before migration.
- `scripts/inventory_panel.gd`: recovery warning and page-label tooltip.
- `tests/v1922_collection_recovery_smoke.gd`: isolated synthetic fixture tests.
- GitHub Actions and root ROADMAP.md: regression and evidence.

## Recovery
Free backpack space or restore the missing resource and restart the game. Records that still cannot fit remain in the save. Recovered items do not automatically equip. Unknown fields are preserved in unresolved records; ordinary item serialization resumes after recovery. Invalid container structure blocks saving; preserve the file and repair/restore a backup before resuming. This is not a general malformed-field repair tool.

## Upgrade / downgrade
Back up the entire Godot user data directory before upgrading. Old v2 grid migration also makes an adjacent `.pre-grid6.bak` (numbered if needed). v1 saves remain intact. The new optional `unresolved_backpack` key is not read by old versions: **do not downgrade with unresolved records**; older builds could discard them on save. Restore your pre-upgrade backup if reverting. No actual player data was used in tests.

## Verification
Previous v1.92.1 CI passed. New headless test is registered; CI result and interactive Godot playtest are pending. Test fixtures cover capacity, missing resource, index mapping, same cosmetic UID / separate instances, saved protection and stats, malformed containers, migration backups. Ordinary save-failure transaction handling and real old-save playtesting remain P0 blockers.
