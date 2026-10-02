set(windows_winmd "crates/libs/default/Windows.winmd")
ExternalProject_Add(windows-rs
    GIT_REPOSITORY https://github.com/microsoft/windows-rs.git
    SOURCE_DIR ${SOURCE_LOCATION}
    GIT_CLONE_FLAGS "--sparse --filter=tree:0"
    GIT_CLONE_POST_COMMAND "sparse-checkout set --no-cone /${windows_winmd}"
    GIT_REMOTE_NAME origin
    GIT_TAG master
    UPDATE_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

force_rebuild_git(windows-rs)
cleanup(windows-rs install)
get_property(WINDOWS_RS_SRC TARGET windows-rs PROPERTY _EP_SOURCE_DIR)
