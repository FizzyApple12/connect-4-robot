pub mod endpoints;

use axum::{Json, Router, routing::get};
use dotenv::dotenv;
use endpoints::{
    EndpointModule,
    board_reader::{DOORBELL_BASE_ENDPOINT, DoorbellModule},
};
use serde_json::{Value, json};
use std::net::SocketAddr;
use std::sync::OnceLock;
use std::thread;
use tokio::sync::broadcast;

static SERVER_THREAD: OnceLock<ExternalServerInterface> = OnceLock::new();

#[derive(Debug, Clone)]
pub struct ExternalServerInterface {
    pub ui_message_sender: broadcast::Sender<ServerMessage>,

    pub hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

#[derive(Debug, Clone)]
pub enum HardwareMessage {
    CaptureBoard,
}

#[derive(Debug, Clone)]
pub enum ServerMessage {
    CurrentBoard(crate::types::GameBoard),
}

#[derive(Debug, Clone)]
pub struct ServerState {
    ui_message_sender: broadcast::Sender<ServerMessage>,

    hardware_message_sender: broadcast::Sender<HardwareMessage>,
}

async fn root() -> Json<Value> {
    Json(json!({ "ok": true, "readme": "welcome to the connect 4 control server" }))
}

pub fn run_server() -> ExternalServerInterface {
    let interface = UI_THREAD.get_or_init(|| {
        let (ui_message_sender, _) = broadcast::channel(16);
        let (hardware_message_sender, _) = broadcast::channel(16);

        let app_state = ServerState {
            ui_message_sender: ui_message_sender.clone(),

            hardware_message_sender: hardware_message_sender.clone(),
        };

        let _ = tokio::task::spawn(async move {
            let app = Router::new()
                .route("/", get(root))
                .nest(DOORBELL_BASE_ENDPOINT, DoorbellModule::create_router());

            let listener = tokio::net::TcpListener::bind("0.0.0.0:4226").await.unwrap();

            axum::serve(
                listener,
                app.into_make_service_with_connect_info::<SocketAddr>(),
            )
            .await
            .unwrap();
        });

        ExternalServerInterface {
            ui_message_sender,

            hardware_message_sender,
        }
    });

    interface.clone()
}
