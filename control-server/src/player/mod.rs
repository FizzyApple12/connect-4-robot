use crate::types::{GameBoard, GamePiece};

pub async fn find_move(_board: &GameBoard, _search_depth: usize) -> (GamePiece, usize) {
    (GamePiece::Red, 0)
}
