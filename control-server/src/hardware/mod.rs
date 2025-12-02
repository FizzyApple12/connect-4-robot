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

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UserInterfaceButton {
    Red,
    Yellow,
    Green,
}

#[derive(Debug, Clone, PartialEq, Eq)]
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

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PieceManipulatorPosition {
    Home,
    Capture,
    ColumnPickUp(usize),
    ColumnDropOff(usize),
    SelfPickUp,
    SelfDropOff,
    OpponentDropOff,
    WinPose,
    LosePose,
}

impl PieceManipulatorPosition {
    pub fn get_robot_position_index(self) -> usize {
        match self {
            PieceManipulatorPosition::Home => 0,
            PieceManipulatorPosition::Capture => 1,
            PieceManipulatorPosition::SelfDropOff => 2,
            PieceManipulatorPosition::SelfPickUp => 3,
            PieceManipulatorPosition::OpponentDropOff => 4,
            PieceManipulatorPosition::ColumnDropOff(column) => 5 + column,
            PieceManipulatorPosition::ColumnPickUp(column) => 12 + column,
            PieceManipulatorPosition::WinPose => 19,
            PieceManipulatorPosition::LosePose => 20,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
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
pub enum BoardReaderError {
    #[error("No Board Reader Connected")]
    NoReaderConnected,
}

pub trait BoardReader {
    async fn connect() -> Result<Self, BoardReaderError>
    where
        Self: Sized;

    async fn capture(&self) -> Result<GameBoard, BoardReaderError>;
}
