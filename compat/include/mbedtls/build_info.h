/* Compat shim for cy-mbedtls-acceleration sources that still include the
 * legacy classic-MbedTLS path "mbedtls/build_info.h" (removed in
 * TF-PSA-Crypto 1.0). Provided by ifx-tf-psa-port so the acceleration
 * checkout is never patched. Maps to the TF-PSA-Crypto build info.
 */
#ifndef IFX_TFPSA_PORT_MBEDTLS_BUILD_INFO_SHIM_H
#define IFX_TFPSA_PORT_MBEDTLS_BUILD_INFO_SHIM_H

#include "tf-psa-crypto/build_info.h"

#endif /* IFX_TFPSA_PORT_MBEDTLS_BUILD_INFO_SHIM_H */
