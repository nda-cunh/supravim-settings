/**
 * The view displayed when the application is started. 
 * It contains buttons to update, clear cache and uninstall Suprapack.
 * and a ThemePage to change the theme of Supravim.
 */
[GtkTemplate (ui = "/ui/homepage.ui")]
public class HomePage : Gtk.Box {

	// Number of clicks on the logo needed to unlock the magic popup.
	private const int MAGIC_CLICKS = 5;

	private int logo_clicks = 0;
	private uint logo_reset_id = 0;
	private uint logo_bounce_id = 0;

	construct {
		test_if_update_available.begin();
		init_logo_easter_egg ();
	}

	public unowned Adw.ApplicationWindow parent_window;

	// GtkChildren
	[GtkChild]
	public unowned ThemePage theme_page;

	[GtkChild]
	public unowned Gtk.Button update_button;

	[GtkChild]
	public unowned Gtk.Picture logo_picture;


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
					run_config_command.begin (@"supravim --save '$(file.get_path ())'", "Config exported", "exportateur");
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
	private async void run_config_command (string command, string success_msg, string? ach_on_success = null) {
		string output, errput;
		int status = yield Utils.run_async_command (command, out output, out errput);

		var popup = new DialogPopup (parent_window, "SupraVim config");
		if (status == 0) {
			popup.set_subtitle_label (success_msg);
			if (ach_on_success != null)
				MainWindow.toast_ach (ach_on_success);
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


	/* ------------------------------------------------------------------ */
	/*  Easter egg: click the logo, get some magic                         */
	/* ------------------------------------------------------------------ */

	private void init_logo_easter_egg () {
		logo_picture.cursor = new Gdk.Cursor.from_name ("pointer", null);

		var gesture = new Gtk.GestureClick ();
		gesture.pressed.connect (() => on_logo_clicked ());
		logo_picture.add_controller (gesture);
	}

	private void on_logo_clicked () {
		bounce_logo ();

		logo_clicks++;
		if (logo_clicks >= MAGIC_CLICKS) {
			logo_clicks = 0;
			if (logo_reset_id != 0) {
				Source.remove (logo_reset_id);
				logo_reset_id = 0;
			}
			new MagicPopup (parent_window).present ();
			return;
		}

		// Only a quick burst of clicks unlocks the popup.
		if (logo_reset_id != 0)
			Source.remove (logo_reset_id);
		logo_reset_id = GLib.Timeout.add (1500, () => {
			logo_clicks = 0;
			logo_reset_id = 0;
			return false;
		});
	}

	private void bounce_logo () {
		logo_picture.add_css_class ("logo_bounce");
		if (logo_bounce_id != 0)
			Source.remove (logo_bounce_id);
		logo_bounce_id = GLib.Timeout.add (120, () => {
			logo_picture.remove_css_class ("logo_bounce");
			logo_bounce_id = 0;
			return false;
		});
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
