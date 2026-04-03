ExternalProject_Add(ffmpeg
    DEPENDS
        spirv-headers
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
        --enable-gpl
        --enable-lcms2
        --enable-libass
        --enable-libbluray
        --enable-libdav1d
        --enable-libfontconfig
        --enable-libfreetype
        --enable-libfribidi
        --enable-libharfbuzz
        --enable-libplacebo
        --enable-libshaderc
        --enable-libsoxr
        --enable-libwebp
        --enable-libxml2
        --enable-libzimg
        --enable-openssl
        --enable-runtime-cpudetect
        --enable-version3
        --disable-cuvid
        --disable-debug
        --disable-doc
        --disable-dxva2
        --disable-ffplay
        --disable-ffprobe
        --disable-indev=dshow
        --disable-indev=gdigrab
        --disable-indev=vfwcap
        --disable-outdevs
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
