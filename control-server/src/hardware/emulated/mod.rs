pub mod board_reader;
pub mod external_app;
pub mod piece_manipulator;
mod ui_elements;
pub mod user_interface;

use crate::hardware::emulated::external_app::ExternalApp;
use masonry::theme::default_property_set;
use std::sync::OnceLock;
use std::thread;
use tokio::sync::broadcast;
use xilem::view::{Axis, flex};
use xilem::winit::platform::wayland::EventLoopBuilderExtWayland;
use xilem::{EventLoop, WidgetView, WindowOptions, Xilem};

static UI_THREAD: OnceLock<ExternalUIInterface> = OnceLock::new();

#[derive(Debug, Clone)]
pub struct ExternalUIInterface {
    pub ui_message_sender: broadcast::Sender<UIMessage>,

    pub hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

#[derive(Debug, Clone)]
pub enum HardwareMessage {
    MoveTo(crate::PieceManipulatorPosition),
    Grab(bool),
    BoardRelease(bool),
    Dispense(crate::DispenseSide),

    #[cfg(feature = "emulated-ui")]
    SetButtonLights(crate::UserInterfaceButton, crate::UserInterfaceLightPattern),

    #[cfg(feature = "emulated-board")]
    CaptureBoard,
}

#[derive(Debug, Clone)]
pub enum UIMessage {
    #[cfg(feature = "emulated-ui")]
    ButtonPressed(crate::UserInterfaceButton),

    #[cfg(feature = "emulated-board")]
    CurrentBoard(crate::types::GameBoard),
}

#[derive(Debug, Clone)]
pub struct HardwareEmulatorState {
    ui_message_sender: broadcast::Sender<UIMessage>,

    hardware_message_sender: broadcast::Sender<HardwareMessage>,

    // Store button states directly in the main state
    #[cfg(feature = "emulated-ui")]
    red_button_on: bool,
    #[cfg(feature = "emulated-ui")]
    yellow_button_on: bool,
    #[cfg(feature = "emulated-ui")]
    green_button_on: bool,

    #[cfg(feature = "emulated-manipulator")]
    position: crate::PieceManipulatorPosition,
    #[cfg(feature = "emulated-manipulator")]
    grab: bool,
    #[cfg(feature = "emulated-manipulator")]
    release: bool,
    #[cfg(feature = "emulated-manipulator")]
    dispensed_robot: bool,
    #[cfg(feature = "emulated-manipulator")]
    dispensed_opponent: bool,

    #[cfg(feature = "emulated-board")]
    current_board: crate::types::GameBoard,
}

fn app_logic(data: &mut HardwareEmulatorState) -> impl WidgetView<HardwareEmulatorState> + use<> {
    flex(
        Axis::Vertical,
        (
            #[cfg(any(feature = "emulated-board", feature = "emulated-manipulator"))]
            flex(
                Axis::Horizontal,
                (
                    #[cfg(feature = "emulated-board")]
                    {
                        ui_elements::emulated_gameboard::emulated_gameboard(data)
                    },
                    #[cfg(feature = "emulated-manipulator")]
                    {
                        ui_elements::emulated_manipulator::emulated_manipulator(data)
                    },
                ),
            ),
            #[cfg(feature = "emulated-ui")]
            flex(
                Axis::Horizontal,
                (
                    ui_elements::emulated_button::emulated_button(
                        data,
                        crate::UserInterfaceButton::Green,
                    ),
                    ui_elements::emulated_button::emulated_button(
                        data,
                        crate::UserInterfaceButton::Yellow,
                    ),
                    ui_elements::emulated_button::emulated_button(
                        data,
                        crate::UserInterfaceButton::Red,
                    ),
                ),
            ),
        ),
    )
}

pub fn run_ui() -> ExternalUIInterface {
    let interface = UI_THREAD.get_or_init(|| {
        let (ui_message_sender, _) = broadcast::channel(16);
        let (hardware_message_sender, _) = broadcast::channel(16);

        let app_state = HardwareEmulatorState {
            ui_message_sender: ui_message_sender.clone(),

            hardware_message_sender: hardware_message_sender.clone(),

            #[cfg(feature = "emulated-ui")]
            red_button_on: false,
            #[cfg(feature = "emulated-ui")]
            yellow_button_on: false,
            #[cfg(feature = "emulated-ui")]
            green_button_on: false,

            #[cfg(feature = "emulated-manipulator")]
            position: crate::PieceManipulatorPosition::Home,
            #[cfg(feature = "emulated-manipulator")]
            grab: false,
            #[cfg(feature = "emulated-manipulator")]
            release: false,
            #[cfg(feature = "emulated-manipulator")]
            dispensed_robot: false,
            #[cfg(feature = "emulated-manipulator")]
            dispensed_opponent: false,

            #[cfg(feature = "emulated-board")]
            current_board: crate::types::GameBoard {
                state: [const { [const { crate::types::GamePiece::Blank }; 6] }; 7],
            },
        };

        let _ = thread::spawn(move || {
            let xilem = Xilem::new_simple(
                app_state,
                app_logic,
                WindowOptions::new("Hardware Emulator"),
            );

            let event_loop = EventLoop::with_user_event()
                .with_any_thread(true)
                .build()
                .unwrap();
            let proxy = event_loop.create_proxy();
            let (driver, windows) = xilem
                .into_driver_and_windows(move |event| proxy.send_event(event).map_err(|err| err.0));
            let masonry_state = masonry_winit::app::MasonryState::new(
                event_loop.create_proxy(),
                windows,
                default_property_set(),
            );

            let mut app = ExternalApp {
                masonry_state,
                app_driver: Box::new(driver),
            };
            event_loop.run_app(&mut app)
        });

        ExternalUIInterface {
            ui_message_sender,

            hardware_message_sender,
        }
    });

    interface.clone()
}
