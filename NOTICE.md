# NOTICE

This repository packages and redistributes upstream software published by the
[bottom](https://github.com/ClementTsang/bottom) project. The Apache-2.0
license in [`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It
does **not** cover any upstream-derived asset — the redistributed bytes carry
their own license, recorded below.

The package logo is upstream's own icon
([`assets/icons/bottom-system-monitor.svg`](https://github.com/ClementTsang/bottom/blob/main/assets/icons/bottom-system-monitor.svg)),
redistributed unmodified under the same MIT license as the rest of the project
and used for catalog identification only. No endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `bottom` | `ghcr.io/ocx-contrib/bottom/bottom` | `MIT` |

---

## `bottom`

Upstream: <https://github.com/ClementTsang/bottom>
Published to `ghcr.io/ocx-contrib/bottom/bottom`.

| Component | SPDX | Holder |
|---|---|---|
| bottom (`btm`) | **MIT** | Copyright (c) 2019 Clement Tsang |

Verified at the Phase 1.5 license gate:

```
$ gh api repos/ClementTsang/bottom/license --jq '.license.spdx_id'
MIT
```

MIT is permissive and grants redistribution of the compiled binary
unconditionally, subject only to retention of the copyright and permission
notices. The canonical text is
<https://github.com/ClementTsang/bottom/blob/main/LICENSE>, and it is reproduced
here in full so the notice travels with the redistributed bytes:

```
MIT License

Copyright (c) 2019 Clement Tsang

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR OTHER DEALINGS IN THE SOFTWARE.
```

Upstream's release archives do **not** ship the `LICENSE` file beside the
binary — they contain only `btm` and `completion/` — which is why the text is
carried here instead.

The published binaries statically link third-party Rust crates under permissive
licenses, enumerated in upstream's `Cargo.lock`.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
