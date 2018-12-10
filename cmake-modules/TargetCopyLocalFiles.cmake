#.rst
# TargetCopyLocalFiles
# --------------------
# Created by Walter Gray.
# Defines functions helpful for copying local files, such as dynamic libraries or resource files
# to the working directory of a project, generally an executable.
#
# =====================
# ADD_LOCAL_FILE_COPY_COMMAND(<target>)
#  Adds the copy command which will reference the REQUIRED_LOCAL_FILES property on the target.
#  The copy command, while platform dependent, will iterate through the list of files, typically
#  DLLS, and will copy them to the appropriate location for the platform.
# ADD_LOCAL_FILES(<target> [DIRECTORY <directory] [FILES <file1> ...] | [DEBUG <file2> ..]  [RELEASE <file3> ...] )
#  Adds files to the list of files to be copied for a target.  TODO: Allow specification of a subdirectory.

#Helper functions for manipulating sets stored in properties.
function(add_to_prop_set scope target property item) #success_var is an optional extra argument
  get_property(_set ${scope} ${target} PROPERTY ${property})
  if(NOT _set)
    set(_set)
  endif()
  set(${ARGN} FALSE PARENT_SCOPE)

  list(FIND _set ${item} _index)
  if(${_index} EQUAL -1)
    set(${ARGN} TRUE PARENT_SCOPE)
    list(APPEND _set ${item})
    set_property(${scope} ${target} PROPERTY ${property} ${_set})
  endif()
endfunction()

function(is_in_prop_set scope target property item found_var)
  get_property(_set ${scope} ${target} PROPERTY ${property})
  set(${found_var} FALSE PARENT_SCOPE)

  list(FIND _set ${item} _index)
  if(${_index} GREATER -1)
    set(${found_var} TRUE PARENT_SCOPE)
  endif()
endfunction()

function(add_to_prop_list scope target property item)
  get_property(_set ${scope} ${target} PROPERTY ${property})
  if(NOT _set)
    set(_set)
  endif()

  list(APPEND _set ${item})
  set_property(${scope} ${target} PROPERTY ${property} ${_set})
endfunction()

function(remove_from_prop_set scope target property item)
  get_property(_set ${scope} ${target} PROPERTY ${property})
  if(NOT _set)
    return()
  endif()
  list(REMOVE_ITEM _set ${item})
  set_property(${scope} ${target} PROPERTY ${property} ${_set})
endfunction()

#Copy over the script files used by add_local_file_copy_command
if(WIN32)
  set(_copy_files_to_dirs_script copy_files_to_dirs.bat)
elseif(APPLE)
  set(_copy_files_to_dirs_script copy_files_to_dirs_apple.sh)
elseif(UNIX)
  set(_copy_files_to_dirs_script copy_files_to_dirs_linux.sh)
endif()

if(_copy_files_to_dirs_script)
  configure_file(${CMAKE_CURRENT_LIST_DIR}/${_copy_files_to_dirs_script}.in ${CMAKE_BINARY_DIR}/${_copy_files_to_dirs_script} @ONLY)
endif()

include(CMakeParseArguments)
function(add_local_file_copy_command target)
  get_target_property(_has_command ${target} LOCAL_FILE_COPY_COMMAND_DEFINED)
  if(_has_command)
    return()
  endif()
  set_property(TARGET ${target} PROPERTY LOCAL_FILE_COPY_COMMAND_DEFINED TRUE)

  set(_file_dir ${CMAKE_BINARY_DIR}/$<CONFIG>/${target})

  #Pre generate the storage directories for the copy manifests, some platforms
  #Don't like creating files in directories that don't exist yet.
  foreach(config ${CMAKE_CONFIGURATION_TYPES})
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/${config}/${target})
  endforeach()

  file(GENERATE OUTPUT ${_file_dir}/LocalFilesToCopy.txt CONTENT "$<JOIN:$<TARGET_PROPERTY:${target},REQUIRED_LOCAL_FILES>$<$<CONFIG:DEBUG>:$<SEMICOLON>$<TARGET_PROPERTY:${target},REQUIRED_LOCAL_FILES_DEBUG>>$<$<CONFIG:RELEASE>:$<SEMICOLON>$<TARGET_PROPERTY:${target},REQUIRED_LOCAL_FILES_RELEASE>>,\n>")
  file(GENERATE OUTPUT ${_file_dir}/LocalFilesDirectories.txt CONTENT "$<JOIN:$<TARGET_PROPERTY:${target},LOCAL_FILE_DIRS>$<$<CONFIG:DEBUG>:$<SEMICOLON>$<TARGET_PROPERTY:${target},LOCAL_FILE_DIRS_DEBUG>>$<$<CONFIG:RELEASE>:$<SEMICOLON>$<TARGET_PROPERTY:${target},LOCAL_FILE_DIRS_RELEASE>>,\n>")

  if(_copy_files_to_dirs_script)
    add_custom_command(TARGET ${target} POST_BUILD COMMAND
      ${CMAKE_BINARY_DIR}/${_copy_files_to_dirs_script} ${_file_dir}/LocalFilesToCopy.txt ${_file_dir}/LocalFilesDirectories.txt $<TARGET_FILE_DIR:${target}>)
  else()
    message(WARNING "Automatic handling of local files is unimplemented on this platform")
  endif()
endfunction()

function(add_local_files target)
  cmake_parse_arguments(add_local_files "" "DIRECTORY" "FILES;DEBUG;RELEASE" ${ARGN})

  add_local_file_copy_command(${target})

  if(NOT add_local_files_DIRECTORY)
    set(add_local_files_DIRECTORY .)
  endif()

  if(add_local_files_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "Invalid arguments passed to add_local_files: ${add_local_files_UNPARSED_ARGUMENTS}")
  endif()

  if(add_local_files_FILES AND (add_local_files_DEBUG OR add_local_files_RELEASE))
    message(FATAL_ERROR "FILES cannot be specified with DEBUG or RELEASE")
  endif()

  if(add_local_files_FILES)
    verbose_message("Adding required local files to ${target}: ${add_local_files_FILES}")
    foreach(_file ${add_local_files_FILES})
      add_to_prop_set(TARGET ${target} REQUIRED_LOCAL_FILES ${_file} _success)
      if(_success)
        add_to_prop_list(TARGET ${target} LOCAL_FILE_DIRS ${add_local_files_DIRECTORY})
      endif()
    endforeach()
  else()
    if(add_local_files_DEBUG)
      verbose_message("Adding required local debug files to ${target}: ${add_local_files_DEBUG}")
      foreach(_file ${add_local_files_DEBUG})
        add_to_prop_set(TARGET ${target} REQUIRED_LOCAL_FILES_DEBUG ${_file} _success)
        if(_success)
          add_to_prop_list(TARGET ${target} LOCAL_FILE_DIRS_DEBUG ${add_local_files_DIRECTORY})
        endif()
      endforeach()
    endif()
    if(add_local_files_RELEASE)
      verbose_message("Adding required local release filesto ${target}: ${add_local_files_RELEASE}")
      foreach(_file ${add_local_files_RELEASE})
        add_to_prop_set(TARGET ${target} REQUIRED_LOCAL_FILES_RELEASE ${_file} _success)
        if(_success)
          add_to_prop_list(TARGET ${target} LOCAL_FILE_DIRS_RELEASE ${add_local_files_DIRECTORY})
        endif()
      endforeach()
    endif()
  endif()
endfunction()
