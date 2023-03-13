# ----------------------------------------------------------------------------
#  CMake file for python support
# ----------------------------------------------------------------------------
if(DEFINED OPENCV_INITIAL_PASS)  # OpenCV build

if(ANDROID OR APPLE_FRAMEWORK OR WINRT)
  ocv_module_disable_(nodejs)
  return()
elseif(BUILD_opencv_world OR (WIN32 AND CMAKE_BUILD_TYPE STREQUAL "Debug"))
  if(NOT DEFINED BUILD_opencv_nodejs)
    set(__disable_nodejs ON)
  endif()
endif()

add_subdirectory(bindings)

add_subdirectory(test)

if(__disable_nodejs)
  ocv_module_disable_(nodejs)
endif()
if(__disable_nodejs)
  return()
endif()

add_subdirectory(nodejs)

else()  # standalone build

cmake_minimum_required(VERSION 2.8.12.2)
project(OpenCVPython CXX C)
include("./standalone.cmake")

endif()
