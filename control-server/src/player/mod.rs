pub mod types;

use crate::{
    player::types::PlayerError,
    types::{GameBoard, GamePiece},
};

pub async fn check_for_wins_and_ties(board: &GameBoard) -> Option<GamePiece> {
    None
}

pub async fn find_move(
    board: &GameBoard,
    _search_depth: usize,
) -> Result<(GamePiece, usize), PlayerError> {
    if let Some(side) = check_for_wins_and_ties(board).await {
        return Err(PlayerError::ResultDetermined {
            winner: side,
            final_move: None,
        });
    }

    Ok((GamePiece::Red, 0))
}
