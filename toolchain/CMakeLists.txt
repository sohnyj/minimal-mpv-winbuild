set_property(DIRECTORY PROPERTY EP_STEP_TARGETS download)
include(${PROJECT_SOURCE_DIR}/cmake/toolchain_check.cmake)
list(APPEND ep
    # depth 0
    cppwinrt
    llvm
    ${llvm_wrapper}
    mingw-w64
    rustup
    # depth 1
    gendef
    llvm-compiler-rt
    mingw-w64-headers
    widl
    # depth 2
    mingw-w64-crt
    # depth 3
    llvm-compiler-rt-builtin
    winpthreads
    # depth 4
    llvm-libcxx
    # depth 5
    llvm-clang
)
foreach(package IN LISTS ep)
    if(NOT ${SINGLE_SOURCE_LOCATION} STREQUAL "")
        set(SOURCE_LOCATION "${SINGLE_SOURCE_LOCATION}/${package}")
    endif()
    if(package MATCHES "llvm")
        include(${CMAKE_CURRENT_SOURCE_DIR}/llvm/${package}.cmake)
    else()
        include(${CMAKE_CURRENT_SOURCE_DIR}/${package}.cmake)
    endif()
    set(SOURCE_LOCATION "")
endforeach()
list(LENGTH ep ep_length)
message(STATUS "Parsing ${ep_length} toolchain packages")
