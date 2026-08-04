# mirror-bottom

OCX mirror for [bottom](https://github.com/ClementTsang/bottom), a cross-platform
graphical process/system monitor for the terminal. One repository, one spec
directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [bottom](https://github.com/ClementTsang/bottom) | [`bottom/mirror.yml`](bottom/mirror.yml) | `ghcr.io/ocx-contrib/bottom/bottom` | [`ocx.sh/bottom/bottom`](https://index.ocx.sh/bottom/bottom) | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

`ClementTsang` is a personal handle rather than a vendor, so the tool names
itself: the namespace is `bottom`, not the maintainer. The package segment is
the name the project publishes under — `bottom` — even though the binary you
type is `btm`.

## Layout

```
mirror-base.yml         repo-wide policy the spec inherits via `extends:`
bottom/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. The logo is **not** — it sits
beside the spec, because a repo-root `logo.*` sits in no workflow's `paths:`
filter, so replacing it would publish nothing until some unrelated edit
happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. `bottom/mirror.yml` does not
restate `platforms:` at all; the measured matrix lives in `mirror-base.yml`.

## Platforms

Six platform entries are planned: both Linux arches, both macOS arches, both
Windows arches, rolled out in three passes (Linux → darwin → windows) per the
skill's cost discipline. Every one of the six anchored asset patterns was
checked against the full asset list of **every** in-range release (0.14.5,
0.14.6, 0.14.7) and matches exactly one asset each, 18/18 — a pattern matching
zero is *silently skipped* by the pipeline, not an error, and would ship a
missing platform under a green run.

**Both Linux keys are bare, because both artifacts are fully static.**
`os.features` states what an artifact requires *of the host*, never how it was
built, and a musl target *triple* is not a musl *requirement*:

| Key | Asset | Measured (0.14.5 and 0.14.7) |
|---|---|---|
| `linux/amd64` | `bottom_x86_64-unknown-linux-musl.tar.gz` | static-pie, `INTERP` count **0**, zero `DT_NEEDED` → **bare** |
| `linux/arm64` | `bottom_aarch64-unknown-linux-musl.tar.gz` | statically linked, `INTERP` count **0**, zero `DT_NEEDED` → **bare** |

The `alpine:3.20` container leg on each key is what turns the universality
claim into evidence — drop it and the claim is merely asserted.

Upstream also ships `-gnu` builds for both arches and they are genuinely
dynamic (`interpreter /lib64/ld-linux-x86-64.so.2`, `NEEDED libc.so.6
libgcc_s.so.1 libm.so.6`, max symver `GLIBC_2.34`). They are **deliberately not
carried**: a second `+libc.glibc` key earns its place only where the gnu build
reaches capability the static one lacks, and `btm` reads `/proc` and `sysfs`
and resolves no hostnames, so musl's NSS-blind resolver is not a
differentiator. Not carrying them also sidesteps an ambiguity trap — upstream
ships `bottom_x86_64-unknown-linux-gnu-2-17.tar.gz` (an older glibc-2.17
baseline) beside `bottom_x86_64-unknown-linux-gnu.tar.gz`, and an unanchored
gnu pattern matches **both**.

### Asset names carry no version

`bottom_x86_64-unknown-linux-musl.tar.gz` is byte-identical *in name* on every
tag — nothing in a filename says which release it came from. Resolution is
tag-scoped by construction (the pipeline reads one release's assets and uses
their own `…/releases/download/<tag>/…` URLs, never a `latest` alias), and
tag↔content agreement was verified by **running** the artifacts: 0.14.7's
binary self-reports `bottom 0.14.7`, 0.14.5's `bottom 0.14.5`.

Also published upstream and deliberately not carried: `i686-*` and `armv7-*`
(no OCX 386 or arm key), `loongarch64` / `powerpc64le` / `riscv64gc`, the
FreeBSD, NetBSD and Android builds, `x86_64-pc-windows-gnu` (msvc is the one
carried), and every packaging artifact — `.deb`, `.rpm`, `*_installer.msi`,
`choco.zip`, `bottom.desktop`, `completion.tar.gz`, `manpage.tar.gz`. The
anchored `^…$` regexes are what keep them out.

## The binaries claim

Every release archive — `.tar.gz` and `.zip` alike — is **flat**: `btm`
(`btm.exe` on Windows, mode 0755 in the tarballs) sits at the archive **root**
beside a `completion/` directory, with no wrapper directory at all. So
`strip_components: 0` is what keeps the executable at the content root;
stripping 1 would delete `btm` outright and hoist `completion/*` in its place.
One `asset_type` therefore serves every platform.

The bundle's only PATH entry is a bare `${installPath}` — the executable *is*
the content root. `bin_scan` only looks *below* an `${installPath}/<dir>`
entry, so `auto`/`verify` is rejected at spec load with exit 65 (*the
verification would inspect no file and pass green whatever the archive
contains*). `bottom/mirror.yml` therefore sets `bin_scan: "off"` and
`bottom/metadata.json` hand-lists `binaries: ["btm"]` — the blessed shape for
this layout, and `btm` is the archive's only mode-0755 entry.

## The smoke test

`btm` is a TUI: its normal mode of operation is an alternate screen it never
leaves, so there is no "run it and read the output" path, and a run that
reaches terminal init would hang the leg. `bottom/tests/smoke.star` therefore
exercises only what runs *before* terminal init and exits deterministically:

- version **shape** (`\d+\.\d+\.\d+`), never the banner;
- a positive control — `--config_location <path>` makes the binary write its
  ~15 KB embedded default config, which is asserted for the TOML section
  headers users actually write against (`[flags]`, `[styles]`, `[processes]`,
  `[cpu]`, `[disk]`, `[[row]]`). Paired with an invalid `--rate 10ms` so the
  process bails immediately after writing rather than entering the TUI, and the
  documented `250ms` bound is asserted instead of the sentence around it;
- a negative control — a malformed TOML config written to scratch must produce
  a `TOML parse error at line N, column M`, whose pointer is *computed* from
  that input. Without it the positive control would pass against a binary that
  dumped its template and accepted anything afterwards.

Empty stdout is asserted on both failing runs: the alternate screen announces
itself with a burst of CSI sequences, so an empty stdout is the evidence the
TUI was never entered.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `bottom/mirror.yml` | hand | yes — see below |
| `bottom/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `bottom/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec bottom/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; the
redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
