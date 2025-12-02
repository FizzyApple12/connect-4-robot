#include "tusb.h"

static int32_t any(int32_t interface)
{
    if (interface >= 0 && interface < CFG_TUD_CDC)
    {
        if (tud_cdc_n_connected(interface))
        {
            return tud_cdc_n_available(interface);
        }
    }

    return 0;
}

static int32_t rxbyte(int32_t interface)
{
    if (any(interface))
    {
        uint8_t character;

        tud_cdc_n_read(interface, &character, 1);

        return character;
    }

    return -1;
}

static void txbyte(int32_t interface, int32_t byte_to_send)
{
    if (interface >= 0 && interface < CFG_TUD_CDC)
    {
        if (tud_cdc_n_connected(interface))
        {
            uint8_t character = byte_to_send & 0xFF;

            while (tud_cdc_n_write_available(interface) < 1)
            {
                tud_task();

                tud_cdc_n_write_flush(interface);
            }

            tud_cdc_n_write(interface, &character, 1);
            tud_cdc_n_write_flush(interface);
        }
    }
}

static void txtext(int32_t interface, const char *text_pointer)
{
    if (interface >= 0 && interface < CFG_TUD_CDC)
    {
        if (tud_cdc_n_connected(interface))
        {
            size_t text_pointer_length = strlen(text_pointer);

            while (text_pointer_length > 0)
            {
                size_t available = tud_cdc_n_write_available(interface);

                if (available == 0)
                {
                    tud_task();
                } else if (text_pointer_length > available)
                {
                    size_t sent = tud_cdc_n_write(interface, text_pointer, available);

                    text_pointer += sent;
                    text_pointer_length -= sent;
                } else
                {
                    tud_cdc_n_write(interface, text_pointer, text_pointer_length);

                    text_pointer_length = 0;
                }

                tud_cdc_n_write_flush(interface);
            }
        }
    }
}
