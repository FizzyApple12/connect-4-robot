pub mod board_reader;

use crate::hardware::physical::interfaces::server::ServerState;
use axum::Router;

pub trait EndpointModule {
    fn create_router(server_state: ServerState) -> Router;
}
