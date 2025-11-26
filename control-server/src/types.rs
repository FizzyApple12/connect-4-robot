#[derive(Debug)]
pub enum GamePiece {
    Red,
    Yellow,
    Blank,
}

#[derive(Debug)]
pub struct GameBoard {
    pub state: [[GamePiece; 6]; 7],
}
