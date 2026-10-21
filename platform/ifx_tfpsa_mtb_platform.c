/**
 * \file ifx_tfpsa_mtb_platform.c
 *
 * \brief Platform hooks for the local TF-PSA-Crypto build on ModusToolbox
 *        targets (provided by the ifx-tf-psa-crypto-port library).
 *
 * The default TF-PSA-Crypto configuration assumes a hosted platform
 * (Unix/Windows): mbedtls_ms_time() and the built-in entropy sources do not
 * exist on a bare Cortex-M target. The port configuration
 * (config/ifx_tfpsa_mtb_config.h) therefore:
 *   - disables MBEDTLS_HAVE_TIME (no wall-clock on target),
 *   - replaces MBEDTLS_PSA_BUILTIN_GET_ENTROPY with
 *     MBEDTLS_PSA_DRIVER_GET_ENTROPY, which routes entropy collection to
 *     the platform hook implemented below.
 */
/*
 * (c) 2026, Infineon Technologies AG, or an affiliate of Infineon
 * Technologies AG. All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "tf-psa-crypto/build_info.h"
#include "mbedtls/platform.h"
#include "mbedtls/private/entropy.h"

#if defined(MBEDTLS_PSA_DRIVER_GET_ENTROPY)

/**
 * Weak, fail-closed default implementation of the platform entropy hook.
 *
 * TODO: PQC (ML-DSA/ML-KEM) key generation REQUIRES a true entropy source.
 * This default stub deliberately returns an error (fail-closed) instead of
 * emitting predictable data: silently succeeding with weak "entropy" would
 * produce insecure keys. The proper fix is to provide a hardware-backed
 * implementation for the target - on PSE84 this is the Crypto block TRNG
 * (PDL Cy_Crypto_Core_Trng, see mtb-dsl-pse8xxgp pdl/drivers/source/
 * cy_crypto_core_trng.c, or mtb_hal_trng). The implementation belongs either
 * in the application (recommended, as it owns Crypto HW initialization) or in
 * a board/platform layer of this port. Override this weak symbol there.
 *
 * Note: a weak stub returning an error means psa_crypto_init() will fail with
 * an entropy error until a real implementation is linked in. This is
 * intentional: the build/link succeeds, but runtime key generation cannot
 * silently proceed without true entropy.
 */
__attribute__((weak))
int mbedtls_platform_get_entropy(psa_driver_get_entropy_flags_t flags,
                                 size_t *estimate_bits,
                                 unsigned char *output, size_t output_size)
{
    (void)flags;
    (void)estimate_bits;
    (void)output;
    (void)output_size;

    /* Fail-closed: no entropy source is available by default. */
    return MBEDTLS_ERR_ENTROPY_SOURCE_FAILED;
}

#endif /* MBEDTLS_PSA_DRIVER_GET_ENTROPY */
