use crate::hardware::{
    DispenseSide, PieceManipulator, PieceManipulatorError, PieceManipulatorPosition,
};

pub struct EmulatedPieceManipulator {}

impl PieceManipulator for EmulatedPieceManipulator {
    async fn connect() -> Result<EmulatedPieceManipulator, PieceManipulatorError> {
        Ok(EmulatedPieceManipulator {})
    }

    async fn move_to(
        &self,
        position: PieceManipulatorPosition,
    ) -> Result<(), PieceManipulatorError> {
        todo!("emulated piece manipulator: move_to {:?}", position)
    }

    async fn grab(&self, grip: bool) -> Result<(), PieceManipulatorError> {
        todo!("emulated piece manipulator: grab {:?}", grip)
    }

    async fn board_release(&self, release: bool) -> Result<(), PieceManipulatorError> {
        todo!("emulated piece manipulator: board_release {:?}", release)
    }

    async fn dispense(&self, side: DispenseSide) -> Result<(), PieceManipulatorError> {
        todo!("emulated piece manipulator: dispense {:?}", side)
    }
}
