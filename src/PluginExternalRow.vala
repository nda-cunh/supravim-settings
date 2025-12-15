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

[GtkTemplate (ui = "/ui/plugins/addexternalrow.ui")]
class RowAddPlugin : Adw.ActionRow {
	[GtkCallback]
	public void add_plugin_clicked () {
		new_plugin ();
	}

	public signal void new_plugin();
}

[GtkTemplate (ui = "/ui/plugins/externalrow.ui")]
public class RowPluginExternal : Adw.ActionRow {
	private string pl_name;
	public RowPluginExternal (string name, string status) {
		this.pl_name = name;
		base.title = name;
		base.subtitle = "External Plugin";
		if (status == "Enable")
			this.status.set_active (true);
		else
			this.status.set_active (false);
	}

	[GtkCallback]
	public bool toggle_plugin_status (bool state) { 
		if (state) {
			Utils.command_line (@"supravim --enable-plugin $pl_name");
			print ("Enabled");
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
	public signal void refresh();

	[GtkChild]
	public unowned Gtk.Switch status;
}
