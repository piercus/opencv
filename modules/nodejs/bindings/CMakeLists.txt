set(MODULE_NAME "nodejs_bindings_generator")
set(OPENCV_MODULE_IS_PART_OF_WORLD FALSE)
ocv_add_module(${MODULE_NAME} INTERNAL)

set(OPENCV_NODEJS_SIGNATURES_FILE "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_signatures.json" CACHE INTERNAL "")
set(OPENCV_NODEJS_BINDINGS_DIR "${CMAKE_CURRENT_BINARY_DIR}" CACHE INTERNAL "")

# This file is included from a subdirectory
set(NODEJS_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../")

if(NOT OPENCV_SKIP_NODEJS_LOADER)
  include("${NODEJS_SOURCE_DIR}/nodejs_loader.cmake")
endif()

# get list of modules to wrap
set(OPENCV_NODEJS_MODULES)
foreach(m ${OPENCV_MODULES_BUILD})
  if (";${OPENCV_MODULE_${m}_WRAPPERS};" MATCHES ";nodejs;" AND HAVE_${m})
    list(APPEND OPENCV_NODEJS_MODULES ${m})
    #message(STATUS "\t${m}")
  endif()
endforeach()

set(opencv_hdrs "")
set(opencv_userdef_hdrs "")
foreach(m ${OPENCV_NODEJS_MODULES})
  foreach (hdr ${OPENCV_MODULE_${m}_HEADERS})
    ocv_is_subdir(is_sub "${OPENCV_MODULE_${m}_LOCATION}/include" "${hdr}")
    if(is_sub)
      list(APPEND opencv_hdrs "${hdr}")
    endif()
  endforeach()

  # both wrapping and C++ implementation
  file(GLOB hdr2 ${OPENCV_MODULE_${m}_LOCATION}/misc/nodejs/nodejs_*.hpp)
  list(SORT hdr2)
  list(APPEND opencv_hdrs ${hdr2})
  list(APPEND opencv_userdef_hdrs ${hdr2})

  file(GLOB hdr ${OPENCV_MODULE_${m}_LOCATION}/misc/nodejs/shadow*.hpp)
  list(SORT hdr)
  list(APPEND opencv_hdrs ${hdr})
  file(GLOB userdef_hdrs ${OPENCV_MODULE_${m}_LOCATION}/misc/nodejs/pyopencv*.hpp)
  list(SORT userdef_hdrs)
  list(APPEND opencv_userdef_hdrs ${userdef_hdrs})
endforeach(m)

# header blacklist
ocv_list_filterout(opencv_hdrs "modules/.*\\\\.h$")
ocv_list_filterout(opencv_hdrs "modules/core/.*/cuda/")
ocv_list_filterout(opencv_hdrs "modules/core/.*/hal/")
ocv_list_filterout(opencv_hdrs "modules/core/.*/opencl/")
ocv_list_filterout(opencv_hdrs "modules/.+/utils/.*")
ocv_list_filterout(opencv_hdrs "modules/.*\\\\.inl\\\\.h*")
ocv_list_filterout(opencv_hdrs "modules/.*_inl\\\\.h*")
ocv_list_filterout(opencv_hdrs "modules/.*\\\\.details\\\\.h*")
ocv_list_filterout(opencv_hdrs "modules/.*\\\\.private\\\\.h*")
ocv_list_filterout(opencv_hdrs "modules/.*/private\\\\.h*")
ocv_list_filterout(opencv_hdrs "modules/.*/legacy/.*")
ocv_list_filterout(opencv_hdrs "modules/.*/detection_based_tracker\\\\.hpp") # Conditional compilation
if(NOT HAVE_CUDA)
  ocv_list_filterout(opencv_hdrs "modules/cuda.*")
  ocv_list_filterout(opencv_hdrs "modules/cudev")
endif()

set(cv2_generated_files
    "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_generated_enums.h"
    "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_generated_funcs.h"
    "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_generated_include.h"
    "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_generated_modules.h"
    "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_generated_modules_content.h"
    "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_generated_types.h"
    "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_generated_types_content.h"
    "${OPENCV_NODEJS_SIGNATURES_FILE}"
)

string(REPLACE ";" "\n" opencv_hdrs_ "${opencv_hdrs}")
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/headers.txt" "${opencv_hdrs_}")
add_custom_command(
    OUTPUT ${cv2_generated_files}
    COMMAND "${NODEJS_DEFAULT_EXECUTABLE}" "${NODEJS_SOURCE_DIR}/src2/gen2.py" "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/headers.txt"
    DEPENDS "${NODEJS_SOURCE_DIR}/src2/gen2.py"
            "${NODEJS_SOURCE_DIR}/src2/hdr_parser.py"
            # not a real build dependency (file(WRITE) result): ${CMAKE_CURRENT_BINARY_DIR}/headers.txt
            ${opencv_hdrs}
    COMMENT "Generate files for Python bindings and documentation"
)

add_custom_target(gen_opencv_nodejs_source DEPENDS ${cv2_generated_files})

set(cv2_custom_hdr "${CMAKE_CURRENT_BINARY_DIR}/pyopencv_custom_headers.h")
set(cv2_custom_hdr_str "//user-defined headers\n")
foreach(uh ${opencv_userdef_hdrs})
    set(cv2_custom_hdr_str "${cv2_custom_hdr_str}#include \"${uh}\"\n")
endforeach(uh)
if(EXISTS "${cv2_custom_hdr}")
  file(READ "${cv2_custom_hdr}" __content)
else()
  set(__content "")
endif()
if("${__content}" STREQUAL "${cv2_custom_hdr_str}")
  # Up-to-date
else()
  file(WRITE "${cv2_custom_hdr}" "${cv2_custom_hdr_str}")
endif()
unset(__content)


#
# Configuration for standalone build of Python bindings
#
set(NODEJS_CONFIG_SCRIPT "")
ocv_cmake_script_append_var(NODEJS_CONFIG_SCRIPT
    CMAKE_BUILD_TYPE
    BUILD_SHARED_LIBS

    CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
    CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE

    CV_GCC CV_CLANG ENABLE_NOISY_WARNINGS

    CMAKE_MODULE_LINKER_FLAGS
    CMAKE_INSTALL_PREFIX
    OPENCV_NODEJS_INSTALL_PATH

    OpenCV_SOURCE_DIR

    OPENCV_FORCE_NODEJS_LIBS
    OPENCV_NODEJS_SKIP_LINKER_EXCLUDE_LIBS

    OPENCV_NODEJS_BINDINGS_DIR
    cv2_custom_hdr
    cv2_generated_files
)
set(CMAKE_HELPER_SCRIPT "${CMAKE_BINARY_DIR}/opencv_nodejs_config.cmake")
file(GENERATE OUTPUT "${CMAKE_HELPER_SCRIPT}" CONTENT "${NODEJS_CONFIG_SCRIPT}")
