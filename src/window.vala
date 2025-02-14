[GtkTemplate (ui = "/ui/window.ui")]
public class MainWindow : Adw.ApplicationWindow {

	[GtkCallback]
	public void update() {
		var tmp = new UpdateWindow(this);
		tmp.close_request.connect(() => {
			test_if_update_available();
			return false;
		});
	}

	[GtkCallback]
	public void clear_cache() {
		new ClearCacheWindow(this);
	}

	[GtkCallback]
	public void uninstall() {
		new UninstallWindow(this);
	}



	public MainWindow(Gtk.Application app) throws Error {
		Object(application: app);
		base.set_cursor_from_name ("default");
		wiki_box.append(new Wiki(Environment.get_home_dir() + "/.local/share/supravim-gui/"));
		plugins = new Plugins(plugins_group);
		options = new Options(options_group, options_group_pl);
		theme_group.add (new ThemeGroups());

		test_if_update_available();
	}

	private void test_if_update_available () {
		try {
			string contents;
			Process.spawn_command_line_sync("suprapack have_update supravim", out contents);

			if (contents._strip() == "") {
				update_button.set_label("Update (no update available)");
				update_button.remove_css_class("have_update");
				return;
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
	}

	/* Private Variable */
	Plugins plugins;
	Options options;
	public string text;

	/* BluePrint Variable */
	[GtkChild]
	public unowned Gtk.Button update_button;
	[GtkChild]
	public unowned Adw.PreferencesGroup theme_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup plugins_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup options_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup options_group_pl;
	[GtkChild]
	unowned Gtk.Box wiki_box; 
}
