cmake_minimum_required(VERSION 3.0)

project(htreedeps)

set(BUILD_TESTS_DEFAULT OFF)

add_compile_options(-std=c++11)

add_subdirectory(extern/htreecpp/htree)
include_directories($<TARGET_PROPERTY:htree,INTERFACE_INCLUDE_DIRECTORIES>)

add_subdirectory(extern/rtmidi)
include_directories($<TARGET_PROPERTY:rtmidi,INTERFACE_INCLUDE_DIRECTORIES>)