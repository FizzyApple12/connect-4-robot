use crate::hardware::{BoardReader, BoardReaderError};
use crate::types::GameBoard;

pub struct EmulatedBoardReader {}

impl BoardReader for EmulatedBoardReader {
    async fn connect() -> Result<EmulatedBoardReader, BoardReaderError> {
        Ok(EmulatedBoardReader {})
    }

    async fn capture(&self) -> Result<GameBoard, BoardReaderError> {
        todo!("emulated board reader: capture")
    }
}
