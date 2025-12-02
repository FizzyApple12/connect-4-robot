use std::sync::OnceLock;
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    sync::broadcast,
};
use tokio_serial::{SerialPortBuilderExt, SerialPortType, available_ports};

use crate::hardware::physical::interfaces::HardwareMessage;

const BRAINWORM_VID: u16 = 0xF155;
const BRAINWORM_PID: u16 = 0xFB01;

static SERVER_THREAD: OnceLock<BrainwormSerialInterface> = OnceLock::new();

#[derive(Debug, Clone)]
pub struct BrainwormSerialInterface {
    pub serial_message_sender: broadcast::Sender<BrainwormSerialMessage>,

    pub hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

#[derive(Debug, Clone)]
pub enum BrainwormSerialMessage {
    MoveDone,
}

#[derive(Debug, Clone)]
pub struct BrainwormSerialState {
    serial_message_sender: broadcast::Sender<BrainwormSerialMessage>,

    hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

pub fn connect_brainworm_serial() -> BrainwormSerialInterface {
    let interface = SERVER_THREAD.get_or_init(|| {
        let (server_message_sender, _) = broadcast::channel(16);
        let (hardware_message_sender, _) = broadcast::channel(16);

        let app_state = BrainwormSerialState {
            serial_message_sender: server_message_sender.clone(),

            hardware_message_sender: hardware_message_sender.clone(),
        };

        let all_serial_ports = available_ports().expect("Failed to get system serial port list");

        let brainworm_serial_port_info = all_serial_ports
            .into_iter()
            .find(|port| match port.port_type {
                SerialPortType::UsbPort(ref usb_port_info) => {
                    usb_port_info.vid == BRAINWORM_VID && usb_port_info.pid == BRAINWORM_PID
                }
                _ => false,
            })
            .expect("Failed to find brainworm serial port");

        let mut brainworm_serial_port =
            tokio_serial::new(brainworm_serial_port_info.port_name, 115200)
                .dtr_on_open(true)
                .open_native_async()
                .expect("Failed to open brainworm serial port");

        tokio::task::spawn(async move {
            let BrainwormSerialState {
                serial_message_sender,
                hardware_message_sender,
            } = app_state;

            let hardware_message_sender = hardware_message_sender.clone();

            let mut hardware_message_receiver = hardware_message_sender.subscribe();

            loop {
                tokio::select! {
                    read_result = brainworm_serial_port.read_u8() => {
                        if let Ok(b'd') = read_result {
                            println!("brainworm serial: last move reported as complete");

                            let _ = serial_message_sender.send(BrainwormSerialMessage::MoveDone);
                        }
                    }
                    hardware_message = hardware_message_receiver.recv() => {
                        match hardware_message {
                            Ok(HardwareMessage::MoveTo(position)) => {
                                let position_index = position.get_robot_position_index();

                                println!("brainworm serial: sending position command 'p{position_index}'");

                                let _ = brainworm_serial_port.write(format!("p{position_index}\n").as_bytes()).await;
                            }
                            Ok(HardwareMessage::Grab(grip)) => {
                                println!("brainworm serial: sending grip command 'g{}'", if grip {1} else {0});

                                let _ = brainworm_serial_port.write(format!("g{}", if grip {1} else {0}).as_bytes()).await;
                            }
                            _ => {}
                        }
                    }
                }
            }
        });

        BrainwormSerialInterface {
            serial_message_sender: server_message_sender,

            hardware_message_sender,
        }
    });

    interface.clone()
}
