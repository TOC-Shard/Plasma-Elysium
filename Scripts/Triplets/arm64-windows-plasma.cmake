set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_DISABLE_COMPILER_TRACKING TRUE)

# See x64-windows-plasma.cmake for why - keep in sync.
if(DEFINED ENV{VSINSTALLDIR} AND NOT "$ENV{VSINSTALLDIR}" STREQUAL "")
    string(REGEX REPLACE "[\\/]+$" "" _plasma_vs_path "$ENV{VSINSTALLDIR}")
    set(VCPKG_VISUAL_STUDIO_PATH "${_plasma_vs_path}")
    unset(_plasma_vs_path)
    if(DEFINED ENV{VCToolsVersion} AND NOT "$ENV{VCToolsVersion}" STREQUAL "")
        set(VCPKG_PLATFORM_TOOLSET_VERSION "$ENV{VCToolsVersion}")
    endif()
else()
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
# If you update this list, remember to synchronize {x86,x64}-windows-plasma.cmake.
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
