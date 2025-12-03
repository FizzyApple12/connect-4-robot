#ifndef TMC_2209_H
#define TMC_2209_H

#include <hardware/gpio.h>
#include <hardware/uart.h>
#include <stdint.h>

#define CONFIG_NULL 0b00000000000000000000000000000000

#define REGISTER_GCONF 0x00
#define CONFIG_GCONF_ISCALE_ANALOG    0b00000000000000000000000000000001
#define CONFIG_GCONF_INTERNAL_RSENSE  0b00000000000000000000000000000010
#define CONFIG_GCONF_EN_SPREADCYCLE   0b00000000000000000000000000000100
#define CONFIG_GCONF_SHAFT            0b00000000000000000000000000001000
#define CONFIG_GCONF_INDEX_OTPW       0b00000000000000000000000000010000
#define CONFIG_GCONF_INDEX_STEP       0b00000000000000000000000000100000
#define CONFIG_GCONF_PDN_DISABLE      0b00000000000000000000000001000000
#define CONFIG_GCONF_MSTEP_REG_SELECT 0b00000000000000000000000010000000
#define CONFIG_GCONF_MULTISTEP_FILT   0b00000000000000000000000100000000

#define REGISTER_SLAVECONF 0x03
#define CONFIG_SLAVECONF(delay) ((0b00000000000000000000000000001111 & ((uint32_t) delay)) << 8)

#define REGISTER_IHOLD_IRUN 0x10
#define CONFIG_IHOLD_IRUN_IHOLD(standstill_current) (0b00000000000000000000000000011111 & ((uint32_t) standstill_current))
#define CONFIG_IHOLD_IRUN_IRUN(run_current)         ((0b00000000000000000000000000011111 & ((uint32_t) run_current)) << 8)
#define CONFIG_IHOLD_IRUN_IHOLDDELAY(hold_delay)    ((0b00000000000000000000000000001111 & ((uint32_t) hold_delay)) << 16)

#define REGISTER_CHOPCONF 0x6C
#define CONFIG_CHOPCONF_DISS2VSS                0b10000000000000000000000000000000
#define CONFIG_CHOPCONF_DISS2G                  0b01000000000000000000000000000000
#define CONFIG_CHOPCONF_DEDGE                   0b00100000000000000000000000000000
#define CONFIG_CHOPCONF_INTPOL                  0b00010000000000000000000000000000
#define CONFIG_CHOPCONF_MRES(resolution)        ((0b00000000000000000000000000001111 & ((uint32_t) resolution)) << 24)
#define CONFIG_CHOPCONF_VSENSE                  0b00000000000000100000000000000000
#define CONFIG_CHOPCONF_TBL(blank_time)         ((0b00000000000000000000000000000011 & ((uint32_t) blank_time)) << 15)
#define CONFIG_CHOPCONF_HEND(hysteresis_end)    ((0b00000000000000000000000000001111 & ((uint32_t) hysteresis_end)) << 7)
#define CONFIG_CHOPCONF_HSTRT(hysteresis_start) ((0b00000000000000000000000000000111 & ((uint32_t) hysteresis_start)) << 4)
#define CONFIG_CHOPCONF_TOFF(driver_decay)      (0b00000000000000000000000000001111 & ((uint32_t) driver_decay))

#define REGISTER_PWMCONF 0x70
#define CONFIG_PWMCONF_PWM_LIM(limit)           ((0b00000000000000000000000000001111 & ((uint32_t) limit)) << 28)
#define CONFIG_PWMCONF_PWM_REG(gradient)        ((0b00000000000000000000000000001111 & ((uint32_t) gradient)) << 24)
#define CONFIG_PWMCONF_FREEWHEEL(mode)          ((0b00000000000000000000000000000011 & ((uint32_t) mode)) << 20)
#define CONFIG_PWMCONF_AUTOGRAD                 0b00000000000010000000000000000000
#define CONFIG_PWMCONF_AUTOSCALE                0b00000000000001000000000000000000
#define CONFIG_PWMCONF_PWM_FREQUENCY(frequency) ((0b00000000000000000000000000000011 & ((uint32_t) frequency)) << 16)
#define CONFIG_PWMCONF_PWM_GRAD(gradient)       ((0b00000000000000000000000011111111 & ((uint32_t) gradient)) << 8)
#define CONFIG_PWMCONF_PWM_OFS(amplitude)       (0b00000000000000000000000011111111 & ((uint32_t) amplitude))

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

void tmc_write(uart_inst_t * uart, uint8_t tmc_id, uint8_t address, uint32_t data)
{
    uint8_t data_out[8] = {
        0x55,
        tmc_id,
        address | 0b10000000,
        (uint8_t) ((data >> 24) & 0xFF),
        (uint8_t) ((data >> 16) & 0xFF),
        (uint8_t) ((data >> 8) & 0xFF),
        (uint8_t) (data & 0xFF),
        0
    };

    crc(data_out, 8);

    uart_write_blocking(uart, data_out, 8);
}

uint32_t tmc_read(uart_inst_t * uart, uint8_t tmc_id, uint8_t address)
{
    uint8_t data_out[4] = {
        0x55,
        tmc_id,
        address & 0b01111111,
        0
    };

    crc(data_out, 4);

    uart_write_blocking(uart, data_out, 4);

    uint8_t data_in[8];

    uart_read_blocking(uart, data_in, 8);

    return (((uint32_t) data_in[3]) << 24)
        + (((uint32_t) data_in[4]) << 16)
        + (((uint32_t) data_in[5]) << 8)
        + ((uint32_t) data_in[6]);
}

#endif
