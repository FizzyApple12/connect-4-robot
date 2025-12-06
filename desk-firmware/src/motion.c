#include "motion.h"

#include "tmc2209.h"
#include "main.h"
#include <hardware/gpio.h>
#include <hardware/uart.h>
#include <pico/multicore.h>
#include <pico/time.h>
#include <stdint.h>

void run_motion_task()
{
    tmc_write(uart1, BOARD_RELEASE_MOTOR_ID, REGISTER_GCONF,      CONFIG_GCONF_EN_SPREADCYCLE | CONFIG_GCONF_PDN_DISABLE | CONFIG_GCONF_MSTEP_REG_SELECT | CONFIG_GCONF_MULTISTEP_FILT);
    tmc_write(uart1, BOARD_RELEASE_MOTOR_ID, REGISTER_SLAVECONF,  CONFIG_SLAVECONF(2));
    tmc_write(uart1, BOARD_RELEASE_MOTOR_ID, REGISTER_IHOLD_IRUN, CONFIG_IHOLD_IRUN_IHOLD(0) | CONFIG_IHOLD_IRUN_IRUN(31) | CONFIG_IHOLD_IRUN_IHOLDDELAY(1));
    tmc_write(uart1, BOARD_RELEASE_MOTOR_ID, REGISTER_CHOPCONF,   CONFIG_CHOPCONF_INTPOL | CONFIG_CHOPCONF_MRES(2) | CONFIG_CHOPCONF_HSTRT(5) | CONFIG_CHOPCONF_TOFF(3));
    // tmc_write(uart1, BOARD_RELEASE_MOTOR_ID, REGISTER_PWMCONF,    CONFIG_PWMCONF_PWM_LIM(12) | CONFIG_PWMCONF_PWM_REG(2) | CONFIG_PWMCONF_FREEWHEEL(1) | CONFIG_PWMCONF_AUTOSCALE | CONFIG_PWMCONF_PWM_GRAD(2) | CONFIG_PWMCONF_PWM_OFS(31));

    tmc_write(uart1, ROBOT_DISPENSER_MOTOR_ID, REGISTER_GCONF,      CONFIG_GCONF_EN_SPREADCYCLE | CONFIG_GCONF_PDN_DISABLE | CONFIG_GCONF_MSTEP_REG_SELECT | CONFIG_GCONF_MULTISTEP_FILT);
    tmc_write(uart1, ROBOT_DISPENSER_MOTOR_ID, REGISTER_SLAVECONF,  CONFIG_SLAVECONF(2));
    tmc_write(uart1, ROBOT_DISPENSER_MOTOR_ID, REGISTER_IHOLD_IRUN, CONFIG_IHOLD_IRUN_IHOLD(0) | CONFIG_IHOLD_IRUN_IRUN(31) | CONFIG_IHOLD_IRUN_IHOLDDELAY(1));
    tmc_write(uart1, ROBOT_DISPENSER_MOTOR_ID, REGISTER_CHOPCONF,   CONFIG_CHOPCONF_INTPOL | CONFIG_CHOPCONF_MRES(2) | CONFIG_CHOPCONF_HSTRT(5) | CONFIG_CHOPCONF_TOFF(3));
    // tmc_write(uart1, ROBOT_DISPENSER_MOTOR_ID, REGISTER_PWMCONF,    CONFIG_PWMCONF_PWM_LIM(12) | CONFIG_PWMCONF_PWM_REG(2) | CONFIG_PWMCONF_FREEWHEEL(1) | CONFIG_PWMCONF_AUTOSCALE | CONFIG_PWMCONF_PWM_GRAD(2) | CONFIG_PWMCONF_PWM_OFS(31));

    tmc_write(uart1, OPPONENT_DISPENSER_MOTOR_ID, REGISTER_GCONF,      CONFIG_GCONF_EN_SPREADCYCLE | CONFIG_GCONF_PDN_DISABLE | CONFIG_GCONF_MSTEP_REG_SELECT | CONFIG_GCONF_MULTISTEP_FILT);
    tmc_write(uart1, OPPONENT_DISPENSER_MOTOR_ID, REGISTER_SLAVECONF,  CONFIG_SLAVECONF(2));
    tmc_write(uart1, OPPONENT_DISPENSER_MOTOR_ID, REGISTER_IHOLD_IRUN, CONFIG_IHOLD_IRUN_IHOLD(0) | CONFIG_IHOLD_IRUN_IRUN(31) | CONFIG_IHOLD_IRUN_IHOLDDELAY(1));
    tmc_write(uart1, OPPONENT_DISPENSER_MOTOR_ID, REGISTER_CHOPCONF,   CONFIG_CHOPCONF_INTPOL | CONFIG_CHOPCONF_MRES(2) | CONFIG_CHOPCONF_HSTRT(5) | CONFIG_CHOPCONF_TOFF(3));
    // tmc_write(uart1, OPPONENT_DISPENSER_MOTOR_ID, REGISTER_PWMCONF,    CONFIG_PWMCONF_PWM_LIM(12) | CONFIG_PWMCONF_PWM_REG(2) | CONFIG_PWMCONF_FREEWHEEL(1) | CONFIG_PWMCONF_AUTOSCALE | CONFIG_PWMCONF_PWM_GRAD(2) | CONFIG_PWMCONF_PWM_OFS(31));

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

                sleep_ms(500);

                gpio_put(dir_pin, false);

                sleep_ms(1);

                for (int i = 0; i < DISPENSE_STEPS; i++) {
                    gpio_put(step_pin, true);

                    sleep_us(DISPENSE_STEP_FREQUENCY);

                    gpio_put(step_pin, false);

                    sleep_us(DISPENSE_STEP_FREQUENCY);
                }

                multicore_fifo_push_blocking(SERIAL_COMMAND_DISPENSE_DONE);
                multicore_fifo_push_blocking(dispense_motor_number);
                break;
            case MOTION_COMMAND_RELEASE:
                release_position = multicore_fifo_pop_blocking();

                if (release_position != released) {
                    released = release_position;

                    gpio_put(BOARD_RELEASE_MOTOR_DIR, released);

                    sleep_ms(1);

                    for (int i = 0; i < RELEASE_STEPS; i++) {
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
