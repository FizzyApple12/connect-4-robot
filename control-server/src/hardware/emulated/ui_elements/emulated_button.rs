use masonry::properties::types::AsUnit;
use std::time::Duration;
use xilem::Color;
use xilem::WidgetView;
use xilem::style::Style;
use xilem::view::{button, label, sized_box, task_raw};
use xilem_core::fork;

use crate::hardware::emulated::{HardwareEmulatorState, HardwareMessage, UIMessage};
use crate::hardware::{UserInterfaceButton, UserInterfaceLightPattern};

const RED: Color = Color::from_rgb8(0xff, 0x00, 0x00);
const DARK_RED: Color = Color::from_rgb8(0x44, 0x00, 0x00);

const YELLOW: Color = Color::from_rgb8(0xff, 0xff, 0x00);
const DARK_YELLOW: Color = Color::from_rgb8(0x44, 0x44, 0x00);

const GREEN: Color = Color::from_rgb8(0x00, 0xff, 0x00);
const DARK_GREEN: Color = Color::from_rgb8(0x00, 0x44, 0x00);

// i really want to write this code in a more modular way but xilem doesn't have an
// equivalent to react's useState so self-contained state is basically impossible
pub fn emulated_button(
    data: &mut HardwareEmulatorState,
    button_type: UserInterfaceButton,
) -> impl WidgetView<HardwareEmulatorState> + use<> {
    let button_on = match button_type {
        UserInterfaceButton::Red => data.red_button_on,
        UserInterfaceButton::Yellow => data.yellow_button_on,
        UserInterfaceButton::Green => data.green_button_on,
    };

    let cloned_button_type = button_type.clone();
    let cloned_button_type_for_task = button_type.clone();

    let hardware_sender = data.hardware_message_sender.clone();

    fork(
        sized_box(
            button(label(""), move |data: &mut HardwareEmulatorState| {
                let _ = data
                    .ui_message_sender
                    .send(UIMessage::ButtonPressed(cloned_button_type.clone()));
            })
            .background_color(if button_on {
                match button_type {
                    UserInterfaceButton::Red => RED,
                    UserInterfaceButton::Yellow => YELLOW,
                    UserInterfaceButton::Green => GREEN,
                }
            } else {
                match button_type {
                    UserInterfaceButton::Red => DARK_RED,
                    UserInterfaceButton::Yellow => DARK_YELLOW,
                    UserInterfaceButton::Green => DARK_GREEN,
                }
            }),
        )
        .width(40.px())
        .height(40.px()),
        task_raw(
            move |proxy| {
                let mut cloned_hardware_receiver = hardware_sender.clone().subscribe();
                let cloned_button_type_for_task_2 = button_type.clone();

                async move {
                    let mut interval = tokio::time::interval(Duration::from_secs_f64(0.5));

                    let mut on = false;
                    let mut is_flashing = false;

                    loop {
                        tokio::select! {
                            _ = interval.tick() => {
                                on = !on;
                                if is_flashing {
                                    let _ = proxy.message(on);
                                }
                            }
                            message = cloned_hardware_receiver.recv() => {
                                if let Ok(HardwareMessage::SetButtonLights(user_interface_button, user_interface_light_pattern)) = message
                                    && user_interface_button == cloned_button_type_for_task_2
                                {
                                    match user_interface_light_pattern {
                                        UserInterfaceLightPattern::Off => {
                                            is_flashing = false;
                                            let _ = proxy.message(false);
                                        },
                                        UserInterfaceLightPattern::Blink => {
                                            let _ = proxy.message(on);
                                            is_flashing = true;
                                        },
                                        UserInterfaceLightPattern::On => {
                                            is_flashing = false;
                                            let _ = proxy.message(true);
                                        },
                                    }
                                }
                            }
                        };
                    }
                }
            },
            move |data: &mut HardwareEmulatorState, on: bool| match cloned_button_type_for_task
                .clone()
            {
                UserInterfaceButton::Red => data.red_button_on = on,
                UserInterfaceButton::Yellow => data.yellow_button_on = on,
                UserInterfaceButton::Green => data.green_button_on = on,
            },
        ),
    )
}
