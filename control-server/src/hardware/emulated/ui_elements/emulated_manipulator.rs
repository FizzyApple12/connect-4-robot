use std::time::Duration;

use masonry::properties::types::AsUnit;
use xilem::Color;
use xilem::WidgetView;
use xilem::style::Style;
use xilem::view::{Axis, flex, label, sized_box, task_raw};
use xilem_core::fork;

use crate::hardware::DispenseSide;
use crate::hardware::PieceManipulatorPosition;
use crate::hardware::emulated::{HardwareEmulatorState, HardwareMessage};

const RED: Color = Color::from_rgb8(0xff, 0x00, 0x00);
const GREEN: Color = Color::from_rgb8(0x00, 0xff, 0x00);

const ACTIVE: Color = Color::from_rgb8(0xff, 0xff, 0xff);
const SUB_ACTIVE: Color = Color::from_rgb8(0x44, 0x44, 0x44);
const INACTIVE: Color = Color::from_rgb8(0x22, 0x22, 0x22);

#[derive(Debug, Clone)]
pub enum ManipulatorEvent {
    MoveTo(PieceManipulatorPosition),
    Grab(bool),
    BoardRelease(bool),
    Dispense(DispenseSide),
    OpponentDispenseDone,
}

// i really want to write this code in a more modular way but xilem doesn't have an
// equivalent to react's useState so self-contained state is basically impossible
pub fn emulated_manipulator(
    data: &mut HardwareEmulatorState,
) -> impl WidgetView<HardwareEmulatorState> + use<> {
    let hardware_sender = data.hardware_message_sender.clone();

    fork(
        flex(
            Axis::Vertical,
            (
                flex(
                    Axis::Horizontal,
                    (
                        sized_box(flex(
                            Axis::Horizontal,
                            label("home").color(
                                if data.position == PieceManipulatorPosition::Home {
                                    INACTIVE
                                } else {
                                    ACTIVE
                                },
                            ),
                        ))
                        .height(40.px())
                        .background_color(if data.position == PieceManipulatorPosition::Home {
                            ACTIVE
                        } else {
                            INACTIVE
                        })
                        .corner_radius(8.0)
                        .padding(8.0),
                        sized_box(flex(
                            Axis::Horizontal,
                            label("capture").color(
                                if data.position == PieceManipulatorPosition::Capture {
                                    INACTIVE
                                } else {
                                    ACTIVE
                                },
                            ),
                        ))
                        .height(40.px())
                        .background_color(if data.position == PieceManipulatorPosition::Capture {
                            ACTIVE
                        } else {
                            INACTIVE
                        })
                        .corner_radius(8.0)
                        .padding(8.0),
                        sized_box(flex(
                            Axis::Horizontal,
                            label("win").color(
                                if data.position == PieceManipulatorPosition::WinPose {
                                    INACTIVE
                                } else {
                                    ACTIVE
                                },
                            ),
                        ))
                        .height(40.px())
                        .background_color(if data.position == PieceManipulatorPosition::WinPose {
                            ACTIVE
                        } else {
                            INACTIVE
                        })
                        .corner_radius(8.0)
                        .padding(8.0),
                        sized_box(flex(
                            Axis::Horizontal,
                            label("lose").color(
                                if data.position == PieceManipulatorPosition::LosePose {
                                    INACTIVE
                                } else {
                                    ACTIVE
                                },
                            ),
                        ))
                        .height(40.px())
                        .background_color(if data.position == PieceManipulatorPosition::LosePose {
                            ACTIVE
                        } else {
                            INACTIVE
                        })
                        .corner_radius(8.0)
                        .padding(8.0),
                    ),
                ),
                flex(
                    Axis::Horizontal,
                    (0..7)
                        .map(|column_index| {
                            sized_box(flex(
                                Axis::Horizontal,
                                label(format!("{}d", column_index)).color(
                                    if data.position
                                        == PieceManipulatorPosition::ColumnDropOff(column_index)
                                    {
                                        INACTIVE
                                    } else {
                                        ACTIVE
                                    },
                                ),
                            ))
                            .width(40.px())
                            .height(40.px())
                            .background_color(
                                if data.position
                                    == PieceManipulatorPosition::ColumnDropOff(column_index)
                                {
                                    ACTIVE
                                } else {
                                    INACTIVE
                                },
                            )
                            .corner_radius(8.0)
                            .padding(8.0)
                        })
                        .collect::<Vec<_>>(),
                ),
                flex(
                    Axis::Horizontal,
                    (0..7)
                        .map(|column_index| {
                            sized_box(flex(
                                Axis::Horizontal,
                                label(format!("{}p", column_index)).color(
                                    if data.position
                                        == PieceManipulatorPosition::ColumnPickUp(column_index)
                                    {
                                        INACTIVE
                                    } else {
                                        ACTIVE
                                    },
                                ),
                            ))
                            .width(40.px())
                            .height(40.px())
                            .background_color(
                                if data.position
                                    == PieceManipulatorPosition::ColumnPickUp(column_index)
                                {
                                    ACTIVE
                                } else if data.release {
                                    SUB_ACTIVE
                                } else {
                                    INACTIVE
                                },
                            )
                            .corner_radius(8.0)
                            .padding(8.0)
                        })
                        .collect::<Vec<_>>(),
                ),
                flex(
                    Axis::Horizontal,
                    (
                        label("robot magazine"),
                        sized_box(flex(
                            Axis::Horizontal,
                            label("pickup").color(
                                if data.position == PieceManipulatorPosition::SelfPickUp {
                                    INACTIVE
                                } else {
                                    ACTIVE
                                },
                            ),
                        ))
                        .height(40.px())
                        .background_color(
                            if data.position == PieceManipulatorPosition::SelfPickUp {
                                ACTIVE
                            } else if data.dispensed_robot {
                                SUB_ACTIVE
                            } else {
                                INACTIVE
                            },
                        )
                        .corner_radius(8.0)
                        .padding(8.0),
                        sized_box(flex(
                            Axis::Horizontal,
                            label("dropoff").color(
                                if data.position == PieceManipulatorPosition::SelfDropOff {
                                    INACTIVE
                                } else {
                                    ACTIVE
                                },
                            ),
                        ))
                        .height(40.px())
                        .background_color(
                            if data.position == PieceManipulatorPosition::SelfDropOff {
                                ACTIVE
                            } else {
                                INACTIVE
                            },
                        )
                        .corner_radius(8.0)
                        .padding(8.0),
                    ),
                ),
                flex(
                    Axis::Horizontal,
                    (
                        label("opponent magazine"),
                        sized_box(flex(Axis::Horizontal, label("pickup").color(ACTIVE)))
                            .height(40.px())
                            .background_color(if data.dispensed_opponent {
                                SUB_ACTIVE
                            } else {
                                INACTIVE
                            })
                            .corner_radius(8.0)
                            .padding(8.0),
                        sized_box(flex(
                            Axis::Horizontal,
                            label("dropoff").color(
                                if data.position == PieceManipulatorPosition::OpponentDropOff {
                                    INACTIVE
                                } else {
                                    ACTIVE
                                },
                            ),
                        ))
                        .height(40.px())
                        .background_color(
                            if data.position == PieceManipulatorPosition::OpponentDropOff {
                                ACTIVE
                            } else {
                                INACTIVE
                            },
                        )
                        .corner_radius(8.0)
                        .padding(8.0),
                    ),
                ),
                flex(
                    Axis::Horizontal,
                    sized_box(flex(Axis::Horizontal, label("grabbing").color(ACTIVE)))
                        .height(40.px())
                        .background_color(if data.grab { GREEN } else { RED })
                        .corner_radius(8.0)
                        .padding(8.0),
                ),
            ),
        ),
        task_raw(
            move |proxy| {
                let mut cloned_hardware_receiver = hardware_sender.clone().subscribe();

                async move {
                    loop {
                        if let Ok(message) = cloned_hardware_receiver.recv().await {
                            match message {
                                HardwareMessage::MoveTo(position) => {
                                    let _ = proxy.message(ManipulatorEvent::MoveTo(position));
                                }
                                HardwareMessage::Grab(grip) => {
                                    let _ = proxy.message(ManipulatorEvent::Grab(grip));
                                }
                                HardwareMessage::BoardRelease(release) => {
                                    let _ = proxy.message(ManipulatorEvent::BoardRelease(release));
                                }
                                HardwareMessage::Dispense(side) => {
                                    let _ = proxy.message(ManipulatorEvent::Dispense(side));

                                    let proxy_clone = proxy.clone();

                                    tokio::task::spawn(async move {
                                        tokio::time::sleep(Duration::from_secs(1)).await;

                                        let _ = proxy_clone
                                            .message(ManipulatorEvent::OpponentDispenseDone);
                                    });
                                }
                                _ => {}
                            }
                        }
                    }
                }
            },
            move |data: &mut HardwareEmulatorState, event: ManipulatorEvent| match event {
                ManipulatorEvent::MoveTo(piece_manipulator_position) => {
                    data.position = piece_manipulator_position;
                }
                ManipulatorEvent::Grab(grip) => {
                    data.grab = grip;
                    if data.position == PieceManipulatorPosition::SelfPickUp {
                        data.dispensed_robot = false;
                    }
                }
                ManipulatorEvent::BoardRelease(release) => {
                    data.release = release;
                }
                ManipulatorEvent::Dispense(DispenseSide::Robot) => {
                    data.dispensed_robot = true;
                }
                ManipulatorEvent::Dispense(DispenseSide::Opponent) => {
                    data.dispensed_opponent = true;
                }
                ManipulatorEvent::OpponentDispenseDone => {
                    data.dispensed_opponent = false;
                }
            },
        ),
    )
}
