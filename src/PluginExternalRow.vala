[GtkTemplate (ui = "/ui/plugins/externalrow.ui")]
public class RowPluginExternal : Adw.ActionRow {
	// Private Members
	private string pl_name;
	[GtkChild]
	public unowned Gtk.Switch status;

	// Signals
	public signal void refresh();

	// Constructor
	public RowPluginExternal (string name, string status) {
		this.pl_name = name;
		base.title = name;
		base.subtitle = "External Plugin";

		if (status == "Enable")
			this.status.set_active (true);
		else
			this.status.set_active (false);
	}

	// Callbacks
	[GtkCallback]
	public bool toggle_plugin_status (bool state) { 
		if (state) {
			Utils.command_line (@"supravim --enable-plugin $pl_name");
		} else {
			Utils.command_line (@"supravim --disable-plugin $pl_name");
		}
		return false;
	}

	[GtkCallback]
	public void show_uninstall_window() {
		var parent = this.get_root() as Gtk.Window;
		var dialog = new WindowRemovePlugin (parent, pl_name);

		dialog.refresh.connect (() => refresh());
		dialog.present();
	}

	/**
  	 * Class for the Popup Window to remove a plugin
  	 */
	public class WindowRemovePlugin : DialogPopup {
		public WindowRemovePlugin (Gtk.Window mainWindow, string name) {
			base (mainWindow, "Uninstall Plugin", @"Are you sure you want to uninstall '$name' plugin?");
			base.add_cancel_button ();

			var uninstall_button = new Gtk.Button.with_label(@"Uninstall $name") {
				css_classes = {"destructive-action", "button_popup"},
			};

			uninstall_button.clicked.connect (() => {
				Utils.command_line (@"supravim --remove-plugin $name");
				refresh();
				base.close();
			});

			box_buttons.append(uninstall_button);
			base.present();
		}
		public signal void refresh();
	}
}
