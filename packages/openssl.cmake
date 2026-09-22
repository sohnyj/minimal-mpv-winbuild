ExternalProject_Add(openssl
    GIT_REPOSITORY https://github.com/openssl/openssl.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/demos !/test"
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${EXEC} CONF=1 <SOURCE_DIR>/Configure
        --cross-compile-prefix=${TARGET_ARCH}-
        --prefix=${MINGW_INSTALL_PREFIX}
        --libdir=lib
        --release
        mingw64
        enable-ec_nistp_64_gcc_128
        enable-threads
        no-autoload-config
        no-apps
        no-aria
        no-ascon128
        no-async
        no-bf
        no-blake2
        no-camellia
        no-cast
        no-cmac
        no-cmp
        no-cms
        no-comp
        no-ct
        no-dh
        no-dsa
        no-dso
        no-dtls1
        no-ec2m
        no-err
        no-filenames
        no-gost
        no-hmac-drbg-kdf
        no-http
        no-idea
        no-ikev2kdf
        no-integrity-only-ciphers
        no-kbkdf
        no-krb5kdf
        no-legacy
        no-md4
        no-mdc2
        no-multiblock
        no-nextprotoneg
        no-ocb
        no-psk
        no-pvkkdf
        no-quic
        no-rc2
        no-rc4
        no-rfc3779
        no-rmd160
        no-scrypt
        no-seed
        no-shared
        no-siphash
        no-slh-dsa
        no-sm3
        no-sm4
        no-snmpkdf
        no-srp
        no-srtpkdf
        no-sshkdf
        no-sskdf
        no-ssl-trace
        no-thread-pool
        no-tls1_1
        no-ts
        no-ui-console
        no-whirlpool
        no-winstore
        no-x942kdf
        no-x963kdf
    BUILD_COMMAND ${MAKE} build_sw
    INSTALL_COMMAND ${MAKE} install_sw
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(openssl)
cleanup(openssl install)
