# AGENTS.md

## Project purpose
A grab-bag of community-contributed VyOS helper scripts: admin tools, build tools, config processors, format converters. Not part of the shipped image — these are external scripts maintained loosely.

## Tech stack
- Mostly Perl (admin-tools: `dhcpremember.pl`, `ovpnbundle.pl`, `ravpnlist.pl`).
- Other subdirectories carry shell / Python / format-conversion helpers.
- No top-level build system; scripts run standalone.

## Build / test / run
- No build. Each subdirectory's script is self-contained — read each `README` for invocation.
- No automated tests.

## Repository layout
- `admin-tools/` — Perl operator helpers (DHCP lease tracker, OpenVPN bundle generator, RA-VPN client lister).
- `build-tools/` — image/build helpers.
- `config-processors/` — config-tree post-processing.
- `converters/` — format conversion.
- `README` — top-level pitch ("contributions welcome").
- `.github/workflows/` — minimal CI inherited via `vyos/.github` reusables.

## Cross-repo context
This repo is informal/optional and is not part of the canonical 14-repo build set in an internal repository. Stale by category-§3.10 in the cross-repo audit.

## Conventions
- Commit / PR title: `component: T12345: description` (Phorge ID expected).
- Default branch `master` (per audit baseline); pre-dates the `current` rename. Light governance — community-driven contributions.
- No mandatory LICENSE in tree at root; treat each script's header as authoritative.

## Notes for future contributors
- README is one paragraph; per-subdir `README` files are the real docs.
- Stale by audit baseline; if you adopt one of these scripts into the product, fold it into `vyos-1x` rather than evolving it here.
