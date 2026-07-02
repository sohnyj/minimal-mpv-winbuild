ExternalProject_Add(mpv
    DEPENDS
        curl
        ffmpeg
        fontconfig
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
    GIT_CLONE_FLAGS "--filter=tree:0"
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
        -Dcuda-hwaccel=enabled
        -Dcuda-interop=enabled
        -Dd3d-hwaccel=enabled
        -Dd3d11=enabled
        -Diconv=enabled
        -Djpeg=enabled
        -Dlcms2=enabled
        -Dlibarchive=enabled
        -Dlibavdevice=enabled
        -Dlibbluray=enabled
        -Dlibcurl=enabled
        -Dlua=luajit
        -Dshaderc=enabled
        -Dspirv-cross=enabled
        -Dsubrandr=enabled
        -Duchardet=enabled
        -Dvulkan=enabled
        -Dwasapi=enabled
        -Dwin32-smtc=enabled
        -Dzimg=enabled
        -Dzlib=enabled
        -Dcdda=disabled
        -Dcplugins=disabled
        -Dd3d9-hwaccel=disabled
        -Ddirect3d=disabled
        -Ddvbin=disabled
        -Ddvdnav=disabled
        -Dfuzzers=false
        -Dgl=disabled
        -Dhtml-build=disabled
        -Djavascript=disabled
        -Dlibmpv=false
        -Dmanpage-build=disabled
        -Dpdf-build=disabled
        -Drubberband=disabled
        -Dtests=false
        -Dvapoursynth=disabled
    BUILD_COMMAND ${EXEC} LTO_JOB=1 ninja -C <BINARY_DIR>
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1 LOG_CONFIGURE 1 LOG_BUILD 1 LOG_INSTALL 1
)

ExternalProject_Add_Step(mpv strip-binary
    DEPENDEES build
    COMMENT "Stripping mpv binaries"
)

ExternalProject_Add_Step(mpv copy-binary
    DEPENDEES strip-binary
    COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/mpv.exe                           ${CMAKE_CURRENT_BINARY_DIR}/mpv-package/mpv.exe
    COMMAND ${CMAKE_COMMAND} -E copy <BINARY_DIR>/mpv.com                           ${CMAKE_CURRENT_BINARY_DIR}/mpv-package/mpv.com
    COMMAND ${CMAKE_COMMAND} -E copy ${MINGW_INSTALL_PREFIX}/etc/fonts/fonts.conf   ${CMAKE_CURRENT_BINARY_DIR}/mpv-package/mpv/fonts.conf
    COMMENT "Copying mpv binaries"
)

set(RENAME ${CMAKE_CURRENT_BINARY_DIR}/mpv-prefix/src/rename.sh)
file(WRITE ${RENAME}
"#!/bin/bash
cd $1
GIT=$(git rev-parse --short=7 HEAD)
mv $2 $2-git-\${GIT}")

ExternalProject_Add_Step(mpv copy-package-dir
    DEPENDEES copy-binary
    COMMAND chmod 755 ${RENAME}
    COMMAND mv ${CMAKE_CURRENT_BINARY_DIR}/mpv-package ${CMAKE_BINARY_DIR}/mpv-${TARGET_CPU}${x86_64_LEVEL}-${BUILDDATE}
    COMMAND ${RENAME} <SOURCE_DIR> ${CMAKE_BINARY_DIR}/mpv-${TARGET_CPU}${x86_64_LEVEL}-${BUILDDATE}

    COMMENT "Moving mpv package folder"
    LOG 1
)

force_rebuild_git(mpv)
force_meson_configure(mpv)
cleanup(mpv copy-package-dir)
