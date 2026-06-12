[GtkTemplate (ui = "/ui/plugins/externalrow.ui")]
public class RowPluginExternal : Adw.ActionRow {
	// Private Members
	private string pl_name;
	private string pl_url;
	[GtkChild]
	public unowned Gtk.Switch status;

	// Signals
	public signal void refresh();

	// Constructor
	public RowPluginExternal (string name, string status, string url = "") {
		this.pl_name = name;
		this.pl_url = url;
		base.title = name;
		base.subtitle = "External Plugin";

		if (status == "Enable")
			this.status.set_active (true);
		else
			this.status.set_active (false);

		// Clicking the row (not its buttons) opens the repository page.
		if (url != "") {
			base.tooltip_text = "Open %s".printf (url);
			base.activatable = true;
			base.activated.connect (() => {
				try {
					AppInfo.launch_default_for_uri (pl_url, null);
				} catch (Error e) {
					warning ("Could not open %s: %s", pl_url, e.message);
				}
			});
		}
	}

	// Callbacks
	[GtkCallback]
	public bool toggle_plugin_status (bool state) {
		try {
			if (state)
				Supravim.Plugin.enable (pl_name);
			else
				Supravim.Plugin.disable (pl_name);
		} catch (Error e) {
			warning (e.message);
		}
		return false;
	}

	[GtkCallback]
	public void update_plugin () {
		try {
			Supravim.Plugin.update (pl_name);
		} catch (Error e) {
			var dialog = new DialogPopup (this.get_root () as Gtk.Window,
				"Error Updating Plugin",
				Utils.remove_color (e.message));
			dialog.add_cancel_button ();
			dialog.present ();
		}
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
				try {
					Supravim.Plugin.remove (name);
				} catch (Error e) {
					warning (e.message);
				}
				refresh ();
				base.close ();
			});

			box_buttons.append(uninstall_button);
			base.present();
		}
		public signal void refresh();
	}
}
