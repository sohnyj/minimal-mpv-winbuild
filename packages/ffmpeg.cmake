ExternalProject_Add(ffmpeg
    DEPENDS
        nvcodec-headers
        bzip2
        lcms2
        openssl
        libass
        libbluray
        libpng
        libsoxr
        libwebp
        libzimg
        fontconfig
        harfbuzz
        libxml2
        shaderc
        libplacebo
        dav1d
    GIT_REPOSITORY https://github.com/FFmpeg/FFmpeg.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !tests/ref/fate"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 <SOURCE_DIR>/configure
        --cross-prefix=${TARGET_ARCH}-
        --prefix=${MINGW_INSTALL_PREFIX}
        --arch=${TARGET_CPU}
        --target-os=mingw32
        --pkg-config-flags=--static
        --enable-cross-compile
        --enable-runtime-cpudetect
        --enable-gpl
        --enable-version3
        --enable-libass
        --enable-libbluray
        --enable-libfreetype
        --enable-libfribidi
        --enable-libfontconfig
        --enable-libharfbuzz
        --enable-lcms2
        --enable-libsoxr
        --enable-libwebp
        --enable-libdav1d
        --enable-libzimg
        --enable-openssl
        --enable-libxml2
        --enable-libplacebo
        --enable-libshaderc
        --disable-debug
        --disable-doc
        --disable-ffplay
        --disable-ffprobe
        --disable-indev=gdigrab
        --disable-indev=vfwcap
        --disable-outdevs
        --disable-cuvid
        --disable-dxva2
        --disable-sdl2
        --disable-vaapi
        --disable-vdpau
        ${ffmpeg_lto}
        --extra-cflags='-Wno-error=int-conversion'
        "--extra-libs='${ffmpeg_extra_libs}'" # -lstdc++ / -lc++ needs by shaderc
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(ffmpeg)
cleanup(ffmpeg install)
