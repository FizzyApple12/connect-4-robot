cmake_minimum_required(VERSION 3.13)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(PICO_SDK_PATH $ENV{PICO_SDK_PATH})

include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(desk_firmware)

set(SKIP_PICO_STDIO_USB 1)

pico_sdk_init()

add_executable(desk_firmware
    src/main.c
    src/serial.c
    src/motion.c
    src/tinyusb_task.c
    src/stdio_usb.c
    src/usb_descriptors.c
)

target_include_directories(desk_firmware PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/src
    ${PICO_SDK_PATH}/src/rp2_common/pico_stdio_usb/include
)

target_link_libraries(desk_firmware
    pico_stdlib
    pico_multicore
    pico_unique_id
    tinyusb_board
    tinyusb_device
)

pico_add_extra_outputs(desk_firmware)

pico_enable_stdio_usb(desk_firmware 1)
pico_enable_stdio_uart(desk_firmware 0)
