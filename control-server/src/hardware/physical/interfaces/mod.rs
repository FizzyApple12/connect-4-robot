#[cfg(any(feature = "physical-ui", feature = "physical-manipulator"))]
pub mod desk_serial;
#[cfg(feature = "physical-manipulator")]
pub mod fanuc_brainworm_serial;
#[cfg(feature = "webserver")]
pub mod server;

#[derive(Debug, Clone)]
pub enum HardwareMessage {
    #[cfg(feature = "physical-manipulator")]
    MoveTo(crate::PieceManipulatorPosition),
    #[cfg(feature = "physical-manipulator")]
    Grab(bool),
    #[cfg(feature = "physical-manipulator")]
    BoardRelease(bool),
    #[cfg(feature = "physical-manipulator")]
    Dispense(crate::DispenseSide),

    #[cfg(feature = "physical-ui")]
    SetButtonLights(crate::UserInterfaceButton, crate::UserInterfaceLightPattern),

    #[cfg(feature = "physical-board")]
    CaptureBoard,
}
