/**
 * The Window widget of the application.
 */
[GtkTemplate (ui = "/ui/window.ui")]
public class MainWindow : Adw.ApplicationWindow {

	public MainWindow(Gtk.Application app) throws Error {
		Object(application: app);

		base.set_cursor_from_name ("default");
		wiki_box.append(new Wiki(Environment.get_home_dir() + "/.local/share/supravim-gui/"));
		// theme_group.add (new ThemePage());
		test_if_update_available();
	}

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


	[GtkCallback]
	public void update() {
		var tmp = new WindowUpdate(this);
		tmp.close_request.connect(test_if_update_available);
	}

	[GtkCallback]
	public void clear_cache() {
		new WindowClearCache(this);
	}

	[GtkCallback]
	public void uninstall() {
		new WindowUninstall(this);
	}
	/* BluePrint Variable */
	[GtkChild]
	public unowned Gtk.Button update_button;
	[GtkChild]
	public unowned ThemePage theme_page; 
	[GtkChild]
	public unowned OptionsPage options_page;
	[GtkChild]
	public unowned PluginsPage plugins_page;
	[GtkChild]
	unowned Gtk.Box wiki_box; 
}
