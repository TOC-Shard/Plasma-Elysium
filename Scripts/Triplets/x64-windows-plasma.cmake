set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_DISABLE_COMPILER_TRACKING TRUE)

# Without this, vcpkg's own per-port builds auto-detect "the newest
# installed Visual Studio" independently of whatever generator/toolset the
# outer project is configured with. On a machine with both VS2022 and a
# newer VS install side by side, that silently picks the newer one for
# vcpkg's builds while the main project stays pinned to something older
# (or vice versa) - the two STL/CRT versions aren't link-compatible.
# Confirmed empirically (both on this project and, isolated, on a sibling
# fork sharing this machine) that this specifically surfaces as
# OpenAL32.lib failing with "unresolved external symbol __std_rotate" (an
# MSVC STL vectorized-algorithm helper only exported starting with a
# certain toolset version) at the final link step, not at compile time -
# and that VCPKG_PLATFORM_TOOLSET alone isn't reliably sufficient to
# prevent it, since a newer VS release can ALSO carry an installed
# older-toolset-compatible component side by side, leaving a toolset-only
# filter still ambiguous between instances.
#
# Rather than hardcoding one specific VS version, match whichever one is
# ACTUALLY building right now: vcvarsall.bat / Visual Studio's own
# CMake-IDE-integration environment inheritance sets VSINSTALLDIR and
# VCToolsVersion in the process environment before cmake.exe is even
# invoked - if present, they describe exactly which VS instance/toolset
# this specific build session is already using, and vcpkg's own
# per-port build processes inherit the same environment, so reading it
# here just tells vcpkg to match rather than independently re-detect
# "whatever's newest installed" on its own. This makes switching which VS
# version you build with (e.g. VS2022 vs. a newer release installed
# alongside it) something that "just works" without editing this file.
if(DEFINED ENV{VSINSTALLDIR} AND NOT "$ENV{VSINSTALLDIR}" STREQUAL "")
    string(REGEX REPLACE "[\\/]+$" "" _plasma_vs_path "$ENV{VSINSTALLDIR}")
    set(VCPKG_VISUAL_STUDIO_PATH "${_plasma_vs_path}")
    unset(_plasma_vs_path)
    if(DEFINED ENV{VCToolsVersion} AND NOT "$ENV{VCToolsVersion}" STREQUAL "")
        set(VCPKG_PLATFORM_TOOLSET_VERSION "$ENV{VCToolsVersion}")
    endif()
else()
    # No dev-environment context to inherit (e.g. CI invoking cmake
    # directly with an explicit -G "Visual Studio ..." generator, without
    # first running vcvarsall) - fall back to pinning VS2022 specifically,
    # since that's what this project's CI workflow targets today. Update
    # the version range here (and VCPKG_PLATFORM_TOOLSET below) if that
    # generator choice ever changes.
    find_program(_plasma_vswhere vswhere
        PATHS "$ENV{ProgramFiles\(x86\)}/Microsoft Visual Studio/Installer"
              "$ENV{ProgramFiles}/Microsoft Visual Studio/Installer"
    )
    if(_plasma_vswhere)
        execute_process(
            COMMAND "${_plasma_vswhere}" -latest -version "[17.0,18.0)" -property installationPath
            OUTPUT_VARIABLE _plasma_vs2022_path
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        if(_plasma_vs2022_path)
            set(VCPKG_VISUAL_STUDIO_PATH "${_plasma_vs2022_path}")
        endif()
        unset(_plasma_vs2022_path)
    endif()
    unset(_plasma_vswhere CACHE)
    set(VCPKG_PLATFORM_TOOLSET v143)
endif()

# Unfortunately, we cannot include() anything from here because CMAKE_CURRENT_LIST_DIR is "wrong."
# If you update this list, remember to synchronize {x86,arm64}-windows-plasma.cmake.
set(_PLASMA_DYNAMIC_LIBRARIES
    cairo
    python2
    python3
)

cmake_policy(SET CMP0057 NEW)
if(PORT IN_LIST _PLASMA_DYNAMIC_LIBRARIES)
    set(VCPKG_LIBRARY_LINKAGE dynamic)
else()
    set(VCPKG_LIBRARY_LINKAGE static)
endif()

# This is a terrible hack because meson seems to suck.
if(PORT STREQUAL cairo)
    set(VCPKG_BUILD_TYPE release)
endif()
