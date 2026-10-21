################################################################################
# \file tfpsa_crypto.mk
#
# \brief
# Curated local build of TF-PSA-Crypto for ModusToolbox applications.
# Included from ../library.mk in the default (non-conflicting) case.
#
# The source/include sets below mirror the library's own CMake target
# composition (core + dispatch + extras + platform + utilities +
# drivers/{builtin,everest,p256-m,pqcp}). Individual sources are guarded
# internally by the TF-PSA-Crypto configuration, so disabled features
# compile to (nearly) empty objects.
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

# Note: the conflict check against ifx-tf-m-ns is done once, centrally,
# in library.mk before this file is included.

################################################################################
# Sources
################################################################################

TFPSA_SOURCES:=
TFPSA_SOURCES+=$(wildcard $(TFPSA_CRYPTO_DIR)/core/*.c)
TFPSA_SOURCES+=$(wildcard $(TFPSA_CRYPTO_DIR)/dispatch/*.c)
TFPSA_SOURCES+=$(wildcard $(TFPSA_CRYPTO_DIR)/extras/*.c)
TFPSA_SOURCES+=$(wildcard $(TFPSA_CRYPTO_DIR)/platform/*.c)
TFPSA_SOURCES+=$(wildcard $(TFPSA_CRYPTO_DIR)/utilities/*.c)
TFPSA_SOURCES+=$(wildcard $(TFPSA_CRYPTO_DIR)/drivers/builtin/src/*.c)
# Everest: CMake compiles ONLY these two files (not the raw Hacl_*.c). The raw
# Hacl_Curve25519.c requires __int128 (64-bit only) and is never compiled on
# Cortex-M; its body is additionally guarded by MBEDTLS_ECDH_VARIANT_EVEREST_ENABLED
# (off by default). Do NOT wildcard drivers/everest/library/*.c.
TFPSA_SOURCES+=$(TFPSA_CRYPTO_DIR)/drivers/everest/library/x25519.c
TFPSA_SOURCES+=$(TFPSA_CRYPTO_DIR)/drivers/everest/library/Hacl_Curve25519_joined.c
TFPSA_SOURCES+=$(wildcard $(TFPSA_CRYPTO_DIR)/drivers/p256-m/*.c)
TFPSA_SOURCES+=$(wildcard $(TFPSA_CRYPTO_DIR)/drivers/pqcp/src/*.c)

# Port platform glue (entropy hook, etc.).
TFPSA_SOURCES+=$(TFPSA_PORT_DIR)/platform/ifx_tfpsa_mtb_platform.c

SOURCES+=$(TFPSA_SOURCES)

################################################################################
# Include directories
################################################################################

INCLUDES+=$(TFPSA_CRYPTO_DIR)/include
INCLUDES+=$(TFPSA_CRYPTO_DIR)/core
INCLUDES+=$(TFPSA_CRYPTO_DIR)/dispatch
INCLUDES+=$(TFPSA_CRYPTO_DIR)/extras
INCLUDES+=$(TFPSA_CRYPTO_DIR)/platform
INCLUDES+=$(TFPSA_CRYPTO_DIR)/utilities
INCLUDES+=$(TFPSA_CRYPTO_DIR)/drivers/builtin/include
INCLUDES+=$(TFPSA_CRYPTO_DIR)/drivers/builtin/src
INCLUDES+=$(TFPSA_CRYPTO_DIR)/drivers/everest/include
INCLUDES+=$(TFPSA_CRYPTO_DIR)/drivers/everest/library
# NOTE: do NOT add everest's private Hacl include dirs
# (include/tf-psa-crypto/private/everest[/kremlib]) to the include path:
# they are only needed when MBEDTLS_ECDH_VARIANT_EVEREST_ENABLED is on
# (64-bit targets with __int128). Keeping them off the path prevents the
# unsupported Hacl_*.h headers from being picked up on Cortex-M.
INCLUDES+=$(TFPSA_CRYPTO_DIR)/drivers/p256-m
INCLUDES+=$(TFPSA_CRYPTO_DIR)/drivers/pqcp/include
INCLUDES+=$(TFPSA_CRYPTO_DIR)/drivers/pqcp/src
# mldsa_native.c / mldsa_native_config.h live here; they are #include'd
# textually by drivers/pqcp/src/wrap_mldsa_native.c (once per parameter
# set), so this path is required on the include path. The files themselves
# are excluded from compilation via CY_IGNORE in library.mk.
INCLUDES+=$(TFPSA_CRYPTO_DIR)/drivers/pqcp/mldsa-native/mldsa
# Port-provided default configuration header
INCLUDES+=$(TFPSA_PORT_DIR)/config

################################################################################
# Optional hardware acceleration (cy-mbedtls-acceleration) PSA drivers
################################################################################

# When the application also pulls cy-mbedtls-acceleration, build ONLY its PSA
# transparent drivers (mbedtls_PSA/*) against this library. The legacy classic
# Mbed TLS "*_ALT" interface (mbedtls_MXCRYPTO/, mbedtls_MXCRYPTOLITE/) was
# removed in TF-PSA-Crypto 1.0 (every MBEDTLS_*_ALT macro is a hard #error),
# so those sources can never compile here and are excluded from auto-discovery
# via CY_IGNORE in library.mk.
ifneq ($(SEARCH_cy-mbedtls-acceleration),)
TFPSA_ACCEL_DIR:=$(call TFPSA_PATH_MIXED,$(abspath $(SEARCH_cy-mbedtls-acceleration)))

# Tell the acceleration sources to use the TF-PSA-Crypto header layout
# (tf-psa-crypto/build_info.h, mbedtls/private/*) instead of the classic
# mbedtls/ layout. Note: the acceleration code uses two different macros for
# this - most headers check IFX_TF_PSA_CRYPTO, while
# mbedtls_psa_MXCrypto/ifx_mxcrypto_transparent_key_agreement.c checks the
# older IFX_TF_PSA. Define both so all guarded paths pick the new layout.
DEFINES+=IFX_TF_PSA_CRYPTO
DEFINES+=IFX_TF_PSA

# PSA transparent driver headers live directly in each mbedtls_psa_* dir.
INCLUDES+=$(TFPSA_ACCEL_DIR)/mbedtls_PSA/mbedtls_psa_MXCrypto
INCLUDES+=$(TFPSA_ACCEL_DIR)/mbedtls_PSA/mbedtls_psa_MXCryptolite
INCLUDES+=$(TFPSA_ACCEL_DIR)/mbedtls_PSA/mbedtls_psa_MXCryptosuite
INCLUDES+=$(TFPSA_ACCEL_DIR)/mbedtls_PSA/mbedtls_psa_wolfcrypto

# Compat shims for the few acceleration files that include legacy mbedtls/
# headers WITHOUT any guard (e.g. ifx_cryptolite_common.h ->
# mbedtls/build_info.h, ifx_cryptolite_transparent_functions.h -> same).
# The port provides mbedtls/{build_info.h,ecp.h} that forward to the
# TF-PSA-Crypto equivalents, so the acceleration checkout is never patched.
# Only use the shims when the real mbedtls is NOT present: with a genuine
# mbedtls (TLS projects, TFM-4813) our shim would shadow the real
# mbedtls/build_info.h (which carries MBEDTLS_PRIVATE /
# MBEDTLS_ALLOW_PRIVATE_ACCESS) and break it.
ifeq ($(SEARCH_mbedtls),)
INCLUDES+=$(TFPSA_PORT_DIR)/compat/include
endif

$(info ifx-tf-psa-crypto-port: enabling cy-mbedtls-acceleration PSA drivers \
       (legacy *_ALT excluded, IFX_TF_PSA_CRYPTO/IFX_TF_PSA defined))
endif

################################################################################
# Configuration
################################################################################

# Default configuration file, unless the application provides its own via
# DEFINES+=TF_PSA_CRYPTO_CONFIG_FILE=\"my_tfpsa_config.h\"
ifeq ($(filter TF_PSA_CRYPTO_CONFIG_FILE=%,$(DEFINES)),)
DEFINES+=TF_PSA_CRYPTO_CONFIG_FILE=\"ifx_tfpsa_mtb_config.h\"
endif
