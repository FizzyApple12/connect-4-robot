cmake_minimum_required(VERSION 3.13)

include(pico_sdk_import.cmake)

project(my_project)

pico_sdk_init()

add_executable(desk_firmware
    src/main.c
)

target_link_libraries(desk_firmware pico_stdlib)

pico_add_extra_outputs(desk_firmware)
