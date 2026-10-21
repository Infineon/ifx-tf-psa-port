/**
 * \file ifx_tfpsa_mtb_config.h
 *
 * \brief Default TF-PSA-Crypto configuration for ModusToolbox local builds.
 *
 * This header is used when the application builds TF-PSA-Crypto locally via
 * the ifx-tf-psa-crypto-port library (the default mode) and does not
 * provide its own configuration through
 * DEFINES+=TF_PSA_CRYPTO_CONFIG_FILE=\"...\".
 *
 * It starts from the library's default configuration (psa/crypto_config.h)
 * and additionally enables the PQCP driver so that ML-DSA works out of the
 * box. For size-constrained applications, copy this file into the
 * application, trim the PSA_WANT_* set, and point
 * TF_PSA_CRYPTO_CONFIG_FILE at the copy.
 */
/*
 * (c) 2026, Infineon Technologies AG, or an affiliate of Infineon
 * Technologies AG. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

#ifndef IFX_TFPSA_MTB_CONFIG_H
#define IFX_TFPSA_MTB_CONFIG_H

/* Base: the library's own default configuration.
 * (All adjust/dependency headers are applied later via build_info.h.) */
#include "psa/crypto_config.h"

/* ---- ModusToolbox bare-metal adjustments ------------------------------ */

/* The library default enables MBEDTLS_HAVE_TIME, which requires a hosted
 * clock (clock_gettime/GetSystemTimeAsFileTime) for mbedtls_ms_time().
 * Neither exists on a bare Cortex-M target, so disable it. (PKCS#7/X.509
 * features that need wall-clock time are not part of the local PQC use
 * case; re-enable with a platform time provider if ever needed.) */
#undef MBEDTLS_HAVE_TIME

/* The built-in entropy sources (MBEDTLS_PSA_BUILTIN_GET_ENTROPY) only work
 * on Unix and Windows. Switch to the driver/platform hook:
 * mbedtls_platform_get_entropy() is provided (weak, fail-closed stub) by
 * the port's platform/ifx_tfpsa_mtb_platform.c - override it with a
 * hardware TRNG implementation (PSE84: Cy_Crypto_Core_Trng / mtb_hal_trng)
 * in the application before using PQC key generation. See the TODO in that
 * file. */
#undef MBEDTLS_PSA_BUILTIN_GET_ENTROPY
#define MBEDTLS_PSA_DRIVER_GET_ENTROPY

/* Enable the PQCP driver: ML-DSA via the bundled mldsa-native.
 * The driver provides the ML-DSA implementation behind the PSA API. */
#define TF_PSA_CRYPTO_PQCP_MLDSA_ENABLED

/* Parameter sets available in this release of the library.
 * v1.2.x provides ML-DSA-87 only; newer versions add 44/65 via
 * TF_PSA_CRYPTO_PQCP_MLDSA_44_ENABLED / _65_ENABLED. */
#define TF_PSA_CRYPTO_PQCP_MLDSA_87_ENABLED

/* Use the PSA SHAKE implementation (builtin SHA-3 driver) instead of the
 * FIPS-202 code bundled with mldsa-native. Undefine and define
 * TF_PSA_CRYPTO_PQCP_OWN_SHAKE instead if the builtin SHA-3 is disabled. */
/* #define TF_PSA_CRYPTO_PQCP_OWN_SHAKE */

#endif /* IFX_TFPSA_MTB_CONFIG_H */
