pub enum GamePiece {
    Red,
    Yellow,
    Blank,
}

pub struct GameBoard {
    pub state: [[GamePiece; 6]; 7],
}
