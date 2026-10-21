# ifx-tf-psa-crypto-port

ModusToolbox integration (porting layer) for the **TF-PSA-Crypto** library.
Works unchanged with both checkouts:

- the Infineon fork `ifx-tf-psa-crypto`, and
- the upstream `tf-psa-crypto` (Mbed-TLS),

because it never modifies the library checkout: all exclusions are applied
through the application-scope `CY_IGNORE` variable and all build inputs are
given as explicit `SOURCES`/`INCLUDES`/`DEFINES` relative to the discovered
`SEARCH_` path.

## Why this port exists

The TF-PSA-Crypto repository is a CMake-oriented library. Its tree contains
host tools (`programs/`, ~10 `main()` functions), tests, a test framework,
and *single-compilation-unit* aggregates such as
`drivers/pqcp/mldsa-native/mldsa/mldsa_native.c` and `mldsa_native.S`, which
are **textually `#include`d** by `drivers/pqcp/src/wrap_mldsa_native.c`
(once per ML-DSA parameter set).

Letting MTB auto-discovery scan this tree fails the build:

```
mtbninja: Multiple source files map to the object file '.../mldsa_native.o'
  Source file '.../mldsa_native.S'
  Source file '.../mldsa_native.c'
```

This port suppresses auto-discovery for the library and builds exactly the
parts that make sense on a ModusToolbox target.

## Usage

Add both libraries to the application (Library Manager or `deps/*.mtb`):

- `ifx-tf-psa-crypto` (or upstream `tf-psa-crypto`)
- `ifx-tf-psa-crypto-port` (this asset)

There must be **exactly one PSA Crypto interface** in a project. The port
enforces this:

### Default — local crypto (e.g. ML-DSA / ML-KEM on this core)

No configuration needed. When the application does **not** use the TF-M
non-secure interface (`ifx-tf-m-ns`), the port compiles a curated subset of
the library locally:

| Part | Sources |
|---|---|
| PSA core | `core/*.c` |
| Driver dispatch | `dispatch/` (headers) |
| Extra algorithms | `extras/*.c` |
| Platform glue | `platform/*.c` |
| Utilities | `utilities/*.c` |
| Builtin drivers | `drivers/builtin/src/*.c` |
| Everest (X25519/Ed25519) | `drivers/everest/library/*.c` |
| P-256 driver | `drivers/p256-m/*.c` |
| PQCP (ML-DSA) | `drivers/pqcp/src/*.c` |

### Conflict — `ifx-tf-m-ns` present

If the application also pulls `ifx-tf-m-ns` (the TF-M non-secure PSA client
interface), the build **stops with an error**: both would define
`psa_crypto_*` and provide `psa/crypto.h`. This is intentional — pick one:

- keep `ifx-tf-m-ns`, remove `ifx-tf-psa-crypto-port` (crypto runs on the
  secure side, calls routed via TZ / MTB mailbox), or
- keep this port, remove `ifx-tf-m-ns` (crypto runs locally on this core).

### Emergency opt-out

To suppress the port completely (no local build, no conflict error):

```
TFPSA_CRYPTO_PORT_DISABLE=1
```

(The library stays excluded from auto-discovery in every mode.)

### Custom configuration

The port ships `config/ifx_tfpsa_mtb_config.h`: the library default config
plus the PQCP driver enabled with ML-DSA-87. To use your own configuration,
add to the application Makefile:

```
INCLUDES+=<dir with your header>
DEFINES+=TF_PSA_CRYPTO_CONFIG_FILE=\"my_tfpsa_config.h\"
```

### Hardware acceleration (cy-mbedtls-acceleration)

When the application also pulls `cy-mbedtls-acceleration`, the port wires up
its **PSA transparent drivers** (`mbedtls_PSA/`) against this library and
excludes the parts that cannot build here:

- `DEFINES+=IFX_TF_PSA_CRYPTO` and `IFX_TF_PSA` so the acceleration PSA
  headers pick the TF-PSA-Crypto header layout.
- `INCLUDES+=` for each `mbedtls_PSA/mbedtls_psa_*` directory.
- Excluded via `CY_IGNORE` (the acceleration checkout is never modified):
  - `mbedtls_MXCRYPTO/`, `mbedtls_MXCRYPTOLITE/` — legacy classic-MbedTLS
    `*_ALT` interface, removed in TF-PSA-Crypto 1.0 (every `MBEDTLS_*_ALT`
    macro is a hard `#error`);
  - `mbedtls_PSA/mbedtls_psa_wolfcrypto/` — wolfSSL-backed PSA driver;
    requires the wolfSSL library, which is not part of this stack.

A few acceleration v3.2.0 headers reference the removed classic
`mbedtls/build_info.h` / `mbedtls/ecp.h` without a config guard (upstream
defect, still present in v3.100.0). The port supplies thin forwarding shims
under `compat/include/mbedtls/` so those files build unmodified.

## Notes / roadmap

- **ML-KEM** is not present in TF-PSA-Crypto v1.2.x. When the library gains
  it (upstream roadmap), enable it in the config; if it arrives as a new
  driver directory, add it to `make/tfpsa_crypto.mk`.
- **ML-DSA parameter sets**: v1.2.x provides ML-DSA-87 only
  (`TF_PSA_CRYPTO_PQCP_MLDSA_87_ENABLED`). 44/65 need a newer library.
- The mldsa-native `examples/`, `test/`, `proofs/`, `dev/` trees and the
  monolithic `mldsa_native.c`/`.S` are never compiled by MTB; the C sources
  are included textually by `wrap_mldsa_native.c`, the `.S` files are
  AArch64/x86-64 only and unused on Cortex-M targets.
