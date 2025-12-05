use crate::hardware::{
    DispenseSide, PieceManipulator, PieceManipulatorError, PieceManipulatorPosition,
    physical::interfaces::{
        HardwareMessage,
        desk_serial::{DeskSerialInterface, DeskSerialMessage, connect_desk_serial},
        fanuc_brainworm_serial::{
            BrainwormSerialInterface, BrainwormSerialMessage, connect_brainworm_serial,
        },
    },
};
use std::time::Duration;

pub struct PhysicalPieceManipulator {
    brainworm_serial_interface: BrainwormSerialInterface,

    desk_serial_interface: DeskSerialInterface,
}

impl PieceManipulator for PhysicalPieceManipulator {
    async fn connect() -> Result<PhysicalPieceManipulator, PieceManipulatorError> {
        let brainworm_serial_interface = connect_brainworm_serial().await;
        let desk_serial_interface = connect_desk_serial().await;

        Ok(PhysicalPieceManipulator {
            brainworm_serial_interface,

            desk_serial_interface,
        })
    }

    async fn move_to(
        &self,
        position: PieceManipulatorPosition,
    ) -> Result<(), PieceManipulatorError> {
        println!("physical piece manipulator: move_to {:?}", position);

        let serial_message_sender = self
            .brainworm_serial_interface
            .serial_message_sender
            .clone();

        let mut serial_message_receiver = serial_message_sender.subscribe();

        let _ = self
            .brainworm_serial_interface
            .hardware_message_sender
            .send(HardwareMessage::MoveTo(position));

        loop {
            if let Ok(BrainwormSerialMessage::MoveDone) = serial_message_receiver.recv().await {
                break;
            }
        }

        Ok(())
    }

    async fn grab(&self, grip: bool) -> Result<(), PieceManipulatorError> {
        println!("physical piece manipulator: grab {:?}", grip);

        let _ = self
            .brainworm_serial_interface
            .hardware_message_sender
            .send(HardwareMessage::Grab(grip));

        if grip {
            tokio::time::sleep(Duration::from_secs_f64(0.25)).await;
        }

        Ok(())
    }

    async fn board_release(&self, release: bool) -> Result<(), PieceManipulatorError> {
        println!("physical piece manipulator: board_release {:?}", release);

        let serial_message_sender = self.desk_serial_interface.serial_message_sender.clone();

        let mut serial_message_receiver = serial_message_sender.subscribe();

        let _ = self
            .desk_serial_interface
            .hardware_message_sender
            .send(HardwareMessage::BoardRelease(release));

        loop {
            if let Ok(DeskSerialMessage::BoardReleaseDone) = serial_message_receiver.recv().await {
                break;
            }
        }

        Ok(())
    }

    async fn dispense(&self, side: DispenseSide) -> Result<(), PieceManipulatorError> {
        println!("physical piece manipulator: dispense {:?}", side);

        let serial_message_sender = self.desk_serial_interface.serial_message_sender.clone();

        let mut serial_message_receiver = serial_message_sender.subscribe();

        let _ = self
            .desk_serial_interface
            .hardware_message_sender
            .send(HardwareMessage::Dispense(side.clone()));

        loop {
            if let Ok(DeskSerialMessage::DispenseDone(complete_side)) =
                serial_message_receiver.recv().await
                && complete_side == side
            {
                break;
            }
        }

        Ok(())
    }
}
