use crate::hardware::physical::interfaces::HardwareMessage;
use crate::hardware::physical::interfaces::desk_serial::{
    DeskSerialInterface, DeskSerialMessage, connect_desk_serial,
};
use crate::hardware::{
    UserInterface, UserInterfaceButton, UserInterfaceError, UserInterfaceLightPattern,
};

pub struct PhysicalUserInterface {
    desk_serial_interface: DeskSerialInterface,
}

impl UserInterface for PhysicalUserInterface {
    async fn connect() -> Result<PhysicalUserInterface, UserInterfaceError> {
        let desk_serial_interface = connect_desk_serial().await;

        Ok(PhysicalUserInterface {
            desk_serial_interface,
        })
    }

    async fn set_button_lights(
        &self,
        button: UserInterfaceButton,
        pattern: UserInterfaceLightPattern,
    ) -> Result<(), UserInterfaceError> {
        println!(
            "physical user interface: set_button_lights {:?} {:?}",
            button, pattern
        );

        let _ = self
            .desk_serial_interface
            .hardware_message_sender
            .send(HardwareMessage::SetButtonLights(button, pattern));

        Ok(())
    }

    async fn wait_for_button(&self, button: UserInterfaceButton) -> Result<(), UserInterfaceError> {
        println!("physical user interface: wait_for_button {:?}", button);

        let serial_message_sender = self.desk_serial_interface.serial_message_sender.clone();

        let mut serial_message_receiver = serial_message_sender.subscribe();

        loop {
            if let Ok(DeskSerialMessage::ButtonPressed(pressed_button)) =
                serial_message_receiver.recv().await
                && pressed_button == button
            {
                break;
            }
        }

        Ok(())
    }
}
