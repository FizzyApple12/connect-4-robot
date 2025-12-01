#[cfg(feature = "physical-board")]
use crate::hardware::physical::board_reader::PhysicalBoardReader;
use crate::{
    hardware::{
        BoardReader, BoardReaderError, DispenseSide, PieceManipulator, PieceManipulatorError,
        PieceManipulatorPosition, UserInterface, UserInterfaceButton, UserInterfaceError,
        UserInterfaceLightPattern,
    },
    types::GameBoard,
};

#[cfg(feature = "emulated-board")]
use crate::hardware::emulated::board_reader::EmulatedBoardReader;
#[cfg(feature = "emulated-manipulator")]
use crate::hardware::emulated::piece_manipulator::EmulatedPieceManipulator;
#[cfg(feature = "emulated-ui")]
use crate::hardware::emulated::user_interface::EmulatedUserInterface;

pub struct GenericUserInterface {
    #[cfg(feature = "emulated-ui")]
    emulated: EmulatedUserInterface,
}

impl UserInterface for GenericUserInterface {
    async fn connect() -> Result<GenericUserInterface, UserInterfaceError> {
        Ok(GenericUserInterface {
            #[cfg(feature = "emulated-ui")]
            emulated: EmulatedUserInterface::connect().await?,
        })
    }

    async fn set_button_lights(
        &self,
        button: UserInterfaceButton,
        pattern: UserInterfaceLightPattern,
    ) -> Result<(), UserInterfaceError> {
        #[cfg(feature = "emulated-ui")]
        return self.emulated.set_button_lights(button, pattern).await;
        #[cfg(feature = "physical-ui")]
        todo!(
            "generic user interface: set_button_lights {:?} {:?}",
            button,
            pattern
        )
    }

    async fn wait_for_button(&self, button: UserInterfaceButton) -> Result<(), UserInterfaceError> {
        #[cfg(feature = "emulated-ui")]
        return self.emulated.wait_for_button(button).await;
        #[cfg(feature = "physical-ui")]
        todo!("generic user interface: wait_for_button {:?}", button)
    }
}

pub struct GenericPieceManipulator {
    #[cfg(feature = "emulated-manipulator")]
    emulated: EmulatedPieceManipulator,
}

impl PieceManipulator for GenericPieceManipulator {
    async fn connect() -> Result<GenericPieceManipulator, PieceManipulatorError> {
        Ok(GenericPieceManipulator {
            #[cfg(feature = "emulated-manipulator")]
            emulated: EmulatedPieceManipulator::connect().await?,
        })
    }

    async fn move_to(
        &self,
        position: PieceManipulatorPosition,
    ) -> Result<(), PieceManipulatorError> {
        #[cfg(feature = "emulated-manipulator")]
        return self.emulated.move_to(position).await;
        #[cfg(feature = "physical-manipulator")]
        todo!("generic piece manipulator: move_to {:?}", position)
    }

    async fn grab(&self, grip: bool) -> Result<(), PieceManipulatorError> {
        #[cfg(feature = "emulated-manipulator")]
        return self.emulated.grab(grip).await;
        #[cfg(feature = "physical-manipulator")]
        todo!("generic piece manipulator: grab {:?}", grip)
    }

    async fn board_release(&self, release: bool) -> Result<(), PieceManipulatorError> {
        #[cfg(feature = "emulated-manipulator")]
        return self.emulated.board_release(release).await;
        #[cfg(feature = "physical-manipulator")]
        todo!("generic piece manipulator: board_release {:?}", release)
    }

    async fn dispense(&self, side: DispenseSide) -> Result<(), PieceManipulatorError> {
        #[cfg(feature = "emulated-manipulator")]
        return self.emulated.dispense(side).await;
        #[cfg(feature = "physical-manipulator")]
        todo!("generic piece manipulator: dispense {:?}", side)
    }
}

pub struct GenericBoardReader {
    #[cfg(feature = "emulated-board")]
    emulated: EmulatedBoardReader,
    #[cfg(feature = "physical-board")]
    physical: PhysicalBoardReader,
}

impl BoardReader for GenericBoardReader {
    async fn connect() -> Result<GenericBoardReader, BoardReaderError> {
        Ok(GenericBoardReader {
            #[cfg(feature = "emulated-board")]
            emulated: EmulatedBoardReader::connect().await?,
            #[cfg(feature = "physical-board")]
            physical: PhysicalBoardReader::connect().await?,
        })
    }

    async fn capture(&self) -> Result<GameBoard, BoardReaderError> {
        #[cfg(feature = "emulated-board")]
        return self.emulated.capture().await;
        #[cfg(feature = "physical-board")]
        return self.physical.capture().await;
    }
}
