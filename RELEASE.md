# ifx-tf-psa-crypto-port release notes

## 1.0.0 (prototype)

- Initial prototype.
- Excludes the TF-PSA-Crypto checkout from MTB auto-discovery via
  `CY_IGNORE` (fixes `mtbninja: Multiple source files map to the object
  file ... mldsa_native.o` and prevents host-only `programs/`, `tests/`,
  `framework/` code from entering embedded builds).
- Adds optional local build (`COMPONENTS+=TFPSA_CRYPTO_LOCAL`) with curated
  sources, include paths and a default configuration enabling ML-DSA-87
  through the PQCP driver.
- Works with both `ifx-tf-psa-crypto` (Infineon fork) and upstream
  `tf-psa-crypto` checkouts without modifying them.
