use crate::hardware::emulated::{ExternalUIInterface, HardwareMessage, UIMessage, run_ui};
use crate::hardware::{
    UserInterface, UserInterfaceButton, UserInterfaceError, UserInterfaceLightPattern,
};

pub struct EmulatedUserInterface {
    ui_interface: ExternalUIInterface,
}

impl UserInterface for EmulatedUserInterface {
    async fn connect() -> Result<EmulatedUserInterface, UserInterfaceError> {
        let ui_interface = run_ui();

        Ok(EmulatedUserInterface { ui_interface })
    }

    async fn set_button_lights(
        &self,
        button: UserInterfaceButton,
        pattern: UserInterfaceLightPattern,
    ) -> Result<(), UserInterfaceError> {
        println!(
            "emulated user interface: set_button_lights {:?} {:?}",
            button, pattern
        );

        let _ = self
            .ui_interface
            .hardware_message_sender
            .send(HardwareMessage::SetButtonLights(button, pattern));

        Ok(())
    }

    async fn wait_for_button(&self, button: UserInterfaceButton) -> Result<(), UserInterfaceError> {
        println!("emulated user interface: wait_for_button {:?}", button);

        let ui_message_sender = self.ui_interface.ui_message_sender.clone();

        let mut ui_message_receiver = ui_message_sender.subscribe();

        loop {
            if let Ok(UIMessage::ButtonPressed(button_pressed)) = ui_message_receiver.recv().await
                && button_pressed == button
            {
                break;
            }
        }

        Ok(())
    }
}
