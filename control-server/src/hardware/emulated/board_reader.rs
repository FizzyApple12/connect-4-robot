use crate::hardware::emulated::{ExternalUIInterface, HardwareMessage, UIMessage, run_ui};
use crate::hardware::{BoardReader, BoardReaderError};
use crate::types::GameBoard;

pub struct EmulatedBoardReader {
    ui_interface: ExternalUIInterface,
}

impl BoardReader for EmulatedBoardReader {
    async fn connect() -> Result<EmulatedBoardReader, BoardReaderError> {
        let ui_interface = run_ui();

        Ok(EmulatedBoardReader { ui_interface })
    }

    async fn capture(&self) -> Result<GameBoard, BoardReaderError> {
        println!("emulated board reader: capture");

        let ui_message_sender = self.ui_interface.ui_message_sender.clone();

        let mut ui_message_receiver = ui_message_sender.subscribe();

        let _ = self
            .ui_interface
            .hardware_message_sender
            .send(HardwareMessage::CaptureBoard);

        loop {
            if let Ok(ui_message) = ui_message_receiver.recv().await {
                match ui_message {
                    UIMessage::ButtonPressed(_) => {}
                    UIMessage::CurrentBoard(board) => {
                        return Ok(board);
                    }
                }
            }
        }

        // Err(BoardReaderError::NoReaderConnected)
    }
}
