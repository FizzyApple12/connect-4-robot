use crate::types::GamePiece;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PlayerError {
    #[error("Board won by {winner:?}")]
    ResultDetermined {
        winner: GamePiece,
        final_move: Option<(GamePiece, usize)>,
    },
}

enum SolutionTreeOutcome {
    Node(SolutionTreeNode),
    Probability(f64),
}

struct SolutionTreeNode {
    options: [Option<Box<SolutionTreeOutcome>>; 7],
}

impl SolutionTreeNode {
    fn flatten(self) -> [f64; 7] {
        let mut options: [f64; 7] = [0.0; 7];

        for (i, option) in self.options.into_iter().enumerate() {
            options[i] = match option {
                Some(boxed_outcome) => match *boxed_outcome {
                    SolutionTreeOutcome::Node(solution_tree_node) => {
                        let flattened = solution_tree_node.flatten();

                        flattened
                            .into_iter()
                            .reduce(|accumulator, option| accumulator + (option / 7.0))
                            .unwrap_or(0.0)
                    }
                    SolutionTreeOutcome::Probability(probability) => probability,
                },
                None => 0.0,
            };
        }

        options
    }
}
