#![allow(async_fn_in_trait)]

use crate::{
    hardware::{
        BoardReader, DispenseSide, PieceManipulator, PieceManipulatorPosition, UserInterface,
        UserInterfaceButton, UserInterfaceLightPattern,
        generic::{GenericBoardReader, GenericPieceManipulator, GenericUserInterface},
    },
    player::PlayerError,
    types::GamePiece,
};
use std::time::Duration;

pub mod hardware;
pub mod player;
pub mod types;

pub const SIMPLE_TURN_DEPTH: usize = 2;
pub const COMPLEX_TURN_DEPTH: usize = 5;

enum MainLoopState {
    Init,
    ResettingBoard {
        user_interface: GenericUserInterface,
        piece_manipulator: GenericPieceManipulator,
        board_reader: GenericBoardReader,
    },
    ReadyToStart {
        user_interface: GenericUserInterface,
        piece_manipulator: GenericPieceManipulator,
        board_reader: GenericBoardReader,
    },
    WaitingForOpponentTurn {
        user_interface: GenericUserInterface,
        piece_manipulator: GenericPieceManipulator,
        board_reader: GenericBoardReader,
    },
    RobotTurn {
        user_interface: GenericUserInterface,
        piece_manipulator: GenericPieceManipulator,
        board_reader: GenericBoardReader,
        search_depth: usize,
    },
    Exit,
}

async fn next_state(state: MainLoopState) -> MainLoopState {
    match state {
        MainLoopState::Init => {
            let user_interface = match GenericUserInterface::connect().await {
                Ok(user_interface) => user_interface,
                Err(err) => {
                    println!("failed to connect to user interface: {err:#?}");

                    return MainLoopState::Exit;
                }
            };

            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Red, UserInterfaceLightPattern::On)
                .await;
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Yellow, UserInterfaceLightPattern::On)
                .await;
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Green, UserInterfaceLightPattern::On)
                .await;

            let piece_manipulator = match GenericPieceManipulator::connect().await {
                Ok(piece_manipulator) => piece_manipulator,
                Err(err) => {
                    println!("failed to connect to piece manipulator: {err:#?}");

                    return MainLoopState::Exit;
                }
            };

            let _ = piece_manipulator.board_release(false).await;
            let _ = piece_manipulator.grab(false).await;
            let _ = piece_manipulator
                .move_to(PieceManipulatorPosition::Home)
                .await;

            let board_reader = match GenericBoardReader::connect().await {
                Ok(board_reader) => board_reader,
                Err(err) => {
                    println!("failed to connect to board reader: {err:#?}");

                    return MainLoopState::Exit;
                }
            };

            MainLoopState::ResettingBoard {
                user_interface,
                piece_manipulator,
                board_reader,
            }
        }
        MainLoopState::ResettingBoard {
            user_interface,
            piece_manipulator,
            board_reader,
        } => {
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Red, UserInterfaceLightPattern::On)
                .await;
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Yellow, UserInterfaceLightPattern::Off)
                .await;
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Green, UserInterfaceLightPattern::Off)
                .await;

            let _ = piece_manipulator
                .move_to(PieceManipulatorPosition::Capture)
                .await;

            let board_state = match board_reader.capture().await {
                Ok(board_state) => board_state,
                Err(err) => {
                    println!("failed to read board, retrying in 1 second: {err:#?}");

                    tokio::time::sleep(Duration::from_secs(1)).await;

                    return MainLoopState::ResettingBoard {
                        user_interface,
                        piece_manipulator,
                        board_reader,
                    };
                }
            };

            println!("board: {board_state:#?}");

            let _ = piece_manipulator.board_release(true).await;

            for (column_index, board_column) in board_state.state.iter().enumerate() {
                for piece in board_column.iter().rev() {
                    if *piece == GamePiece::Blank {
                        continue;
                    }

                    let _ = piece_manipulator
                        .move_to(PieceManipulatorPosition::ColumnPickUp(column_index))
                        .await;

                    let _ = piece_manipulator.grab(true).await;

                    let _ = piece_manipulator
                        .move_to(PieceManipulatorPosition::Home)
                        .await;

                    match piece {
                        GamePiece::Red => {
                            let _ = piece_manipulator
                                .move_to(PieceManipulatorPosition::SelfDropOff)
                                .await;
                        }
                        GamePiece::Yellow => {
                            let _ = piece_manipulator
                                .move_to(PieceManipulatorPosition::OpponentDropOff)
                                .await;
                        }
                        GamePiece::Blank => {}
                    }

                    let _ = piece_manipulator.grab(false).await;

                    let _ = piece_manipulator
                        .move_to(PieceManipulatorPosition::Home)
                        .await;
                }
            }

            let _ = piece_manipulator.board_release(false).await;

            let _ = piece_manipulator
                .move_to(PieceManipulatorPosition::Home)
                .await;

            MainLoopState::ReadyToStart {
                user_interface,
                piece_manipulator,
                board_reader,
            }
        }
        MainLoopState::ReadyToStart {
            user_interface,
            piece_manipulator,
            board_reader,
        } => {
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Red, UserInterfaceLightPattern::Off)
                .await;
            let _ = user_interface
                .set_button_lights(
                    UserInterfaceButton::Yellow,
                    UserInterfaceLightPattern::Blink,
                )
                .await;
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Green, UserInterfaceLightPattern::Blink)
                .await;

            tokio::select! {
                _ = user_interface.wait_for_button(UserInterfaceButton::Green) => {
                    MainLoopState::RobotTurn {
                        user_interface,
                        piece_manipulator,
                        board_reader,
                        search_depth: COMPLEX_TURN_DEPTH
                    }
                },
                _ = user_interface.wait_for_button(UserInterfaceButton::Yellow) => {
                    MainLoopState::RobotTurn {
                        user_interface,
                        piece_manipulator,
                        board_reader,
                        search_depth: SIMPLE_TURN_DEPTH
                    }
                },
            }
        }
        MainLoopState::WaitingForOpponentTurn {
            user_interface,
            piece_manipulator,
            board_reader,
        } => {
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Red, UserInterfaceLightPattern::Blink)
                .await;
            let _ = user_interface
                .set_button_lights(
                    UserInterfaceButton::Yellow,
                    UserInterfaceLightPattern::Blink,
                )
                .await;
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Green, UserInterfaceLightPattern::Blink)
                .await;

            tokio::select! {
                _ = user_interface.wait_for_button(UserInterfaceButton::Green) => {
                    MainLoopState::RobotTurn {
                        user_interface,
                        piece_manipulator,
                        board_reader,
                        search_depth: COMPLEX_TURN_DEPTH
                    }
                },
                _ = user_interface.wait_for_button(UserInterfaceButton::Yellow) => {
                    MainLoopState::RobotTurn {
                        user_interface,
                        piece_manipulator,
                        board_reader,
                        search_depth: SIMPLE_TURN_DEPTH
                    }
                },
                _ = user_interface.wait_for_button(UserInterfaceButton::Red) => {
                    MainLoopState::ResettingBoard {
                        user_interface,
                        piece_manipulator,
                        board_reader,
                    }
                },
            }
        }
        MainLoopState::RobotTurn {
            user_interface,
            piece_manipulator,
            board_reader,
            search_depth,
        } => {
            let _ = user_interface
                .set_button_lights(UserInterfaceButton::Red, UserInterfaceLightPattern::Off)
                .await;
            let _ = user_interface
                .set_button_lights(
                    UserInterfaceButton::Yellow,
                    if search_depth == SIMPLE_TURN_DEPTH {
                        UserInterfaceLightPattern::On
                    } else {
                        UserInterfaceLightPattern::Off
                    },
                )
                .await;
            let _ = user_interface
                .set_button_lights(
                    UserInterfaceButton::Green,
                    if search_depth == COMPLEX_TURN_DEPTH {
                        UserInterfaceLightPattern::On
                    } else {
                        UserInterfaceLightPattern::Off
                    },
                )
                .await;

            let _ = piece_manipulator
                .move_to(PieceManipulatorPosition::Capture)
                .await;

            let board_state = match board_reader.capture().await {
                Ok(board_state) => board_state,
                Err(err) => {
                    println!("failed to read board, retrying in 1 second: {err:#?}");

                    tokio::time::sleep(Duration::from_secs(1)).await;

                    return MainLoopState::RobotTurn {
                        user_interface,
                        piece_manipulator,
                        board_reader,
                        search_depth,
                    };
                }
            };

            println!("board: {board_state:#?}");

            let ((piece_type, column), reset, won) =
                match player::find_move(&board_state, search_depth).await {
                    Ok(player_move) => (player_move, false, false),
                    Err(PlayerError::ResultDetermined { winner, final_move }) => {
                        match (winner, final_move) {
                            (GamePiece::Red, Some(final_move)) => (final_move, true, true),
                            (GamePiece::Yellow, Some(final_move))
                            | (GamePiece::Blank, Some(final_move)) => (final_move, true, false),
                            (GamePiece::Red, None) => {
                                let _ = piece_manipulator
                                    .move_to(PieceManipulatorPosition::WinPose)
                                    .await;

                                let _ = piece_manipulator
                                    .move_to(PieceManipulatorPosition::Home)
                                    .await;

                                return MainLoopState::ResettingBoard {
                                    user_interface,
                                    piece_manipulator,
                                    board_reader,
                                };
                            }
                            (GamePiece::Yellow, None) | (GamePiece::Blank, None) => {
                                let _ = piece_manipulator
                                    .move_to(PieceManipulatorPosition::LosePose)
                                    .await;

                                let _ = piece_manipulator
                                    .move_to(PieceManipulatorPosition::Home)
                                    .await;

                                return MainLoopState::ResettingBoard {
                                    user_interface,
                                    piece_manipulator,
                                    board_reader,
                                };
                            }
                        }
                    } // Err(err) => {
                      //     println!("player encountered an error, retrying on 1 second: {err:#?}");

                      //     tokio::time::sleep(Duration::from_secs(1)).await;

                      //     return MainLoopState::RobotTurn {
                      //         user_interface,
                      //         piece_manipulator,
                      //         board_reader,
                      //         search_depth,
                      //     };
                      // }
                };

            match piece_type {
                GamePiece::Red => {
                    let _ = piece_manipulator.dispense(DispenseSide::Robot).await;

                    let _ = piece_manipulator
                        .move_to(PieceManipulatorPosition::SelfPickUp)
                        .await;

                    let _ = piece_manipulator.grab(true).await;

                    let _ = piece_manipulator
                        .move_to(PieceManipulatorPosition::Home)
                        .await;

                    let _ = piece_manipulator
                        .move_to(PieceManipulatorPosition::ColumnDropOff(column))
                        .await;

                    let _ = piece_manipulator.grab(false).await;

                    let _ = piece_manipulator
                        .move_to(PieceManipulatorPosition::Home)
                        .await;

                    let _ = piece_manipulator.dispense(DispenseSide::Opponent).await;

                    if reset {
                        if won {
                            let _ = piece_manipulator
                                .move_to(PieceManipulatorPosition::WinPose)
                                .await;
                        } else {
                            let _ = piece_manipulator
                                .move_to(PieceManipulatorPosition::LosePose)
                                .await;
                        }

                        let _ = piece_manipulator
                            .move_to(PieceManipulatorPosition::Home)
                            .await;

                        MainLoopState::ResettingBoard {
                            user_interface,
                            piece_manipulator,
                            board_reader,
                        }
                    } else {
                        MainLoopState::WaitingForOpponentTurn {
                            user_interface,
                            piece_manipulator,
                            board_reader,
                        }
                    }
                }
                _ => {
                    let _ = piece_manipulator
                        .move_to(PieceManipulatorPosition::Home)
                        .await;

                    if reset {
                        if won {
                            let _ = piece_manipulator
                                .move_to(PieceManipulatorPosition::WinPose)
                                .await;
                        } else {
                            let _ = piece_manipulator
                                .move_to(PieceManipulatorPosition::LosePose)
                                .await;
                        }

                        let _ = piece_manipulator
                            .move_to(PieceManipulatorPosition::Home)
                            .await;

                        MainLoopState::ResettingBoard {
                            user_interface,
                            piece_manipulator,
                            board_reader,
                        }
                    } else {
                        MainLoopState::WaitingForOpponentTurn {
                            user_interface,
                            piece_manipulator,
                            board_reader,
                        }
                    }
                }
            }
        }
        MainLoopState::Exit => MainLoopState::Exit,
    }
}

#[tokio::main(flavor = "multi_thread")]
async fn main() {
    let mut state: MainLoopState = MainLoopState::Init;

    while !matches!(state, MainLoopState::Exit) {
        state = next_state(state).await;
    }

    println!("exit");
}
