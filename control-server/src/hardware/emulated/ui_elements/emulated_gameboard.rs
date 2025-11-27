use masonry::properties::types::AsUnit;
use xilem::Color;
use xilem::WidgetView;
use xilem::style::Style;
use xilem::view::{Axis, button, flex, label, sized_box, task_raw};
use xilem_core::fork;

use crate::hardware::emulated::{HardwareEmulatorState, HardwareMessage, UIMessage};
use crate::types::GamePiece;

const RED: Color = Color::from_rgb8(0xff, 0x00, 0x00);
const YELLOW: Color = Color::from_rgb8(0xff, 0xff, 0x00);
const BLANK: Color = Color::from_rgb8(0x44, 0x44, 0x44);

// i really want to write this code in a more modular way but xilem doesn't have an
// equivalent to react's useState so self-contained state is basically impossible
pub fn emulated_gameboard(
    data: &mut HardwareEmulatorState,
) -> impl WidgetView<HardwareEmulatorState> + use<> {
    let hardware_sender = data.hardware_message_sender.clone();

    fork(
        flex(
            Axis::Horizontal,
            data.current_board
                .state
                .iter()
                .enumerate()
                .map(|(column_index, column)| {
                    flex(
                        Axis::Vertical,
                        column
                            .iter()
                            .enumerate()
                            .map(move |(row_index, piece)| {
                                sized_box(
                                    button(label(""), move |data: &mut HardwareEmulatorState| {
                                        data.current_board.state[column_index][row_index] =
                                            match data.current_board.state[column_index][row_index]
                                            {
                                                GamePiece::Red => GamePiece::Yellow,
                                                GamePiece::Yellow => GamePiece::Blank,
                                                GamePiece::Blank => GamePiece::Red,
                                            }
                                    })
                                    .background_color(
                                        match piece {
                                            GamePiece::Red => RED,
                                            GamePiece::Yellow => YELLOW,
                                            GamePiece::Blank => BLANK,
                                        },
                                    ),
                                )
                                .width(40.px())
                                .height(40.px())
                            })
                            .collect::<Vec<_>>(),
                    )
                })
                .collect::<Vec<_>>(),
        ),
        task_raw(
            move |proxy| {
                let mut cloned_hardware_receiver = hardware_sender.clone().subscribe();

                async move {
                    loop {
                        if let Ok(HardwareMessage::CaptureBoard) =
                            cloned_hardware_receiver.recv().await
                        {
                            let _ = proxy.message(());
                        }
                    }
                }
            },
            move |data: &mut HardwareEmulatorState, _| {
                let _ = data
                    .ui_message_sender
                    .send(UIMessage::CurrentBoard(data.current_board.clone()));
            },
        ),
    )
}
