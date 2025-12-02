#include "main.h"

#include "motion.h"
#include "serial.h"
#include <hardware/uart.h>
#include <pico/stdlib.h>
#include <pico/stdio.h>
#include <hardware/gpio.h>
#include <pico/time.h>
#include <pico/multicore.h>
#include <stdbool.h>
#include <stdio.h>

extern bool stdio_usb_init(void);

int main()
{
    stdio_init_all();
    stdio_usb_init();

    gpio_init(RED_BUTTON);
    gpio_init(YELLOW_BUTTON);
    gpio_init(GREEN_BUTTON);
    gpio_set_dir(RED_BUTTON, false);
    gpio_set_dir(YELLOW_BUTTON, false);
    gpio_set_dir(GREEN_BUTTON, false);
    gpio_set_pulls(RED_BUTTON, true, false);
    gpio_set_pulls(YELLOW_BUTTON, true, false);
    gpio_set_pulls(GREEN_BUTTON, true, false);

    gpio_init(RED_BUTTON_LED);
    gpio_init(YELLOW_BUTTON_LED);
    gpio_init(GREEN_BUTTON_LED);
    gpio_set_dir(RED_BUTTON_LED, true);
    gpio_set_dir(YELLOW_BUTTON_LED, true);
    gpio_set_dir(GREEN_BUTTON_LED, true);
    gpio_put(RED_BUTTON_LED, false);
    gpio_put(YELLOW_BUTTON_LED, false);
    gpio_put(GREEN_BUTTON_LED, false);

    gpio_set_function(MOTOR_UART_TX, UART_FUNCSEL_NUM(uart1, MOTOR_UART_TX));
    gpio_set_function(MOTOR_UART_RX, UART_FUNCSEL_NUM(uart1, MOTOR_UART_RX));

    uart_init(uart1, 115200);

    gpio_init(BOARD_RELEASE_MOTOR_EN);
    gpio_init(BOARD_RELEASE_MOTOR_STEP);
    gpio_init(BOARD_RELEASE_MOTOR_DIR);
    gpio_set_dir(BOARD_RELEASE_MOTOR_EN, true);
    gpio_set_dir(BOARD_RELEASE_MOTOR_STEP, true);
    gpio_set_dir(BOARD_RELEASE_MOTOR_DIR, true);
    gpio_put(BOARD_RELEASE_MOTOR_EN, false);
    gpio_put(BOARD_RELEASE_MOTOR_STEP, false);
    gpio_put(BOARD_RELEASE_MOTOR_DIR, false);

    gpio_init(ROBOT_DISPENSER_MOTOR_EN);
    gpio_init(ROBOT_DISPENSER_MOTOR_STEP);
    gpio_init(ROBOT_DISPENSER_MOTOR_DIR);
    gpio_set_dir(ROBOT_DISPENSER_MOTOR_EN, true);
    gpio_set_dir(ROBOT_DISPENSER_MOTOR_STEP, true);
    gpio_set_dir(ROBOT_DISPENSER_MOTOR_DIR, true);
    gpio_put(ROBOT_DISPENSER_MOTOR_EN, false);
    gpio_put(ROBOT_DISPENSER_MOTOR_STEP, false);
    gpio_put(ROBOT_DISPENSER_MOTOR_DIR, false);

    gpio_init(OPPONENT_DISPENSER_MOTOR_EN);
    gpio_init(OPPONENT_DISPENSER_MOTOR_STEP);
    gpio_init(OPPONENT_DISPENSER_MOTOR_DIR);
    gpio_set_dir(OPPONENT_DISPENSER_MOTOR_EN, true);
    gpio_set_dir(OPPONENT_DISPENSER_MOTOR_STEP, true);
    gpio_set_dir(OPPONENT_DISPENSER_MOTOR_DIR, true);
    gpio_put(OPPONENT_DISPENSER_MOTOR_EN, false);
    gpio_put(OPPONENT_DISPENSER_MOTOR_STEP, false);
    gpio_put(OPPONENT_DISPENSER_MOTOR_DIR, false);

    multicore_launch_core1(run_motion_task);

    run_serial_task();
}
