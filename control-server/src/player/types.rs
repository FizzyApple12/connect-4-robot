use crate::types::GamePiece;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum PlayerError {
    #[error("Board won by {winner:?}")]
    ResultDetermined {
        winner: GamePiece,
        final_move: Option<(GamePiece, usize)>,
    },

    #[error("Found impossible move")]
    ImpossibleMove,
}

pub enum SolutionTreeOutcome {
    Node(SolutionTreeNode),
    Probability(f64),
}

pub struct SolutionTreeNode {
    pub options: [Option<Box<SolutionTreeOutcome>>; 7],
}

impl SolutionTreeNode {
    pub fn flatten(self) -> [Option<f64>; 7] {
        let mut options: [Option<f64>; 7] = [None; 7];

        for (i, option) in self.options.into_iter().enumerate() {
            options[i] = match option {
                Some(boxed_outcome) => match *boxed_outcome {
                    SolutionTreeOutcome::Node(solution_tree_node) => {
                        let flattened = solution_tree_node.flatten();

                        let filtered: Vec<f64> = flattened.into_iter().flatten().collect();

                        let number_probabilities = filtered.len() as f64;

                        filtered
                            .into_iter()
                            .reduce(|accumulator, option| accumulator + option)
                            .map(|sum| sum / number_probabilities)
                    }
                    SolutionTreeOutcome::Probability(probability) => Some(probability),
                },
                None => None,
            };
        }

        options
    }
}
