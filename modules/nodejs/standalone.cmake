if(NOT DEFINED OpenCV_BINARY_DIR)
  message(FATAL_ERROR "Define OpenCV_BINARY_DIR")
endif()
include("${OpenCV_BINARY_DIR}/opencv_nodejs_config.cmake")
if(NOT DEFINED OpenCV_SOURCE_DIR)
  message(FATAL_ERROR "Missing OpenCV_SOURCE_DIR")
endif()
if(DEFINED OPENCV_NODEJS_STANDALONE_INSTALL_PATH)
  set(OPENCV_NODEJS_INSTALL_PATH "${OPENCV_NODEJS_STANDALONE_INSTALL_PATH}")
elseif(NOT OPENCV_NODEJS_INSTALL_PATH)
  message(FATAL_ERROR "Missing OPENCV_NODEJS_STANDALONE_INSTALL_PATH / OPENCV_NODEJS_INSTALL_PATH")
endif()

include("${OpenCV_SOURCE_DIR}/cmake/OpenCVUtils.cmake")

set(OPENCV_NODEJS_SKIP_DETECTION ON)
include("${OpenCV_SOURCE_DIR}/cmake/OpenCVDetectNodejs.cmake")
find_nodejs("${OPENCV_NODEJS_VERSION}" "${OPENCV_NODEJS_VERSION}" NODEJS_LIBRARY NODEJS_INCLUDE_DIR
    NODEJSINTERP_FOUND NODEJS_EXECUTABLE NODEJS_VERSION_STRING
    NODEJS_VERSION_MAJOR NODEJS_VERSION_MINOR NODEJSLIBS_FOUND
    NODEJSLIBS_VERSION_STRING NODEJS_LIBRARIES NODEJS_LIBRARY
    NODEJS_DEBUG_LIBRARIES NODEJS_LIBRARY_DEBUG NODEJS_INCLUDE_PATH
    NODEJS_INCLUDE_DIR NODEJS_INCLUDE_DIR2 NODEJS_PACKAGES_PATH
    NODEJS_NUMPY_INCLUDE_DIRS NODEJS_NUMPY_VERSION)
if(NOT NODEJS_EXECUTABLE OR NOT NODEJS_INCLUDE_DIR)
  message(FATAL_ERROR "Can't find Nodejs development files")
endif()
if(NOT NODEJS_NUMPY_INCLUDE_DIRS)
  message(FATAL_ERROR "Can't find Nodejs 'numpy' development files")
endif()

status("-----------------------------------------------------------------")
status("  Nodejs:")
status("    Interpreter:"   "${NODEJS_EXECUTABLE} (ver ${NODEJS_VERSION_STRING})")
status("    Libraries:"     "${NODEJS_LIBRARIES} (ver ${NODEJSLIBS_VERSION_STRING})")
status("    numpy:"         "${NODEJS_NUMPY_INCLUDE_DIRS} (ver ${NODEJS_NUMPY_VERSION})")
status("")
status("  Install to:" "${CMAKE_INSTALL_PREFIX}")
status("-----------------------------------------------------------------")

set(OpenCV_DIR "${OpenCV_BINARY_DIR}")
find_package(OpenCV REQUIRED)

set(NODEJS NODEJS)

macro(ocv_add_module module_name)
  set(the_module opencv_${module_name})
  project(${the_module} CXX)
endmacro()

macro(ocv_module_include_directories module)
  include_directories(${ARGN})
endmacro()

set(MODULE_NAME nodejs)
set(MODULE_INSTALL_SUBDIR "")
set(LIBRARY_OUTPUT_PATH "${CMAKE_BINARY_DIR}/lib")
set(deps ${OpenCV_LIBRARIES})
include("${CMAKE_CURRENT_LIST_DIR}/common.cmake")  # generate nodejs target

# done, cleanup
unset(OPENCV_BUILD_INFO_STR CACHE)  # remove from cache
