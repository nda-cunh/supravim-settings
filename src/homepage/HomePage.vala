/**
 * The view displayed when the application is started. 
 * It contains buttons to update, clear cache and uninstall Suprapack.
 * and a ThemePage to change the theme of Supravim.
 */
[GtkTemplate (ui = "/ui/homepage.ui")]
public class HomePage : Gtk.Box {

	construct {
		test_if_update_available.begin();
	}

	public unowned Adw.ApplicationWindow parent_window;

	// GtkChildren
	[GtkChild]
	public unowned ThemePage theme_page; 

	[GtkChild]
	public unowned Gtk.Button update_button;


	// Callbacks for the buttons
	[GtkCallback]
	public void update () {
		var tmp = new WindowUpdate(parent_window);
		tmp.close_request.connect(() =>  {
			test_if_update_available.begin();
			return false;
		});
	}

	[GtkCallback]
	public void clear_cache () {
		new WindowClearCache(parent_window);
	}

	[GtkCallback]
	public void uninstall () {
		new WindowUninstall(parent_window);
	}

	/*
	 * Export the whole SupraVim configuration into a .supravim archive
	 * chosen by the user through a save dialog.
	 */
	[GtkCallback]
	public void export_config () {
		var chooser = new Gtk.FileChooserNative (
			"Export SupraVim config", parent_window,
			Gtk.FileChooserAction.SAVE, "Export", "Cancel"
		);
		chooser.set_current_name ("config.supravim");

		var filter = new Gtk.FileFilter ();
		filter.set_filter_name ("SupraVim config (*.supravim)");
		filter.add_pattern ("*.supravim");
		chooser.add_filter (filter);

		chooser.response.connect ((id) => {
			if (id == Gtk.ResponseType.ACCEPT) {
				var file = chooser.get_file ();
				if (file != null)
					run_config_command.begin (@"supravim --save '$(file.get_path ())'", "Config exported");
			}
			chooser.destroy ();
		});
		chooser.show ();
	}

	/*
	 * Import a SupraVim configuration from a .supravim archive
	 * chosen by the user through an open dialog.
	 */
	[GtkCallback]
	public void import_config () {
		var chooser = new Gtk.FileChooserNative (
			"Import SupraVim config", parent_window,
			Gtk.FileChooserAction.OPEN, "Import", "Cancel"
		);

		var filter = new Gtk.FileFilter ();
		filter.set_filter_name ("SupraVim config (*.supravim)");
		filter.add_pattern ("*.supravim");
		chooser.add_filter (filter);

		chooser.response.connect ((id) => {
			if (id == Gtk.ResponseType.ACCEPT) {
				var file = chooser.get_file ();
				if (file != null)
					run_config_command.begin (@"supravim --load '$(file.get_path ())'", "Config imported (restart Vim to apply)");
			}
			chooser.destroy ();
		});
		chooser.show ();
	}

	/*
	 * Run a supravim config command and report the result in a popup.
	 */
	private async void run_config_command (string command, string success_msg) {
		string output, errput;
		int status = yield Utils.run_async_command (command, out output, out errput);

		var popup = new DialogPopup (parent_window, "SupraVim config");
		if (status == 0) {
			popup.set_subtitle_label (success_msg);
		} else {
			string detail = Utils.remove_color ((errput ?? "").strip ());
			popup.set_subtitle_label (detail == "" ? "Operation failed" : detail);
		}
		var ok_button = new Gtk.Button.with_label ("Ok") {
			css_classes = {"button_popup"},
		};
		ok_button.clicked.connect (() => popup.close ());
		popup.box_buttons.append (ok_button);

		popup.present ();
	}


	/*
	 * Check if an update is available for Supravim using suprapack.
	 * If an update is available, the update button is enabled and its label is updated.
	 */
	private async void test_if_update_available () {
		string contents;
		yield Utils.run_async_command("suprapack have_update supravim", out contents);

		if (contents._strip() == "") {
			update_button.set_label("Update (no update available)");
			update_button.remove_css_class("have_update");
		}
		else {
			update_button.set_label(contents);
			update_button.add_css_class("have_update");
			update_button.set_sensitive(true);
		}
	}

}
