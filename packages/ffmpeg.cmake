ExternalProject_Add(ffmpeg
    DEPENDS
        amf-headers
        bzip2
        dav1d
        fontconfig
        freetype2
        fribidi
        harfbuzz
        lcms2
        libass
        libbluray
        libiconv
        libplacebo
        libsoxr
        libvpl
        libwebp
        libxml2
        libzimg
        nvcodec-headers
        openssl
        shaderc
        spirv-headers
        xz
        zlib
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
        --enable-amf
        --enable-bzlib
        --enable-cross-compile
        --enable-cuda-llvm
        --enable-d3d11va
        --enable-ffnvcodec
        --enable-gpl
        --enable-iconv
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
        --enable-libvpl
        --enable-libwebp
        --enable-libxml2
        --enable-libzimg
        --enable-lzma
        --enable-nvdec
        --enable-nvenc
        --enable-openssl
        --enable-runtime-cpudetect
        --enable-version3
        --enable-vulkan
        --enable-zlib
        --disable-cuvid
        --disable-debug
        --disable-doc
        --disable-dxva2
        --disable-ffplay
        --disable-ffprobe
        --disable-indev=gdigrab
        --disable-indev=vfwcap
        --disable-mediafoundation
        --disable-outdevs
        --disable-sdl2
        --disable-vaapi
        --disable-vdpau
        --disable-protocol=ftp
        --disable-protocol=gopher
        --disable-protocol=gophers
        --disable-protocol=icecast
        --disable-protocol=md5
        --disable-protocol=mmsh
        --disable-protocol=mmst
        --disable-protocol=prompeg
        --disable-protocol=tee
        --disable-protocol=udplite
        ${ffmpeg_lto}
        --extra-cflags='-Wno-error=int-conversion'
        "--extra-libs='${ffmpeg_extra_libs}'" # -lstdc++ / -lc++ needs by shaderc
    BUILD_COMMAND ${MAKE}
    INSTALL_COMMAND ${MAKE} install
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(ffmpeg)
cleanup(ffmpeg install)
