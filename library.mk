################################################################################
# \file library.mk
#
# \brief
# ifx-tf-psa-crypto-port: ModusToolbox integration for the TF-PSA-Crypto
# library (works with both the Infineon fork 'ifx-tf-psa-crypto' and the
# upstream 'tf-psa-crypto' checkout).
#
# The TF-PSA-Crypto repository is a CMake-oriented library that is NOT
# suitable for raw MTB auto-discovery: it contains host tools, tests,
# examples and single-compilation-unit aggregates (e.g. mldsa_native.c/.S
# which are textually #include'd by drivers/pqcp/src/wrap_mldsa_native.c).
# Scanning it causes object-file collisions (mldsa_native.o) and pulls
# hundreds of unwanted sources into the build.
#
# This port therefore:
#   1. Excludes the whole library checkout from MTB auto-discovery via
#      CY_IGNORE (the same approach as ifx-tf-m with its root ".cyignore").
#      The library checkout itself is never modified.
#   2. Builds a curated list of sources/includes/defines locally on this
#      core (e.g. for local ML-DSA / ML-KEM). If the TF-M non-secure
#      interface library (ifx-tf-m-ns) is also present, a warning is printed,
#      because there must be exactly ONE PSA implementation (see below).
#
# There must be exactly one PSA Crypto implementation in a project:
#   - NS core WITHOUT ifx-tf-m-ns -> local build (default)
#   - NS core WITH ifx-tf-m-ns    -> warning. The PSA API comes from TF-M, so
#     the application's TF-PSA-Crypto config must switch to client mode:
#     undefine MBEDTLS_PSA_CRYPTO_C and define MBEDTLS_PSA_CRYPTO_CLIENT
#     (via TF_PSA_CRYPTO_USER_CONFIG_FILE). Only the non-PSA modules (pk, md,
#     asn1, pem, ...) are then built locally; otherwise the link fails with
#     duplicate psa_* symbols.
#
# Emergency opt-out: set TFPSA_CRYPTO_PORT_DISABLE=1 in the application
# Makefile to suppress everything (no local build, no warning).
#
################################################################################
# \copyright
# (c) 2026, Infineon Technologies AG, or an affiliate of Infineon
# Technologies AG. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
################################################################################

ifeq ($(WHICHFILE),true)
$(info Processing $(lastword $(MAKEFILE_LIST)))
endif

################################################################################
# Locate the crypto library checkout
################################################################################

# Cross-platform path normalization. Under modus-shell (Cygwin) 'abspath' /
# 'realpath' would yield a POSIX '/cygdrive/c/...' path that the native
# Windows toolchain (arm-none-eabi-gcc) does not understand in -I flags, so
# convert it to a mixed Windows path (C:/...). On Linux/macOS the path is
# already correct, so it is passed through unchanged.
# (Same pattern as ifx-tf-m-port/make/common.mk.)
TFPSA_OS=$(shell uname)
ifneq (,$(findstring CYGWIN,$(TFPSA_OS)))
TFPSA_PATH_MIXED=$(shell cygpath -i -m "$1")
else
TFPSA_PATH_MIXED=$1
endif

# Prefer the Infineon fork; fall back to an upstream 'tf-psa-crypto' checkout.
TFPSA_CRYPTO_DIR?=$(firstword $(wildcard $(SEARCH_ifx-tf-psa-crypto) $(SEARCH_tf-psa-crypto)))
ifeq ($(TFPSA_CRYPTO_DIR),)
$(error ifx-tf-psa-crypto-port requires the 'ifx-tf-psa-crypto' (or upstream \
        'tf-psa-crypto') library in the application dependencies)
endif
TFPSA_CRYPTO_DIR:=$(call TFPSA_PATH_MIXED,$(abspath $(TFPSA_CRYPTO_DIR)))

# Resolve the port's own directory to an absolute path usable on the compiler
# command line (see TFPSA_PATH_MIXED note above).
TFPSA_PORT_DIR:=$(call TFPSA_PATH_MIXED,$(abspath $(dir $(lastword $(MAKEFILE_LIST)))))

################################################################################
# Exclude the library from MTB auto-discovery
################################################################################

# Never let mtbsearch scan the library: auto-discovery cannot handle its
# CMake layout (object-file name collisions, host-only programs with main(),
# test framework, etc.). Explicit SOURCES/INCLUDES added below are not
# affected by CY_IGNORE - it only applies to the search phase.
CY_IGNORE+=$(TFPSA_CRYPTO_DIR)

# cy-mbedtls-acceleration: exclude from auto-discovery the legacy classic
# MbedTLS "*_ALT" sources (removed in TF-PSA-Crypto 1.0; every MBEDTLS_*_ALT
# is a hard #error), keeping only the PSA transparent drivers
# (mbedtls_PSA/{MXCrypto,MXCryptolite,MXCryptosuite}), which are wired up in
# make/tfpsa_crypto.mk. Done here (app-scope CY_IGNORE) so the acceleration
# checkout itself is never modified.
#
# The *_alt_* files are listed individually (not the whole dirs) because the
# legacy dirs also hold the SHARED helper headers crypto_common.h and
# cryptolite_common.h, which the PSA transparent drivers still need
# (psa_crypto_driver_wrappers.h includes them under IFX_PSA_MXCRYPTO_PRESENT /
# IFX_PSA_CRYPTOLITE_PRESENT). Excluding the whole dir breaks that (TFM-4813).
ifneq ($(SEARCH_cy-mbedtls-acceleration),)
TFPSA_ACCEL_IGNORE_DIR:=$(call TFPSA_PATH_MIXED,$(abspath $(SEARCH_cy-mbedtls-acceleration)))
# Legacy ALT sources/headers in mbedtls_MXCRYPTO (keep crypto_common.*).
CY_IGNORE+=$(foreach f,aes_alt_mxcrypto aes_gcm_alt_mxcrypto ecdh_alt_mxcrypto ecdsa_alt_mxcrypto ecp_alt_mxcrypto ecp_curves_alt_mxcrypto ed25519_alt_mxcrypto eddsa_alt_mxcrypto sha1_alt_mxcrypto sha256_alt_mxcrypto sha512_alt_mxcrypto trng_alt_mxcrypto,$(TFPSA_ACCEL_IGNORE_DIR)/mbedtls_MXCRYPTO/$(f).c $(TFPSA_ACCEL_IGNORE_DIR)/mbedtls_MXCRYPTO/$(f).h)
# Legacy ALT sources/headers in mbedtls_MXCRYPTOLITE (keep cryptolite_common.*).
CY_IGNORE+=$(foreach f,aes_alt_mxcryptolite ecdsa_alt_mxcryptolite ed25519_alt_mxcryptolite eddsa_alt_mxcryptolite eddsa_alt_sha512 sha256_alt_mxcryptolite trng_alt_mxcryptolite,$(TFPSA_ACCEL_IGNORE_DIR)/mbedtls_MXCRYPTOLITE/$(f).c $(TFPSA_ACCEL_IGNORE_DIR)/mbedtls_MXCRYPTOLITE/$(f).h)
# wolfcrypto PSA driver requires the wolfSSL library, which is not in this stack.
CY_IGNORE+=$(TFPSA_ACCEL_IGNORE_DIR)/mbedtls_PSA/mbedtls_psa_wolfcrypto
endif

################################################################################
# ifx-tf-m-ns present: exactly one PSA implementation allowed
################################################################################

ifneq ($(TFPSA_CRYPTO_PORT_DISABLE),1)

# ifx-tf-m-ns provides the psa_* client stubs (tfm_crypto_api.c); the local PSA
# core must be compiled out by the application's config, or both define psa_*.
ifneq ($(SEARCH_ifx-tf-m-ns),)
$(warning ifx-tf-psa-crypto-port: 'ifx-tf-m-ns' (TF-M NS client) is also \
       present, so the PSA API must come from TF-M. Build TF-PSA-Crypto in \
       client mode: undefine MBEDTLS_PSA_CRYPTO_C and define \
       MBEDTLS_PSA_CRYPTO_CLIENT (e.g. via TF_PSA_CRYPTO_USER_CONFIG_FILE), \
       otherwise the link fails with duplicate psa_* symbols. \
       Set TFPSA_CRYPTO_PORT_DISABLE=1 to not build TF-PSA-Crypto at all.)
endif

################################################################################
# Local build of the library
################################################################################

$(info ifx-tf-psa-crypto-port: building TF-PSA-Crypto locally \
       (set TFPSA_CRYPTO_PORT_DISABLE=1 to suppress))
include $(TFPSA_PORT_DIR)/make/tfpsa_crypto.mk

else
$(info ifx-tf-psa-crypto-port: TFPSA_CRYPTO_PORT_DISABLE=1 - \
       not compiling TF-PSA-Crypto locally (auto-discovery suppressed))
endif
