#include <hardware/structs/io_bank0.h>
#include <pico/stdlib.h>
#include <pico/stdio.h>
#include <hardware/gpio.h>
#include <pico/time.h>
#include <stdbool.h>
#include <stdio.h>

#define MAX_NUMBERS 3
#define POS_DATA_BITS 5

#define MOVING 2

#define POS_CLOCK 6
#define POS_DATA 10

#define GRIP 14

void position()
{
    char position_index[MAX_NUMBERS];

    int index;
    char input;

    do
    {
        input = (char) stdio_getchar();

        position_index[index] = input;

        index++;
    } while (index < MAX_NUMBERS && input != 10 && input != 13);

    if (index >= MAX_NUMBERS) index--;

    position_index[index] = 0;

    int number;
    int number_converted = sscanf(position_index, "%d", &number);

    if (number_converted <= 0 || number < 0 || number >= 32)
    {
        return;
    }

    gpio_put(POS_CLOCK, false);
    gpio_put(POS_DATA, false);

    bool data = false;
    bool clock = false;

    for (int i = 0; i < POS_DATA_BITS; i++)
    {
        data = ((number >> i) & 0x1) != 0;

        gpio_put(POS_DATA, data);

        clock = !clock;
        gpio_put(POS_CLOCK, clock);

        sleep_ms(100);
    }

    gpio_put(POS_CLOCK, false);
    gpio_put(POS_DATA, false);

    sleep_ms(500);

    bool moving = true;

    do {
        moving = gpio_get(MOVING);
    } while (moving);

    printf("d");
}

void grip()
{
    char input = (char) stdio_getchar();

    switch (input)
    {
        case '1':
            gpio_put(GRIP, true);
            break;
        case '0':
            gpio_put(GRIP, false);
            break;
        default:
            break;
    }
}

extern bool stdio_usb_init(void);

int main()
{
    stdio_init_all();
    stdio_usb_init();

    gpio_init(MOVING);
    gpio_set_dir(MOVING, false);
    gpio_set_pulls(MOVING, false, true);

    gpio_init(POS_CLOCK);
    gpio_init(POS_DATA);
    gpio_set_dir(POS_CLOCK, true);
    gpio_set_dir(POS_DATA, true);
    gpio_put(POS_CLOCK, false);
    gpio_put(POS_DATA, false);

    gpio_init(GRIP);
    gpio_set_dir(GRIP, true);
    gpio_set_pulls(GRIP, false, true);
    gpio_put(GRIP, false);

    while (1)
    {
        char input = (char) stdio_getchar();

        switch (input)
        {
            case 'p':
                position();
                break;
            case 'g':
                grip();
                break;
            default:
                break;
        }
    }
}
