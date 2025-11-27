use crate::hardware::emulated::{ExternalUIInterface, HardwareMessage, run_ui};
use crate::hardware::{
    DispenseSide, PieceManipulator, PieceManipulatorError, PieceManipulatorPosition,
};
use std::time::Duration;

pub struct EmulatedPieceManipulator {
    ui_interface: ExternalUIInterface,
}

impl PieceManipulator for EmulatedPieceManipulator {
    async fn connect() -> Result<EmulatedPieceManipulator, PieceManipulatorError> {
        let ui_interface = run_ui();

        Ok(EmulatedPieceManipulator { ui_interface })
    }

    async fn move_to(
        &self,
        position: PieceManipulatorPosition,
    ) -> Result<(), PieceManipulatorError> {
        println!("emulated piece manipulator: move_to {:?}", position);

        let _ = self
            .ui_interface
            .hardware_message_sender
            .send(HardwareMessage::MoveTo(position));

        tokio::time::sleep(Duration::from_secs(1)).await;

        Ok(())
    }

    async fn grab(&self, grip: bool) -> Result<(), PieceManipulatorError> {
        println!("emulated piece manipulator: grab {:?}", grip);

        let _ = self
            .ui_interface
            .hardware_message_sender
            .send(HardwareMessage::Grab(grip));

        tokio::time::sleep(Duration::from_secs_f64(0.25)).await;

        Ok(())
    }

    async fn board_release(&self, release: bool) -> Result<(), PieceManipulatorError> {
        println!("emulated piece manipulator: board_release {:?}", release);

        let _ = self
            .ui_interface
            .hardware_message_sender
            .send(HardwareMessage::BoardRelease(release));

        tokio::time::sleep(Duration::from_secs(1)).await;

        Ok(())
    }

    async fn dispense(&self, side: DispenseSide) -> Result<(), PieceManipulatorError> {
        println!("emulated piece manipulator: dispense {:?}", side);

        let _ = self
            .ui_interface
            .hardware_message_sender
            .send(HardwareMessage::Dispense(side));

        tokio::time::sleep(Duration::from_secs(1)).await;

        Ok(())
    }
}
