pub mod board_operations;
pub mod types;
pub mod win_finder;

use std::cmp::Ordering;

use crate::{
    OPPONENT_PIECE, ROBOT_PIECE,
    player::{
        board_operations::apply_move,
        types::{PlayerError, SolutionTreeNode, SolutionTreeOutcome},
        win_finder::check_for_wins_and_ties,
    },
    types::{GameBoard, GamePiece},
};

pub fn generate_move_tree(
    board: &GameBoard,
    last_piece: GamePiece,
    current_depth: usize,
    max_depth: usize,
) -> SolutionTreeNode {
    let mut options: [Option<Box<SolutionTreeOutcome>>; 7] = [const { None }; 7];

    let this_played_piece = match last_piece {
        GamePiece::Red => GamePiece::Yellow,
        GamePiece::Yellow => GamePiece::Red,
        GamePiece::Blank => GamePiece::Blank,
    };

    (0..board.state.len()).for_each(|column_index| {
        if let Ok(modified_board) =
            apply_move(board.clone(), (this_played_piece.clone(), column_index))
        {
            options[column_index] = match check_for_wins_and_ties(&modified_board) {
                ROBOT_PIECE => Some(Box::new(SolutionTreeOutcome::Probability(1.0))),
                OPPONENT_PIECE => Some(Box::new(SolutionTreeOutcome::Probability(-1.0))),
                GamePiece::Blank => {
                    if current_depth >= max_depth {
                        Some(Box::new(SolutionTreeOutcome::Probability(0.0)))
                    } else {
                        Some(Box::new(SolutionTreeOutcome::Node(generate_move_tree(
                            &modified_board,
                            this_played_piece.clone(),
                            current_depth + 1,
                            max_depth,
                        ))))
                    }
                }
            };
        }
    });

    SolutionTreeNode { options }
}

pub fn find_move(
    board: &GameBoard,
    search_depth: usize,
) -> Result<(GamePiece, usize), PlayerError> {
    println!("solver checking if board is complete...");

    match check_for_wins_and_ties(board) {
        GamePiece::Blank => {}
        side => {
            println!("solver found a complete board, winner is {side:?}");

            return Err(PlayerError::ResultDetermined {
                winner: side,
                final_move: None,
            });
        }
    }

    println!("solver looking for any winning moves...");

    for column_index in 0..board.state.len() {
        if let Ok(modified_board) = apply_move(board.clone(), (ROBOT_PIECE, column_index))
            && check_for_wins_and_ties(&modified_board) == ROBOT_PIECE
        {
            println!("solver found a winning move in column {column_index}");

            return Err(PlayerError::ResultDetermined {
                winner: ROBOT_PIECE,
                final_move: Some((ROBOT_PIECE, column_index)),
            });
        }
    }

    println!("solver running deep move search...");

    let move_tree = generate_move_tree(board, OPPONENT_PIECE, 0, search_depth);

    let options = move_tree.flatten();

    println!("solver search results: {options:#?}");

    let best_option = options
        .iter()
        .enumerate()
        .filter_map(|(i, option)| option.map(|option| (i, option)))
        .max_by(|x, y| match (x.1).partial_cmp(&y.1) {
            Some(ordering) => ordering,
            None => match (x.1, y.1) {
                (x, y) if x.is_nan() && y.is_nan() => Ordering::Equal,
                (x, _) if x.is_nan() => Ordering::Less,
                (_, y) if y.is_nan() => Ordering::Greater,
                _ => Ordering::Equal,
            },
        });

    match best_option {
        Some((index, probability)) => {
            println!(
                "best move: {:?} at column {index} with a probability of {probability:.3}",
                ROBOT_PIECE
            );

            Ok((ROBOT_PIECE, index))
        }
        None => {
            println!("no possible moves found, board is likely tied and full");

            Err(PlayerError::ResultDetermined {
                winner: GamePiece::Blank,
                final_move: None,
            })
        }
    }
}
