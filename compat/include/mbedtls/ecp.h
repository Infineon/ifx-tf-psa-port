/* Compat shim for cy-mbedtls-acceleration sources that still include the
 * legacy classic-MbedTLS path "mbedtls/ecp.h" (moved to mbedtls/private/ in
 * TF-PSA-Crypto). Provided by ifx-tf-psa-port so the acceleration checkout is
 * never patched. Maps to the TF-PSA-Crypto private header.
 */
#ifndef IFX_TFPSA_PORT_MBEDTLS_ECP_SHIM_H
#define IFX_TFPSA_PORT_MBEDTLS_ECP_SHIM_H

#include "mbedtls/private/ecp.h"

#endif /* IFX_TFPSA_PORT_MBEDTLS_ECP_SHIM_H */
