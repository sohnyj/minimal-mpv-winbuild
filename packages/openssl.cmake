ExternalProject_Add(openssl
    DEPENDS
        brotli
        zlib
        zstd
    GIT_REPOSITORY https://github.com/openssl/openssl.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !demos !test"
    GIT_SUBMODULES ""
    UPDATE_COMMAND ""
    BUILD_IN_SOURCE 1
    CONFIGURE_COMMAND ${EXEC} CONF=1 <SOURCE_DIR>/Configure
        --cross-compile-prefix=${TARGET_ARCH}-
        --prefix=${MINGW_INSTALL_PREFIX}
        --libdir=lib
        --release
        mingw64
        enable-brotli
        enable-ec_nistp_64_gcc_128
        enable-zstd
        threads
        zlib
        no-autoload-config
        no-apps
        no-aria
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
        no-demos
        no-dh
        no-docs
        no-dsa
        no-dso
        no-ec2m
        no-err
        no-filenames
        no-gost
        no-idea
        no-ktls
        no-legacy
        no-md2
        no-md4
        no-mdc2
        no-module
        no-nextprotoneg
        no-ocsp
        no-rc2
        no-rc4
        no-rc5
        no-rfc3779
        no-rmd160
        no-seed
        no-shared
        no-siphash
        no-sm2
        no-sm3
        no-sm4
        no-srp
        no-ssl-trace
        no-tests
        no-trace
        no-ts
        no-uplink
        no-whirlpool
    BUILD_COMMAND ${MAKE} build_sw
    INSTALL_COMMAND ${MAKE} install_sw
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(openssl)
cleanup(openssl install)
