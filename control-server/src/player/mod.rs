use thiserror::Error;

use crate::types::{GameBoard, GamePiece};

#[derive(Error, Debug)]
pub enum PlayerError {
    #[error("Board won by {winner:?}")]
    ResultDetermined {
        winner: GamePiece,
        final_move: Option<(GamePiece, usize)>,
    },
}

pub async fn find_move(
    _board: &GameBoard,
    _search_depth: usize,
) -> Result<(GamePiece, usize), PlayerError> {
    Ok((GamePiece::Red, 0))
}
