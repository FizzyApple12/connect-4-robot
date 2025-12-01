use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub enum GamePiece {
    Red,
    Yellow,
    Blank,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct GameBoard {
    pub state: [[GamePiece; 6]; 7],
}
