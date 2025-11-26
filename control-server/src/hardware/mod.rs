pub mod generic;

#[cfg(any(
    feature = "emulated-ui",
    feature = "emulated-board",
    feature = "emulated-manipulator"
))]
mod emulated;
#[cfg(any(
    feature = "physical-ui",
    feature = "physical-board",
    feature = "physical-manipulator"
))]
mod physical;

use crate::types::GameBoard;
use thiserror::Error;

#[derive(Debug)]
pub enum UserInterfaceButton {
    Red,
    Yellow,
    Green,
}

#[derive(Debug)]
pub enum UserInterfaceLightPattern {
    Off,
    Blink,
    On,
}

#[derive(Error, Debug)]
pub enum UserInterfaceError {}

pub trait UserInterface {
    async fn connect() -> Result<Self, UserInterfaceError>
    where
        Self: Sized;

    async fn set_button_lights(
        &self,
        button: UserInterfaceButton,
        pattern: UserInterfaceLightPattern,
    ) -> Result<(), UserInterfaceError>;

    async fn wait_for_button(&self, button: UserInterfaceButton) -> Result<(), UserInterfaceError>;
}

#[derive(Debug)]
pub enum PieceManipulatorPosition {
    Home,
    Capture,
    ColumnPickUp(usize),
    ColumnDropOff(usize),
    SelfPickUp,
    SelfDropOff,
    OpponentDropOff,
}

#[derive(Debug)]
pub enum DispenseSide {
    Robot,
    Opponent,
}

#[derive(Error, Debug)]
pub enum PieceManipulatorError {}

pub trait PieceManipulator {
    async fn connect() -> Result<Self, PieceManipulatorError>
    where
        Self: Sized;

    async fn move_to(
        &self,
        position: PieceManipulatorPosition,
    ) -> Result<(), PieceManipulatorError>;

    async fn grab(&self, grip: bool) -> Result<(), PieceManipulatorError>;

    async fn board_release(&self, release: bool) -> Result<(), PieceManipulatorError>;

    async fn dispense(&self, side: DispenseSide) -> Result<(), PieceManipulatorError>;
}

#[derive(Error, Debug)]
pub enum BoardReaderError {}

pub trait BoardReader {
    async fn connect() -> Result<Self, BoardReaderError>
    where
        Self: Sized;

    async fn capture(&self) -> Result<GameBoard, BoardReaderError>;
}
