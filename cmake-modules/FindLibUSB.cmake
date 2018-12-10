#.rst
# FindLibUSB
# ------------
#
# Created by Walter Gray.
# Locate and configure LibUSB
#
# Interface Targets
# ^^^^^^^^^^^^^^^^^
#   LibUSB::LibUSB
#
# Variables
# ^^^^^^^^^
#  LibUSB_ROOT_DIR
#  LibUSB_FOUND
#  LibUSB_INCLUDE_DIR
#  LibUSB_LIBRARY
#  LibUSB_INTERFACE_LIB
#  LibUSB_SHARED_LIB


if(LibUSB_FIND_VERSION_EXACT)
  if(NOT LibUSB_ROOT_DIR MATCHES ".*${LibUSB_FIND_VERSION}")
    unset(LibUSB_ROOT_DIR CACHE)
    unset(LibUSB_LIBRARY CACHE)
    unset(LibUSB_SHARED_LIB CACHE)
    unset(LibUSB_IMPORT_LIB CACHE)
    unset(LibUSB_LIBRARY_ORIGINAL CACHE)
  endif()
else()
  set(_additional_path_suffixes libusb)
endif()

find_path(LibUSB_ROOT_DIR
  HINTS ${EXTERNAL_LIBRARY_DIR}
  NAMES include/libusb/libusb.h
  PATH_SUFFIXES libusb-${LibUSB_FIND_VERSION} libusb-1.0.22 ${_additional_path_suffixes}
)

set(LibUSB_INCLUDE_DIR "${LibUSB_ROOT_DIR}/include" CACHE FILEPATH "" FORCE)

if(MSVC)
  find_library(LibUSB_IMPORT_LIB
    NAMES usb usb-${LibUSB_FIND_VERSION} libusb-1.0.lib HINTS ${LibUSB_ROOT_DIR}/lib)
  find_file(LibUSB_SHARED_LIB NAMES "libusb-1.0.dll" HINTS ${LibUSB_ROOT_DIR}/lib)
else()
  find_library(LibUSB_SHARED_LIB
    NAMES usb usb-${LibUSB_FIND_VERSION} HINTS ${LibUSB_ROOT_DIR}/lib)
endif()

#This is a little bit of a hack - if this becomes a common use-case we may need
#to add the ability to specify destination file names to add_local_files
if(BUILD_LINUX AND NOT BUILD_ANDROID AND NOT LibUSB_LIBRARY_ORIGINAL)
  set(LibUSB_LIBRARY_ORIGINAL ${LibUSB_SHARED_LIB} CACHE FILEPATH "")
  mark_as_advanced(LibUSB_LIBRARY_ORIGINAL)

  get_filename_component(_basename "${LibUSB_SHARED_LIB}" NAME_WE)
  set(LibUSB_SHARED_LIB ${CMAKE_BINARY_DIR}/libusb-temp/${_basename}.0${CMAKE_SHARED_LIBRARY_SUFFIX}.0 CACHE FILEPATH "" FORCE)

  file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/libusb-temp)
  configure_file(${LibUSB_LIBRARY_ORIGINAL} ${LibUSB_SHARED_LIB} COPYONLY)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibUSB DEFAULT_MSG 
  LibUSB_INCLUDE_DIR LibUSB_IMPORT_LIB LibUSB_SHARED_LIB)

include(CreateImportTargetHelpers)
generate_import_target(LibUSB SHARED TARGET LibUSB::LibUSB)
