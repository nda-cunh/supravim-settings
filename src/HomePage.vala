/**
 * The view displayed when the application is started. 
 * It contains buttons to update, clear cache and uninstall Suprapack.
 * and a ThemePage to change the theme of Supravim.
 */
[GtkTemplate (ui = "/ui/homepage.ui")]
public class HomePage : Gtk.Box {

	construct {
		test_if_update_available();
	}

	public unowned Adw.ApplicationWindow parent_window;

	// GtkChildren
	[GtkChild]
	public unowned ThemePage theme_page; 

	[GtkChild]
	public unowned Gtk.Button update_button;


	// Callbacks for the buttons
	[GtkCallback]
	public void update() {
		var tmp = new WindowUpdate(parent_window);
		tmp.close_request.connect(test_if_update_available);
	}

	[GtkCallback]
	public void clear_cache() {
		new WindowClearCache(parent_window);
	}

	[GtkCallback]
	public void uninstall() {
		new WindowUninstall(parent_window);
	}


	/*
	 * Check if an update is available for Supravim using suprapack.
	 * If an update is available, the update button is enabled and its label is updated.
	 */
	private bool test_if_update_available () {
		try {
			string contents;
			Process.spawn_command_line_sync("suprapack have_update supravim", out contents);

			if (contents._strip() == "") {
				update_button.set_label("Update (no update available)");
				update_button.remove_css_class("have_update");
				return false;
			}
			else {
				update_button.set_label(contents);
				update_button.add_css_class("have_update");
				update_button.set_sensitive(true);
			}
		}
		catch (Error e) {
			print(e.message);
		}
		return false;
	}

}
