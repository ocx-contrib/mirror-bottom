# bottom/tests/smoke.star — stable across upstream bottom releases.
#
# btm is a TUI process monitor: its normal mode of operation is an alternate
# screen it never leaves, so there is no "run it and read the output" path.
# Everything below therefore exercises the parts of the binary that run BEFORE
# terminal init and exit deterministically — argument validation, default-config
# generation, and the TOML parser — and asserts computed results, never prose.
# The `Warning: bottom is not being output to a terminal` path is deliberately
# never reached: every run here exits before it.
#
# Binary is `btm`; the PACKAGE is `bottom`. See ocx.mirror testing-practices.md.

BTM = "btm.exe" if ocx.target_platform.os == ocx.os.Windows else "btm"

# Tier 1 + 2: liveness on the composed PATH + version SHAPE (not the vendor
# banner, not the exact version — the digits are the contract).
r_version = ocx.run(BTM, "--version")
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3a: POSITIVE control — a real, observable side effect.
#
# `--config_location <PATH>` writes a full default config when the file does
# not exist, and that write happens during startup, BEFORE any terminal work.
# Pairing it with a deliberately invalid `--rate` makes the process bail
# immediately afterwards instead of entering the TUI and hanging the leg, so
# one run yields both halves: the file bottom generated, and bottom's own
# semantic rejection of the flag.
#
# ⚠️ `--rate 10ms` is rejected by BOTTOM (exit 1, its own "Argument error"),
# not by clap (which exits 2 for unknown flags/values). The `250ms` token is
# the documented minimum and is asserted rather than the sentence around it —
# wording changes across releases, the bound does not.
r_cfg = ocx.run(BTM, "--config_location", "generated.toml", "--rate", "10ms")
expect.eq(r_cfg.exit_code, 1)
expect.matches(r_cfg.stderr, r"250ms")
# Empty stdout is the assertion that the TUI was never entered — the alternate
# screen announces itself with a burst of CSI sequences on stdout.
expect.eq(r_cfg.stdout, "")

# The generated config is ~15 KB of commented TOML compiled into the binary, so
# it is real payload rather than a header: a truncated or hollow artifact
# cannot produce it. Section headers are the config CONTRACT users write
# against — stable tokens, not prose.
expect.true(ocx.exists("generated.toml"))
cfg = ocx.read_file("generated.toml")
expect.true(len(cfg) > 8000)
expect.contains(cfg, "[flags]")
expect.contains(cfg, "[styles]")
expect.contains(cfg, "[processes]")
expect.contains(cfg, "[cpu]")
expect.contains(cfg, "[disk]")
expect.contains(cfg, "[[row]]")

# Tier 3b: NEGATIVE control — the TOML parser, on hermetic malformed input.
#
# Without this, Tier 3a alone would pass against a binary that merely dumped
# its template and accepted anything afterwards. The assertion has teeth
# because the line/column pointer is COMPUTED from the input written here, not
# a fixed string: `column 6` is where `not` starts on line 1.
ocx.write_file("broken.toml", "this is not = valid [toml\n")
r_bad = ocx.run(BTM, "--config_location", "broken.toml")
expect.eq(r_bad.exit_code, 1)
expect.matches(r_bad.stderr, r"TOML parse error at line \d+, column \d+")
expect.eq(r_bad.stdout, "")

# No Tier 4: metadata.json declares PATH only (proven by Tier 1 liveness).
