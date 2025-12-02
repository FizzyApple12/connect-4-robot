#include "motion.h"

#include "main.h"
#include <hardware/gpio.h>
#include <hardware/uart.h>
#include <pico/multicore.h>
#include <pico/time.h>
#include <stdint.h>

void crc(uint8_t* data, uint8_t length)
{
    uint8_t* crc = data + (length - 1);
    uint8_t currentByte;

    *crc = 0;

    for (int i = 0; i < (length - 1); i++) {
        currentByte = data[i];

        for (int j = 0; j < 8; j++) {
            if ((*crc >> 7) ^ (currentByte & 0x01))
            {
                *crc = (*crc << 1) ^ 0x07;
            } else
            {
                *crc = (*crc << 1);
            }

            currentByte = currentByte >> 1;
        }
    }
}

void tmc_write(uint8_t tmc_id, uint8_t address, uint32_t data)
{
    uint8_t data_out[8] = {
        0xAA,
        tmc_id,
        address | 0b10000000,
        (uint8_t) ((data >> 24) & 0xFF),
        (uint8_t) ((data >> 16) & 0xFF),
        (uint8_t) ((data >> 8) & 0xFF),
        (uint8_t) (data & 0xFF),
        0
    };

    crc(data_out, 8);

    uart_write_blocking(uart1, data_out, 8);
}

uint32_t tmc_read(uint8_t tmc_id, uint8_t address)
{
    uint8_t data_out[4] = {
        0xAA,
        tmc_id,
        address & 0b01111111,
        0
    };

    crc(data_out, 4);

    uart_write_blocking(uart1, data_out, 4);

    uint8_t data_in[8];

    uart_read_blocking(uart1, data_in, 8);

    return (((uint32_t) data_in[3]) << 24)
        + (((uint32_t) data_in[4]) << 16)
        + (((uint32_t) data_in[5]) << 8)
        + ((uint32_t) data_in[6]);
}

void run_motion_task()
{
    tmc_write(BOARD_RELEASE_MOTOR_ID, 0x00, 0b00000000000000000000000011000010);
    tmc_write(BOARD_RELEASE_MOTOR_ID, 0x6C, 0b00010000000000100000000111001100);
    tmc_write(BOARD_RELEASE_MOTOR_ID, 0x70, 0b11111111000101000000000000100100);

    tmc_write(ROBOT_DISPENSER_MOTOR_ID, 0x00, 0b00000000000000000000000011000010);
    tmc_write(ROBOT_DISPENSER_MOTOR_ID, 0x6C, 0b00010000000000100000000111001100);
    tmc_write(ROBOT_DISPENSER_MOTOR_ID, 0x70, 0b11111111000101000000000000100100);

    tmc_write(OPPONENT_DISPENSER_MOTOR_ID, 0x00, 0b00000000000000000000000011000010);
    tmc_write(OPPONENT_DISPENSER_MOTOR_ID, 0x6C, 0b00010000000000100000000111001100);
    tmc_write(OPPONENT_DISPENSER_MOTOR_ID, 0x70, 0b11111111000101000000000000100100);

    bool released = false;

    while (1)
    {
        uint32_t fifo_command = multicore_fifo_pop_blocking();

        int dispense_motor_number = 0;
        int release_position = 0;

        switch (fifo_command)
        {
            case MOTION_COMMAND_DISPENSE:
                dispense_motor_number = multicore_fifo_pop_blocking();

                uint dir_pin = ROBOT_DISPENSER_MOTOR_DIR;
                uint step_pin = ROBOT_DISPENSER_MOTOR_STEP;

                if (dispense_motor_number == 1)
                {
                    dir_pin = OPPONENT_DISPENSER_MOTOR_DIR;
                    step_pin = OPPONENT_DISPENSER_MOTOR_STEP;
                }

                gpio_put(dir_pin, true);

                sleep_ms(1);

                for (int i = 0; i < DISPENSE_STEPS; i++) {
                    gpio_put(step_pin, true);

                    sleep_us(DISPENSE_STEP_FREQUENCY);

                    gpio_put(step_pin, false);

                    sleep_us(DISPENSE_STEP_FREQUENCY);
                }

                gpio_put(dir_pin, false);

                sleep_ms(1);

                for (int i = 0; i < DISPENSE_STEPS; i++) {
                    gpio_put(step_pin, true);

                    sleep_us(DISPENSE_STEP_FREQUENCY);

                    gpio_put(step_pin, false);

                    sleep_us(DISPENSE_STEP_FREQUENCY);
                }

                multicore_fifo_push_blocking(SERIAL_COMMAND_DISPENSE_DONE);
                break;
            case MOTION_COMMAND_RELEASE:
                release_position = multicore_fifo_pop_blocking();

                if (release_position != released) {
                    released = release_position;

                    gpio_put(BOARD_RELEASE_MOTOR_DIR, released);

                    sleep_ms(1);

                    for (int i = 0; i < DISPENSE_STEPS; i++) {
                        gpio_put(BOARD_RELEASE_MOTOR_STEP, true);

                        sleep_us(RELEASE_STEP_FREQUENCY);

                        gpio_put(BOARD_RELEASE_MOTOR_STEP, false);

                        sleep_us(RELEASE_STEP_FREQUENCY);
                    }
                }

                multicore_fifo_push_blocking(SERIAL_COMMAND_RELEASE_DONE);
                break;
            default:
                break;
        }
    }
}
