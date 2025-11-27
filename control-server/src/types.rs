#[derive(Debug, Clone, PartialEq, Eq)]
pub enum GamePiece {
    Red,
    Yellow,
    Blank,
}

#[derive(Debug, Clone)]
pub struct GameBoard {
    pub state: [[GamePiece; 6]; 7],
}
