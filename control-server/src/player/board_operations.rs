use crate::{
    player::types::PlayerError,
    types::{GameBoard, GamePiece},
};

pub fn apply_move(
    mut board: GameBoard,
    (piece, column): (GamePiece, usize),
) -> Result<GameBoard, PlayerError> {
    for (piece_index, checking_piece) in board.state[column].iter().enumerate() {
        if *checking_piece != GamePiece::Blank {
            continue;
        }

        board.state[column][piece_index] = piece;

        return Ok(board);
    }

    Err(PlayerError::ImpossibleMove)
}
