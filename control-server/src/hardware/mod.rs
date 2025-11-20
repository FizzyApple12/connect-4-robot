mod emulated;
mod physical;

pub trait UserInterface {
    async fn connect() -> impl UserInterface;
}

pub trait PieceManipulator {
    async fn connect() -> impl PieceManipulator;
}

pub trait BoardReader {
    async fn connect() -> impl BoardReader;
}
