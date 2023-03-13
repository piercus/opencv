# Find specified Nodejs version
# Arguments:
#   preferred_version (value): Version to check for first
#   min_version (value): Minimum supported version
#   library_env (value): Name of Nodejs library ENV variable to check
#   include_dir_env (value): Name of Nodejs include directory ENV variable to check
#   found (variable): Set if interpreter found
#   executable (variable): Output of executable found
#   version_string (variable): Output of found version
#   version_major (variable): Output of found major version
#   version_minor (variable): Output of found minor version
#   libs_found (variable): Set if libs found
#   libs_version_string (variable): Output of found libs version
#   libraries (variable): Output of found Nodejs libraries
#   library (variable): Output of found Nodejs library
#   debug_libraries (variable): Output of found Nodejs debug libraries
#   debug_library (variable): Output of found Nodejs debug library
#   include_path (variable): Output of found Nodejs include path
#   include_dir (variable): Output of found Nodejs include dir
#   include_dir2 (variable): Output of found Nodejs include dir2
#   packages_path (variable): Output of found Nodejs packages path
#   numpy_include_dirs (variable): Output of found Nodejs Numpy include dirs
#   numpy_version (variable): Output of found Nodejs Numpy version
function(find_nodejs preferred_version min_version library_env include_dir_env
         found executable version_string version_major version_minor
         libs_found libs_version_string libraries library debug_libraries
         debug_library include_path include_dir include_dir2 packages_path
         numpy_include_dirs numpy_version)
if(NOT ${found})
  if(" ${executable}" STREQUAL " NODEJS_EXECUTABLE")
    set(__update_nodejs_vars 0)
  else()
    set(__update_nodejs_vars 1)
  endif()

  ocv_check_environment_variables(${executable})
  if(${executable})
    set(NODEJS_EXECUTABLE "${${executable}}")
  endif()

  if(WIN32 AND NOT ${executable} AND OPENCV_NODEJS_PREFER_WIN32_REGISTRY)  # deprecated
    # search for executable with the same bitness as resulting binaries
    # standard FindNodejsInterp always prefers executable from system path
    # this is really important because we are using the interpreter for numpy search and for choosing the install location
    foreach(_CURRENT_VERSION ${Nodejs_ADDITIONAL_VERSIONS} "${preferred_version}" "${min_version}")
      find_host_program(NODEJS_EXECUTABLE
        NAMES nodejs${_CURRENT_VERSION} nodejs
        PATHS
          [HKEY_LOCAL_MACHINE\\\\SOFTWARE\\\\Nodejs\\\\NodejsCore\\\\${_CURRENT_VERSION}\\\\InstallPath]
          [HKEY_CURRENT_USER\\\\SOFTWARE\\\\Nodejs\\\\NodejsCore\\\\${_CURRENT_VERSION}\\\\InstallPath]
        NO_SYSTEM_ENVIRONMENT_PATH
      )
    endforeach()
  endif()

  if(preferred_version)
    set(__nodejs_package_version "${preferred_version} EXACT")
    find_host_package(NodejsInterp "${preferred_version}" EXACT)
    if(NOT NODEJSINTERP_FOUND)
      message(STATUS "Nodejs is not found: ${preferred_version} EXACT")
    endif()
  elseif(min_version)
    set(__nodejs_package_version "${min_version}")
    find_host_package(NodejsInterp "${min_version}")
  else()
    set(__nodejs_package_version "")
    find_host_package(NodejsInterp)
  endif()

  string(REGEX MATCH "^[0-9]+" _nodejs_version_major "${min_version}")

  if(NODEJSINTERP_FOUND)
    # Check if nodejs major version is correct
    if(" ${_nodejs_version_major}" STREQUAL " ")
      set(_nodejs_version_major "${NODEJS_VERSION_MAJOR}")
    endif()
    if(NOT "${_nodejs_version_major}" STREQUAL "${NODEJS_VERSION_MAJOR}"
        AND NOT DEFINED ${executable}
    )
      if(NOT OPENCV_SKIP_NODEJS_WARNING)
        message(WARNING "CMake's 'find_host_package(NodejsInterp ${__nodejs_package_version})' found wrong Nodejs version:\n"
                        "NODEJS_EXECUTABLE=${NODEJS_EXECUTABLE}\n"
                        "NODEJS_VERSION_STRING=${NODEJS_VERSION_STRING}\n"
                        "Consider providing the '${executable}' variable via CMake command line or environment variables\n")
      endif()
      ocv_clear_vars(NODEJSINTERP_FOUND NODEJS_EXECUTABLE NODEJS_VERSION_STRING NODEJS_VERSION_MAJOR NODEJS_VERSION_MINOR NODEJS_VERSION_PATCH)
      if(NOT CMAKE_VERSION VERSION_LESS "3.12")
        if(_nodejs_version_major STREQUAL "2")
          set(__NODEJS_PREFIX Nodejs2)
        else()
          set(__NODEJS_PREFIX Nodejs3)
        endif()
        find_host_package(${__NODEJS_PREFIX} "${preferred_version}" COMPONENTS Interpreter)
        if(${__NODEJS_PREFIX}_EXECUTABLE)
          set(NODEJS_EXECUTABLE "${${__NODEJS_PREFIX}_EXECUTABLE}")
          find_host_package(NodejsInterp "${preferred_version}")  # Populate other variables
        endif()
      else()
        message(STATUS "Consider using CMake 3.12+ for better Nodejs support")
      endif()
    endif()
    if(NODEJSINTERP_FOUND AND "${_nodejs_version_major}" STREQUAL "${NODEJS_VERSION_MAJOR}")
      # Copy outputs
      set(_found ${NODEJSINTERP_FOUND})
      set(_executable ${NODEJS_EXECUTABLE})
      set(_version_string ${NODEJS_VERSION_STRING})
      set(_version_major ${NODEJS_VERSION_MAJOR})
      set(_version_minor ${NODEJS_VERSION_MINOR})
      set(_version_patch ${NODEJS_VERSION_PATCH})
    endif()
  endif()

  if(__update_nodejs_vars)
    # Clear find_host_package side effects
    unset(NODEJSINTERP_FOUND)
    unset(NODEJS_EXECUTABLE CACHE)
    unset(NODEJS_VERSION_STRING)
    unset(NODEJS_VERSION_MAJOR)
    unset(NODEJS_VERSION_MINOR)
    unset(NODEJS_VERSION_PATCH)
  endif()

  if(_found)
    set(_version_major_minor "${_version_major}.${_version_minor}")

    if(NOT ANDROID AND NOT APPLE_FRAMEWORK)
      ocv_check_environment_variables(${library_env} ${include_dir_env})
      if(NOT ${${library_env}} STREQUAL "")
          set(NODEJS_LIBRARY "${${library_env}}")
      endif()
      if(NOT ${${include_dir_env}} STREQUAL "")
          set(NODEJS_INCLUDE_DIR "${${include_dir_env}}")
      endif()

      # not using _version_string here, because it might not conform to the CMake version format
      if(CMAKE_CROSSCOMPILING)
        # builder version can differ from target, matching base version (e.g. 2.7)
        find_package(NodejsLibs "${_version_major_minor}")
      else()
        find_package(NodejsLibs "${_version_major_minor}.${_version_patch}" EXACT)
      endif()

      if(NODEJSLIBS_FOUND)
        # Copy outputs
        set(_libs_found ${NODEJSLIBS_FOUND})
        set(_libraries ${NODEJS_LIBRARIES})
        set(_include_path ${NODEJS_INCLUDE_PATH})
        set(_include_dirs ${NODEJS_INCLUDE_DIRS})
        set(_debug_libraries ${NODEJS_DEBUG_LIBRARIES})
        set(_libs_version_string ${NODEJSLIBS_VERSION_STRING})
        set(_debug_library ${NODEJS_DEBUG_LIBRARY})
        set(_library ${NODEJS_LIBRARY})
        set(_library_debug ${NODEJS_LIBRARY_DEBUG})
        set(_library_release ${NODEJS_LIBRARY_RELEASE})
        set(_include_dir ${NODEJS_INCLUDE_DIR})
        set(_include_dir2 ${NODEJS_INCLUDE_DIR2})
      endif()
      if(__update_nodejs_vars)
        # Clear find_package side effects
        unset(NODEJSLIBS_FOUND)
        unset(NODEJS_LIBRARIES)
        unset(NODEJS_INCLUDE_PATH)
        unset(NODEJS_INCLUDE_DIRS)
        unset(NODEJS_DEBUG_LIBRARIES)
        unset(NODEJSLIBS_VERSION_STRING)
        unset(NODEJS_DEBUG_LIBRARY CACHE)
        unset(NODEJS_LIBRARY)
        unset(NODEJS_LIBRARY_DEBUG)
        unset(NODEJS_LIBRARY_RELEASE)
        unset(NODEJS_LIBRARY CACHE)
        unset(NODEJS_LIBRARY_DEBUG CACHE)
        unset(NODEJS_LIBRARY_RELEASE CACHE)
        unset(NODEJS_INCLUDE_DIR CACHE)
        unset(NODEJS_INCLUDE_DIR2 CACHE)
      endif()
    endif()

    if(NOT ANDROID AND NOT IOS)
      if(CMAKE_HOST_UNIX)
        execute_process(COMMAND ${_executable} -c "from sysconfig import *; print(get_path('purelib'))"
                        RESULT_VARIABLE _cvpy_process
                        OUTPUT_VARIABLE _std_packages_path
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        if("${_std_packages_path}" MATCHES "site-packages")
          set(_packages_path "nodejs${_version_major_minor}/site-packages")
        else() #debian based assumed, install to the dist-packages.
          set(_packages_path "nodejs${_version_major_minor}/dist-packages")
        endif()
        set(_packages_path "lib/${_packages_path}")
      elseif(CMAKE_HOST_WIN32)
        get_filename_component(_path "${_executable}" PATH)
        file(TO_CMAKE_PATH "${_path}" _path)
        if(NOT EXISTS "${_path}/Lib/site-packages")
          unset(_path)
          get_filename_component(_path "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Nodejs\\NodejsCore\\${_version_major_minor}\\InstallPath]" ABSOLUTE)
          if(NOT _path)
             get_filename_component(_path "[HKEY_CURRENT_USER\\SOFTWARE\\Nodejs\\NodejsCore\\${_version_major_minor}\\InstallPath]" ABSOLUTE)
          endif()
          file(TO_CMAKE_PATH "${_path}" _path)
        endif()
        set(_packages_path "${_path}/Lib/site-packages")
        unset(_path)
      endif()

      set(_numpy_include_dirs "${${numpy_include_dirs}}")

      if(NOT _numpy_include_dirs)
        if(CMAKE_CROSSCOMPILING)
          message(STATUS "Cannot probe for Nodejs/Numpy support (because we are cross-compiling OpenCV)")
          message(STATUS "If you want to enable Nodejs/Numpy support, set the following variables:")
          message(STATUS "  NODEJS_INCLUDE_PATH")
          message(STATUS "  NODEJS_LIBRARIES (optional on Unix-like systems)")
          message(STATUS "  NODEJS_NUMPY_INCLUDE_DIRS")
        else()
          # Attempt to discover the NumPy include directory. If this succeeds, then build nodejs API with NumPy
          execute_process(COMMAND "${_executable}" -c "import os; os.environ['DISTUTILS_USE_SDK']='1'; import numpy.distutils; print(os.pathsep.join(numpy.distutils.misc_util.get_numpy_include_dirs()))"
                          RESULT_VARIABLE _numpy_process
                          OUTPUT_VARIABLE _numpy_include_dirs
                          OUTPUT_STRIP_TRAILING_WHITESPACE)

          if(NOT _numpy_process EQUAL 0)
              unset(_numpy_include_dirs)
          endif()
        endif()
      endif()

      if(_numpy_include_dirs)
        file(TO_CMAKE_PATH "${_numpy_include_dirs}" _numpy_include_dirs)
        if(CMAKE_CROSSCOMPILING)
          if(NOT _numpy_version)
            set(_numpy_version "undefined - cannot be probed because of the cross-compilation")
          endif()
        else()
          execute_process(COMMAND "${_executable}" -c "import numpy; print(numpy.version.version)"
                          RESULT_VARIABLE _numpy_process
                          OUTPUT_VARIABLE _numpy_version
                          OUTPUT_STRIP_TRAILING_WHITESPACE)
        endif()
      endif()
    endif(NOT ANDROID AND NOT IOS)
  endif()

  # Export return values
  set(${found} "${_found}" CACHE INTERNAL "")
  set(${executable} "${_executable}" CACHE FILEPATH "Path to Nodejs interpreter")
  set(${version_string} "${_version_string}" CACHE INTERNAL "")
  set(${version_major} "${_version_major}" CACHE INTERNAL "")
  set(${version_minor} "${_version_minor}" CACHE INTERNAL "")
  set(${libs_found} "${_libs_found}" CACHE INTERNAL "")
  set(${libs_version_string} "${_libs_version_string}" CACHE INTERNAL "")
  set(${libraries} "${_libraries}" CACHE INTERNAL "Nodejs libraries")
  set(${library} "${_library}" CACHE FILEPATH "Path to Nodejs library")
  set(${debug_libraries} "${_debug_libraries}" CACHE INTERNAL "")
  set(${debug_library} "${_debug_library}" CACHE FILEPATH "Path to Nodejs debug")
  set(${include_path} "${_include_path}" CACHE INTERNAL "")
  set(${include_dir} "${_include_dir}" CACHE PATH "Nodejs include dir")
  set(${include_dir2} "${_include_dir2}" CACHE PATH "Nodejs include dir 2")
  set(${packages_path} "${_packages_path}" CACHE PATH "Where to install the nodejs packages.")
  set(${numpy_include_dirs} ${_numpy_include_dirs} CACHE PATH "Path to numpy headers")
  set(${numpy_version} "${_numpy_version}" CACHE INTERNAL "")
endif()
endfunction(find_nodejs)

if(OPENCV_NODEJS_SKIP_DETECTION)
  return()
endif()

option(OPENCV_NODEJS_VERSION "Nodejs3 version" "")
find_nodejs("${OPENCV_NODEJS_VERSION}" "${MIN_VER_NODEJS}" NODEJS_LIBRARY NODEJS_INCLUDE_DIR
    NODEJSINTERP_FOUND NODEJS_EXECUTABLE NODEJS_VERSION_STRING
    NODEJS_VERSION_MAJOR NODEJS_VERSION_MINOR NODEJSLIBS_FOUND
    NODEJSLIBS_VERSION_STRING NODEJS_LIBRARIES NODEJS_LIBRARY
    NODEJS_DEBUG_LIBRARIES NODEJS_LIBRARY_DEBUG NODEJS_INCLUDE_PATH
    NODEJS_INCLUDE_DIR NODEJS_INCLUDE_DIR2 NODEJS_PACKAGES_PATH
    NODEJS_NUMPY_INCLUDE_DIRS NODEJS_NUMPY_VERSION)


if(NODEJS_DEFAULT_EXECUTABLE)
    set(NODEJS_DEFAULT_AVAILABLE "TRUE")
elseif(NODEJS_EXECUTABLE AND NODEJSINTERP_FOUND)
    # Use Nodejs 3 as fallback Nodejs interpreter (if there is no Nodejs 2)
    set(NODEJS_DEFAULT_AVAILABLE "TRUE")
    set(NODEJS_DEFAULT_EXECUTABLE "${NODEJS_EXECUTABLE}")
endif()
