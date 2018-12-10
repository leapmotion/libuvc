# A CMake module to provide a macro for converting sources
# into C strings
function(stringify target src_files outdir)
  set(inc_files "")
  add_dependencies(${target} Stringify)

  foreach(src_file ${src_files})
    get_filename_component(name_we ${src_file} NAME_WE)
    get_filename_component(dir ${src_file} DIRECTORY)
    get_filename_component(abs_src_file ${src_file} ABSOLUTE)

    # Need to pass the full path to Stringify because sometimes it's built as an
    # external project rather than an embedded target.  Stringify is always going
    # to be in the executable output directory for the target's current configuration
    add_custom_command(
      OUTPUT "${outdir}/${name_we}.gen.h" "${outdir}/${name_we}.gen.cpp"
      COMMAND ${CMAKE_COMMAND} -E make_directory ${outdir}
      COMMAND Stringify
      ARGS "${src_file}" "${outdir}/${name_we}.gen.h" "${outdir}/${name_we}.gen.cpp"
      DEPENDS ${abs_src_file}
      MAIN_DEPENDENCY ${abs_src_file}
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    )
    target_sources(${target} PRIVATE "${outdir}/${name_we}.gen.h")
    target_sources(${target} PRIVATE "${outdir}/${name_we}.gen.cpp")
  endforeach()
endfunction()
