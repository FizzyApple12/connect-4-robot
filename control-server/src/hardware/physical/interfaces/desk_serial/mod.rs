use std::sync::OnceLock;
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    sync::broadcast,
};
use tokio_serial::{SerialPortBuilderExt, SerialPortType, available_ports};

use crate::hardware::physical::interfaces::HardwareMessage;

const DESK_VID: u16 = 0xF155;
const DESK_PID: u16 = 0xCD01;

static DESK_SERIAL_THREAD: OnceLock<DeskSerialInterface> = OnceLock::new();

#[derive(Debug, Clone)]
pub struct DeskSerialInterface {
    pub serial_message_sender: broadcast::Sender<DeskSerialMessage>,

    pub hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

#[derive(Debug, Clone)]
pub enum DeskSerialMessage {
    #[cfg(feature = "physical-manipulator")]
    BoardReleaseDone,
    #[cfg(feature = "physical-manipulator")]
    DispenseDone(crate::hardware::DispenseSide),

    #[cfg(feature = "physical-ui")]
    ButtonPressed(crate::hardware::UserInterfaceButton),
}

#[derive(Debug, Clone)]
pub struct DeskSerialState {
    serial_message_sender: broadcast::Sender<DeskSerialMessage>,

    hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

pub async fn connect_desk_serial() -> DeskSerialInterface {
    let interface = DESK_SERIAL_THREAD.get_or_init(|| {
        let (serial_message_sender, _) = broadcast::channel(16);
        let (hardware_message_sender, _) = broadcast::channel(16);

        let app_state = DeskSerialState {
            serial_message_sender: serial_message_sender.clone(),

            hardware_message_sender: hardware_message_sender.clone(),
        };

        let all_serial_ports = available_ports().expect("Failed to get system serial port list");

        let desk_serial_port_info = all_serial_ports
            .into_iter()
            .find(|port| match port.port_type {
                SerialPortType::UsbPort(ref usb_port_info) => {
                    usb_port_info.vid == DESK_VID && usb_port_info.pid == DESK_PID
                }
                _ => false,
            })
            .expect("Failed to find desk serial port");

        let mut desk_serial_port =
            tokio_serial::new(desk_serial_port_info.port_name, 115200)
                .dtr_on_open(true)
                .open_native_async()
                .expect("Failed to open desk serial port");

        let DeskSerialState {
            serial_message_sender: task_serial_message_sender,
            hardware_message_sender: task_hardware_message_sender,
        } = app_state;

        let mut task_hardware_message_receiver = task_hardware_message_sender.subscribe();

        tokio::task::spawn(async move {
            loop {
                tokio::select! {
                    read_result = desk_serial_port.read_u8() => {
                        match read_result {
                            #[cfg(feature = "physical-manipulator")]
                            Ok(b'd') => {
                                println!("desk serial: dispense signal...");

                                let side = desk_serial_port.read_u8().await;

                                match side {
                                    Ok(b'1') => {
                                        println!("desk serial: last robot dispense reported as complete");

                                        let _ = task_serial_message_sender.send(DeskSerialMessage::DispenseDone(crate::hardware::DispenseSide::Opponent));
                                    }
                                    Ok(b'0') => {
                                        println!("desk serial: last opponent reported as complete");

                                        let _ = task_serial_message_sender.send(DeskSerialMessage::DispenseDone(crate::hardware::DispenseSide::Robot));
                                    }
                                    _ => {}
                                }
                            }
                            #[cfg(feature = "physical-manipulator")]
                            Ok(b'r') => {
                                println!("desk serial: last release move reported as complete");

                                let _ = task_serial_message_sender.send(DeskSerialMessage::BoardReleaseDone);
                            }
                            #[cfg(feature = "physical-ui")]
                            Ok(b'b') => {
                                println!("desk serial: button signal...");

                                let button = desk_serial_port.read_u8().await;

                                match button {
                                    Ok(b'r') => {
                                        println!("desk serial: red button pressed");

                                        let _ = task_serial_message_sender.send(DeskSerialMessage::ButtonPressed(crate::hardware::UserInterfaceButton::Red));
                                    }
                                    Ok(b'y') => {
                                        println!("desk serial: yellow button pressed");

                                        let _ = task_serial_message_sender.send(DeskSerialMessage::ButtonPressed(crate::hardware::UserInterfaceButton::Yellow));
                                    }
                                    Ok(b'g') => {
                                        println!("desk serial: green button pressed");

                                        let _ = task_serial_message_sender.send(DeskSerialMessage::ButtonPressed(crate::hardware::UserInterfaceButton::Green));
                                    }
                                    _ => {}
                                }
                            }
                            _ => {}
                        }
                    }
                    hardware_message = task_hardware_message_receiver.recv() => {
                        match hardware_message {
                            #[cfg(feature = "physical-manipulator")]
                            Ok(HardwareMessage::BoardRelease(release)) => {
                                let open = if release {1} else {0};

                                println!("desk serial: sending board release command 'r{open}'");

                                let _ = desk_serial_port.write(format!("r{open}").as_bytes()).await;
                            }
                            #[cfg(feature = "physical-manipulator")]
                            Ok(HardwareMessage::Dispense(side)) => {
                                let index = if let crate::DispenseSide::Robot = side {0} else {1};

                                println!("desk serial: sending dispense command 'd{index}'");

                                let _ = desk_serial_port.write(format!("d{index}").as_bytes()).await;
                            }
                            #[cfg(feature = "physical-ui")]
                            Ok(HardwareMessage::SetButtonLights(button, lights)) => {
                                let button = match button {
                                    crate::hardware::UserInterfaceButton::Red => 'r',
                                    crate::hardware::UserInterfaceButton::Yellow => 'y',
                                    crate::hardware::UserInterfaceButton::Green => 'g',
                                };
                                let lights = match lights {
                                    crate::hardware::UserInterfaceLightPattern::Off => 0,
                                    crate::hardware::UserInterfaceLightPattern::Blink => 1,
                                    crate::hardware::UserInterfaceLightPattern::On => 2,
                                };

                                println!("desk serial: sending button lights command 'b{button}{lights}'");

                                let _ = desk_serial_port.write(format!("b{button}{lights}").as_bytes()).await;
                            }
                            _ => {}
                        }
                    }
                }
            }
        });

        DeskSerialInterface {
            serial_message_sender,

            hardware_message_sender,
        }
    });

    // give the task a chance to start up
    tokio::task::yield_now().await;

    interface.clone()
}
