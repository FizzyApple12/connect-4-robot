use crate::hardware::{
    UserInterface, UserInterfaceButton, UserInterfaceError, UserInterfaceLightPattern,
};

pub struct EmulatedUserInterface {}

impl UserInterface for EmulatedUserInterface {
    async fn connect() -> Result<EmulatedUserInterface, UserInterfaceError> {
        Ok(EmulatedUserInterface {})
    }

    async fn set_button_lights(
        &self,
        button: UserInterfaceButton,
        pattern: UserInterfaceLightPattern,
    ) -> Result<(), UserInterfaceError> {
        todo!(
            "emulated user interface: set_button_lights {:?} {:?}",
            button,
            pattern
        )
    }

    async fn wait_for_button(&self, button: UserInterfaceButton) -> Result<(), UserInterfaceError> {
        todo!("emulated user interface: wait_for_button {:?}", button)
    }
}
