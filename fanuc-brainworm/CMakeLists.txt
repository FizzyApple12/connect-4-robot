cmake_minimum_required(VERSION 3.13)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(PICO_SDK_PATH $ENV{PICO_SDK_PATH})

include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(fanuc_brainworm)

set(SKIP_PICO_STDIO_USB 1)

pico_sdk_init()

add_executable(fanuc_brainworm
    src/main.c
    src/tinyusb_task.c
    src/stdio_usb.c
    src/usb_descriptors.c
)

target_include_directories(fanuc_brainworm PUBLIC
    ${CMAKE_CURRENT_LIST_DIR}/src
    ${PICO_SDK_PATH}/src/rp2_common/pico_stdio_usb/include
)

target_link_libraries(fanuc_brainworm
    pico_stdlib
    pico_unique_id
    tinyusb_board
    tinyusb_device
)

pico_add_extra_outputs(fanuc_brainworm)

pico_enable_stdio_usb(fanuc_brainworm 1)
pico_enable_stdio_uart(fanuc_brainworm 0)
