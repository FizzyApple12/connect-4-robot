#ifndef _TUSB_CONFIG_H_
#define _TUSB_CONFIG_H_

#define CFG_TUSB_RHPORT0_MODE (OPT_MODE_DEVICE)

#define CFG_TUD_EP_MAX (16)

#define CFG_TUD_CDC_EP_BUFSIZE (256)
#define CFG_TUD_CDC_RX_BUFSIZE (256)
#define CFG_TUD_CDC_TX_BUFSIZE (256)

#define CFG_TUD_CDC       (1)
#define CFG_TUD_WEB       (0)
#define CFG_TUD_NET       (0)
#define CFG_TUD_ECM_RNDIS (0)
#define CFG_TUD_MSC       (0)
#define CFG_TUD_HID       (0)
#define CFG_TUD_MIDI      (0)
#define CFG_TUD_AUDIO     (0)
#define CFG_TUD_BTH       (0)
#define CFG_TUD_TMC       (0)
#define CFG_TUD_GUD       (0)
#define CFG_TUD_VENDOR    (0)

#endif
