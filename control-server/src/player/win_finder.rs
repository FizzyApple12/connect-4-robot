use crate::types::{GameBoard, GamePiece};

pub fn check_for_wins_and_ties(board: &GameBoard) -> GamePiece {
    for i in 0..4 {
        let reduced_board: [[GamePiece; 6]; 4] = [
            board.state[i].clone(),
            board.state[1 + i].clone(),
            board.state[2 + i].clone(),
            board.state[3 + i].clone(),
        ];

        for j in 0..3 {
            let reduced_board: [[GamePiece; 4]; 4] = [
                reduced_board[0][j..(j + 4)]
                    .last_chunk::<4>()
                    .unwrap()
                    .clone(),
                reduced_board[1][j..(j + 4)]
                    .last_chunk::<4>()
                    .unwrap()
                    .clone(),
                reduced_board[2][j..(j + 4)]
                    .last_chunk::<4>()
                    .unwrap()
                    .clone(),
                reduced_board[3][j..(j + 4)]
                    .last_chunk::<4>()
                    .unwrap()
                    .clone(),
            ];

            match check_for_wins_in_block(reduced_board) {
                GamePiece::Blank => continue,
                winner => return winner,
            }
        }
    }

    GamePiece::Blank
}

pub fn check_for_wins_in_block(slice: [[GamePiece; 4]; 4]) -> GamePiece {
    match slice {
        [
            [
                GamePiece::Red,
                GamePiece::Red,
                GamePiece::Red,
                GamePiece::Red,
            ],
            [_, _, _, _],
            [_, _, _, _],
            [_, _, _, _],
        ]
        | [
            [_, _, _, _],
            [
                GamePiece::Red,
                GamePiece::Red,
                GamePiece::Red,
                GamePiece::Red,
            ],
            [_, _, _, _],
            [_, _, _, _],
        ]
        | [
            [_, _, _, _],
            [_, _, _, _],
            [
                GamePiece::Red,
                GamePiece::Red,
                GamePiece::Red,
                GamePiece::Red,
            ],
            [_, _, _, _],
        ]
        | [
            [_, _, _, _],
            [_, _, _, _],
            [_, _, _, _],
            [
                GamePiece::Red,
                GamePiece::Red,
                GamePiece::Red,
                GamePiece::Red,
            ],
        ]
        | [
            [GamePiece::Red, _, _, _],
            [GamePiece::Red, _, _, _],
            [GamePiece::Red, _, _, _],
            [GamePiece::Red, _, _, _],
        ]
        | [
            [_, GamePiece::Red, _, _],
            [_, GamePiece::Red, _, _],
            [_, GamePiece::Red, _, _],
            [_, GamePiece::Red, _, _],
        ]
        | [
            [_, _, GamePiece::Red, _],
            [_, _, GamePiece::Red, _],
            [_, _, GamePiece::Red, _],
            [_, _, GamePiece::Red, _],
        ]
        | [
            [_, _, _, GamePiece::Red],
            [_, _, _, GamePiece::Red],
            [_, _, _, GamePiece::Red],
            [_, _, _, GamePiece::Red],
        ]
        | [
            [_, _, _, GamePiece::Red],
            [_, _, GamePiece::Red, _],
            [_, GamePiece::Red, _, _],
            [GamePiece::Red, _, _, _],
        ]
        | [
            [GamePiece::Red, _, _, _],
            [_, GamePiece::Red, _, _],
            [_, _, GamePiece::Red, _],
            [_, _, _, GamePiece::Red],
        ] => GamePiece::Red,
        [
            [
                GamePiece::Yellow,
                GamePiece::Yellow,
                GamePiece::Yellow,
                GamePiece::Yellow,
            ],
            [_, _, _, _],
            [_, _, _, _],
            [_, _, _, _],
        ]
        | [
            [_, _, _, _],
            [
                GamePiece::Yellow,
                GamePiece::Yellow,
                GamePiece::Yellow,
                GamePiece::Yellow,
            ],
            [_, _, _, _],
            [_, _, _, _],
        ]
        | [
            [_, _, _, _],
            [_, _, _, _],
            [
                GamePiece::Yellow,
                GamePiece::Yellow,
                GamePiece::Yellow,
                GamePiece::Yellow,
            ],
            [_, _, _, _],
        ]
        | [
            [_, _, _, _],
            [_, _, _, _],
            [_, _, _, _],
            [
                GamePiece::Yellow,
                GamePiece::Yellow,
                GamePiece::Yellow,
                GamePiece::Yellow,
            ],
        ]
        | [
            [GamePiece::Yellow, _, _, _],
            [GamePiece::Yellow, _, _, _],
            [GamePiece::Yellow, _, _, _],
            [GamePiece::Yellow, _, _, _],
        ]
        | [
            [_, GamePiece::Yellow, _, _],
            [_, GamePiece::Yellow, _, _],
            [_, GamePiece::Yellow, _, _],
            [_, GamePiece::Yellow, _, _],
        ]
        | [
            [_, _, GamePiece::Yellow, _],
            [_, _, GamePiece::Yellow, _],
            [_, _, GamePiece::Yellow, _],
            [_, _, GamePiece::Yellow, _],
        ]
        | [
            [_, _, _, GamePiece::Yellow],
            [_, _, _, GamePiece::Yellow],
            [_, _, _, GamePiece::Yellow],
            [_, _, _, GamePiece::Yellow],
        ]
        | [
            [_, _, _, GamePiece::Yellow],
            [_, _, GamePiece::Yellow, _],
            [_, GamePiece::Yellow, _, _],
            [GamePiece::Yellow, _, _, _],
        ]
        | [
            [GamePiece::Yellow, _, _, _],
            [_, GamePiece::Yellow, _, _],
            [_, _, GamePiece::Yellow, _],
            [_, _, _, GamePiece::Yellow],
        ] => GamePiece::Yellow,
        _ => GamePiece::Blank,
    }
}
