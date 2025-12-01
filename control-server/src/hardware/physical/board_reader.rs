use crate::hardware::physical::interfaces::HardwareMessage;
use crate::hardware::physical::interfaces::server::{
    ExternalServerInterface, ServerMessage, run_server,
};
use crate::hardware::{BoardReader, BoardReaderError};
use crate::types::GameBoard;

pub struct PhysicalBoardReader {
    server_interface: ExternalServerInterface,
}

impl BoardReader for PhysicalBoardReader {
    async fn connect() -> Result<PhysicalBoardReader, BoardReaderError> {
        let server_interface = run_server();

        Ok(PhysicalBoardReader { server_interface })
    }

    async fn capture(&self) -> Result<GameBoard, BoardReaderError> {
        println!("physical board reader: capture");

        let server_message_sender = self.server_interface.server_message_sender.clone();

        let mut server_message_receiver = server_message_sender.subscribe();

        if self
            .server_interface
            .hardware_message_sender
            .send(HardwareMessage::CaptureBoard)
            .is_err()
        {
            return Err(BoardReaderError::NoReaderConnected);
        }

        loop {
            if let Ok(ServerMessage::CurrentBoard(board)) = server_message_receiver.recv().await {
                return Ok(board);
            }
        }
    }
}
