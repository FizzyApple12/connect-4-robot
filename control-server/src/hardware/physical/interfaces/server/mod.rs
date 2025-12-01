pub mod endpoints;

use axum::{Json, Router, routing::get};
use endpoints::{
    EndpointModule,
    board_reader::{BOARD_READER_BASE_ENDPOINT, BoardReaderModule},
};
use serde_json::{Value, json};
use std::net::SocketAddr;
use std::sync::OnceLock;
use tokio::sync::broadcast;

use crate::hardware::physical::interfaces::HardwareMessage;

static SERVER_THREAD: OnceLock<ExternalServerInterface> = OnceLock::new();

#[derive(Debug, Clone)]
pub struct ExternalServerInterface {
    pub server_message_sender: broadcast::Sender<ServerMessage>,

    pub hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

#[derive(Debug, Clone)]
pub enum ServerMessage {
    CurrentBoard(crate::types::GameBoard),
}

#[derive(Debug, Clone)]
pub struct ServerState {
    server_message_sender: broadcast::Sender<ServerMessage>,

    hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

async fn root() -> Json<Value> {
    Json(json!({ "ok": true, "readme": "welcome to the connect 4 control server" }))
}

pub fn run_server() -> ExternalServerInterface {
    let interface = SERVER_THREAD.get_or_init(|| {
        let (server_message_sender, _) = broadcast::channel(16);
        let (hardware_message_sender, _) = broadcast::channel(16);

        let app_state = ServerState {
            server_message_sender: server_message_sender.clone(),

            hardware_message_sender: hardware_message_sender.clone(),
        };

        tokio::task::spawn(async move {
            let app = Router::new().route("/", get(root)).nest(
                BOARD_READER_BASE_ENDPOINT,
                BoardReaderModule::create_router(app_state.clone()),
            );

            let listener = tokio::net::TcpListener::bind("0.0.0.0:4226").await.unwrap();

            axum::serve(
                listener,
                app.into_make_service_with_connect_info::<SocketAddr>(),
            )
            .await
            .unwrap();
        });

        ExternalServerInterface {
            server_message_sender,

            hardware_message_sender,
        }
    });

    interface.clone()
}
