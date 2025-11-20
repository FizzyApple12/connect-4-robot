#![allow(async_fn_in_trait)]

pub mod hardware;
pub mod player;
pub mod types;

enum MainLoopState {
    Init,
    // ReadyToStart {},
    Exit,
}

async fn next_state(state: MainLoopState) -> MainLoopState {
    match state {
        MainLoopState::Init => {
            println!("init");

            MainLoopState::Exit
        }
        MainLoopState::Exit => MainLoopState::Exit,
    }
}

#[tokio::main]
async fn main() {
    let mut state: MainLoopState = MainLoopState::Init;

    while !matches!(state, MainLoopState::Exit) {
        state = next_state(state).await;
    }

    println!("exit");
}
