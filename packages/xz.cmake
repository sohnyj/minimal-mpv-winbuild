ExternalProject_Add(xz
    GIT_REPOSITORY https://github.com/tukaani-project/xz.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/cmake !/doc !/dos !/doxygen !/extra !/po4a !/windows"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 autoreconf -fi && <SOURCE_DIR>/configure
        --host=${TARGET_ARCH}
        --prefix=${MINGW_INSTALL_PREFIX}
        --disable-doc
        --disable-lzmadec
        --disable-lzmainfo
        --disable-microlzma
        --disable-nls
        --disable-scripts
        --disable-shared
        --disable-xz
        --disable-xzdec
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    BUILD_IN_SOURCE 1
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(xz)
cleanup(xz install)
