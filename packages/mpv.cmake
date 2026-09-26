ExternalProject_Add(mpv
    DEPENDS
        curl
        ffmpeg
        fribidi
        lcms2
        libarchive
        libass
        libbluray
        libiconv
        libjpeg
        libplacebo
        libzimg
        luajit
        shaderc
        spirv-cross
        subrandr
        uchardet
        vulkan
    GIT_REPOSITORY https://github.com/mpv-player/mpv.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /* !/fuzzers !/test"
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ${EXEC} CONF=1 meson setup <BINARY_DIR> <SOURCE_DIR>
        --prefix=${MINGW_INSTALL_PREFIX}
        --libdir=${MINGW_INSTALL_PREFIX}/lib
        --cross-file=${MESON_CROSS}
        --buildtype=release
        --default-library=shared
        --prefer-static
        -Doptimization=3
        -Db_lto=true
        ${mpv_lto_mode}
        -Damf=enabled
        -Dcdda=disabled
        -Dcplugins=disabled
        -Dcuda-hwaccel=enabled
        -Dcuda-interop=enabled
        -Dd3d-hwaccel=enabled
        -Dd3d11=enabled
        -Dd3d9-hwaccel=disabled
        -Ddirect3d=disabled
        -Ddvbin=disabled
        -Ddvdnav=disabled
        -Dfuzzers=false
        -Dgl=disabled
        -Dhtml-build=disabled
        -Diconv=enabled
        -Djavascript=disabled
        -Djpeg=enabled
        -Dlcms2=enabled
        -Dlibarchive=enabled
        -Dlibavdevice=enabled
        -Dlibbluray=enabled
        -Dlibcurl=enabled
        -Dlibmpv=false
        -Dlua=luajit
        -Dmanpage-build=disabled
        -Dpdf-build=disabled
        -Drubberband=disabled
        -Dshaderc=enabled
        -Dspirv-cross=enabled
        -Dsubrandr=enabled
        -Dtests=false
        -Duchardet=enabled
        -Dvapoursynth=disabled
        -Dvulkan=enabled
        -Dwasapi=enabled
        -Dwin32-smtc=enabled
        -Dzimg=enabled
        -Dzlib=enabled
    BUILD_COMMAND ${EXEC} LTO_JOB=1 ninja -C <BINARY_DIR>
    INSTALL_COMMAND ${EXEC} meson install -C <BINARY_DIR> --no-rebuild --tags runtime
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

force_rebuild_git(mpv)
force_meson_configure(mpv)
cleanup(mpv install)
