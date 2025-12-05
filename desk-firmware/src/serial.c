#include "serial.h"

#include "main.h"
#include <hardware/gpio.h>
#include <pico/error.h>
#include <pico/stdio.h>
#include <pico/multicore.h>
#include <stdint.h>
#include <stdio.h>
#include <sys/_types.h>

volatile int red_button_timer_cutoff = 0;
volatile int yellow_button_timer_cutoff = 0;
volatile int green_button_timer_cutoff = 0;

volatile int flash_timer_progress = 0;

bool flashing_timer_callback(struct repeating_timer *timer)
{
    flash_timer_progress++;

    if (flash_timer_progress >= 2)
        flash_timer_progress = 0;

    gpio_put(RED_BUTTON_LED, flash_timer_progress < red_button_timer_cutoff);
    gpio_put(YELLOW_BUTTON_LED, flash_timer_progress < yellow_button_timer_cutoff);
    gpio_put(GREEN_BUTTON_LED, flash_timer_progress < green_button_timer_cutoff);

    return true;
}

void run_serial_task()
{
    int serial_input = PICO_ERROR_TIMEOUT;
    char serial_command = 0;

    uint32_t fifo_command = 0;
    uint32_t fifo_data = 0;

    char button_colour = 0;
    char button_status = 0;
    char dispense_motor_number = 0;
    char release_position = 0;

    bool red_button_pressed = false;
    bool red_button_pressed_last = false;
    bool yellow_button_pressed = false;
    bool yellow_button_pressed_last = false;
    bool green_button_pressed = false;
    bool green_button_pressed_last = false;

    struct repeating_timer flash_timer;

    add_repeating_timer_ms(500, flashing_timer_callback, NULL, &flash_timer);

    while (1)
    {
        serial_input = (int) stdio_getchar_timeout_us(0);

        if (serial_input != PICO_ERROR_TIMEOUT) {
            if (serial_command == 0)
            {
                switch ((char) serial_input) {
                    case 'b':
                        serial_command = 'b';
                        break;
                    case 'd':
                        serial_command = 'd';
                        break;
                    case 'r':
                        serial_command = 'r';
                        break;
                    default:
                        serial_command = 0;
                        break;
                }
            } else
            {
                switch (serial_command)
                {
                    case 'b':
                        if (button_colour == 0)
                        {
                            switch ((char) serial_input) {
                                case 'r':
                                    button_colour = 'r';
                                    break;
                                case 'y':
                                    button_colour = 'y';
                                    break;
                                case 'g':
                                    button_colour = 'g';
                                    break;
                                default:
                                    serial_command = 0;
                                    button_colour = 0;
                                    break;
                            }
                        } else
                        {
                            switch ((char) serial_input)
                            {
                                case '1':
                                    button_status = 1;
                                    break;
                                case '2':
                                    button_status = 2;
                                    break;
                                default:
                                    button_status = 0;
                                    break;
                            }

                            switch (button_colour)
                            {
                                case 'r':
                                    red_button_timer_cutoff = button_status;

                                    gpio_put(RED_BUTTON_LED, flash_timer_progress < red_button_timer_cutoff);
                                    break;
                                case 'y':
                                    yellow_button_timer_cutoff = button_status;

                                    gpio_put(YELLOW_BUTTON_LED, flash_timer_progress < yellow_button_timer_cutoff);
                                    break;
                                case 'g':
                                    green_button_timer_cutoff = button_status;

                                    gpio_put(GREEN_BUTTON_LED, flash_timer_progress < green_button_timer_cutoff);
                                    break;
                                default:
                                    break;
                            }

                            serial_command = 0;
                            button_colour = 0;
                        }
                        break;
                    case 'd':
                        dispense_motor_number = (char) serial_input;

                        multicore_fifo_push_blocking(MOTION_COMMAND_DISPENSE);
                        multicore_fifo_push_blocking(dispense_motor_number == '0' ? 0 : 1);

                        serial_command = 0;

                        break;
                    case 'r':
                        release_position = (char) serial_input;

                        multicore_fifo_push_blocking(MOTION_COMMAND_RELEASE);
                        multicore_fifo_push_blocking(release_position == '0' ? 0 : 1);

                        serial_command = 0;

                        break;
                    default:
                        serial_command = 0;
                        break;
                }
            }
        }

        if (multicore_fifo_pop_timeout_us(0, &fifo_command))
        {
            switch (fifo_command)
            {
                case SERIAL_COMMAND_DISPENSE_DONE:
                    fifo_data = multicore_fifo_pop_blocking();

                    if (fifo_data)
                    {
                        printf("d1");
                    } else
                    {
                        printf("d0");
                    }

                    stdio_flush();
                    break;
                case SERIAL_COMMAND_RELEASE_DONE:
                    printf("r");

                    stdio_flush();
                    break;
            }
        }

        red_button_pressed_last = red_button_pressed;
        red_button_pressed = gpio_get(RED_BUTTON);

        yellow_button_pressed_last = yellow_button_pressed;
        yellow_button_pressed = gpio_get(YELLOW_BUTTON);

        green_button_pressed_last = green_button_pressed;
        green_button_pressed = gpio_get(GREEN_BUTTON);

        if (red_button_pressed != red_button_pressed_last && red_button_pressed)
        {
            printf("br");

            stdio_flush();
        }

        if (yellow_button_pressed != yellow_button_pressed_last && !yellow_button_pressed)
        {
            printf("by");

            stdio_flush();
        }

        if (green_button_pressed != green_button_pressed_last && !green_button_pressed)
        {
            printf("bg");

            stdio_flush();
        }
    }
}
