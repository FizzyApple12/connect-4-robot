use super::EndpointModule;
use crate::{
    hardware::physical::interfaces::server::{HardwareMessage, ServerMessage, ServerState},
    types::GameBoard,
};
use axum::{
    Router,
    body::Bytes,
    extract::{
        State,
        ws::{Message, Utf8Bytes, WebSocket, WebSocketUpgrade},
    },
    response::IntoResponse,
    routing::get,
};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use tokio::{
    sync::watch::{self},
    task::JoinHandle,
};

pub const BOARD_READER_BASE_ENDPOINT: &str = "/board_reader";

#[derive(Debug, Clone, Deserialize, Serialize)]
pub enum BoardReaderOutgoingMessage {
    // Calibrate
    Capture,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub enum BoardReaderIncomingMessage {
    CaptureResults(GameBoard),
}

#[derive(Clone)]
enum SocketSenderMessage {
    Capture,
    PingPong,
}

pub struct BoardReaderModule {}

impl EndpointModule for BoardReaderModule {
    fn create_router(server_state: ServerState) -> Router {
        Router::new()
            .route("/", get(board_reader_entry))
            .with_state(server_state)
    }
}

async fn board_reader_entry(
    State(state): State<ServerState>,
    ws: WebSocketUpgrade,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| board_reader_socket(state, socket))
}

async fn board_reader_socket(state: ServerState, mut socket: WebSocket) {
    // if socket
    //     .send(Message::Ping(Bytes::from(vec![1, 2, 3])))
    //     .await
    //     .is_err()
    // {
    //     return;
    // }

    // if let Some(msg) = socket.recv().await {
    //     if let Ok(msg) = msg {
    //         if let Message::Close(_) = msg {
    //             return;
    //         }
    //     } else {
    //         return;
    //     }
    // }

    let ServerState {
        server_message_sender,
        hardware_message_sender,
    } = state;

    let (mut sender, mut receiver) = socket.split();

    let mut hardware_message_receiver = hardware_message_sender.subscribe();

    let (send_task_sender, mut send_task_receiver) =
        watch::channel::<SocketSenderMessage>(SocketSenderMessage::PingPong);

    let send_task_sender_2 = send_task_sender.clone();

    let mut send_task: JoinHandle<()> = tokio::spawn(async move {
        loop {
            if (send_task_receiver.changed().await).is_ok() {
                let next_message = send_task_receiver.borrow_and_update().clone();

                match next_message {
                    SocketSenderMessage::Capture => {
                        if let Ok(message) =
                            serde_json::to_string(&BoardReaderOutgoingMessage::Capture)
                            && sender
                                .send(Message::Text(Utf8Bytes::from(message)))
                                .await
                                .is_err()
                        {
                            return;
                        }
                    }
                    SocketSenderMessage::PingPong => {
                        if sender
                            .send(Message::Ping(Bytes::from(vec![
                                103, 111, 111, 100, 32, 109, 111, 114, 110, 105, 110, 103, 33, 33,
                                33,
                            ])))
                            .await
                            .is_err()
                        {
                            return;
                        }
                    }
                }
            }
        }
    });

    let mut ring_watcher_task: JoinHandle<()> = tokio::spawn(async move {
        loop {
            #[allow(irrefutable_let_patterns)]
            if let Ok(message) = hardware_message_receiver.recv().await
                && let HardwareMessage::CaptureBoard = message
            {
                println!("board reader server: requesting board reader to capture");

                let _ = send_task_sender.send(SocketSenderMessage::Capture);
            }
        }
    });

    let mut ping_pong_task: JoinHandle<()> = tokio::spawn(async move {
        loop {
            let _ = send_task_sender_2.send(SocketSenderMessage::PingPong);

            tokio::time::sleep(std::time::Duration::from_millis(5000)).await;
        }
    });

    let mut recv_task: JoinHandle<()> = tokio::spawn(async move {
        while let Some(Ok(msg)) = receiver.next().await {
            match msg {
                Message::Text(text) => {
                    if !text.is_empty() {
                        match serde_json::from_str::<BoardReaderIncomingMessage>(text.as_str()) {
                            Ok(BoardReaderIncomingMessage::CaptureResults(gameboard)) => {
                                println!(
                                    "board reader server: got capture results from board reader"
                                );

                                let _ = server_message_sender
                                    .send(ServerMessage::CurrentBoard(gameboard));
                            }
                            Err(err) => {
                                println!(
                                    "board reader server: unable to deserialize incoming message: {err:#?}"
                                )
                            }
                        }
                    }
                }
                Message::Close(_) => return,
                _ => {}
            }
        }
    });

    tokio::select! {
        _rv_a = (&mut send_task) => {
            ring_watcher_task.abort();
            ping_pong_task.abort();
            recv_task.abort();
        },
        _rv_b = (&mut recv_task) => {
            send_task.abort();
            ring_watcher_task.abort();
            ping_pong_task.abort();
        }
        _rv_c = (&mut ring_watcher_task) => {
            send_task.abort();
            ping_pong_task.abort();
            recv_task.abort();
        }
        _rv_d = (&mut ping_pong_task) => {
            send_task.abort();
            ring_watcher_task.abort();
            recv_task.abort();
        }
    }
}
