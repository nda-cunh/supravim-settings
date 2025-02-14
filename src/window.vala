public class ClearCacheWindow : Adw.Window {

	private Gtk.ProgressBar progress_bar;
	private Gtk.Label label_update = new Gtk.Label("");

	public ClearCacheWindow (Gtk.Window mainWindow) {
		base.set_title("ClearCache");
		base.set_default_size(400, 40);
		base.set_modal(true);
		base.set_transient_for(mainWindow);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
			margin_top = 10,
			margin_bottom = 10,
			margin_start = 10,
			margin_end = 10
		};

		base.present ();
	}		
}

[GtkTemplate (ui = "/ui/window.ui")]
public class MainWindow : Adw.ApplicationWindow {

	[GtkCallback]
	public void update() {
		new UpdateWindow(this);
	}

	[GtkCallback]
	public void clear_cache() {
		new ClearCacheWindow(this);
	}

	[GtkCallback]
	public void uninstall() {
		print ("toto\n");
	}



	public MainWindow(Gtk.Application app) throws Error {
		Object(application: app);
		base.set_cursor_from_name ("default");
		wiki_box.append(new Wiki(Environment.get_home_dir() + "/.local/share/supravim-gui/"));
		plugins = new Plugins(plugins_group);
		options = new Options(options_group);

		theme_group.add (new ThemeGroups());
	}

	/* Private Variable */
	Plugins plugins;
	Options options;
	public string text;

	/* BluePrint Variable */
	[GtkChild]
	public unowned Adw.PreferencesGroup theme_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup plugins_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup options_group;
	[GtkChild]
	unowned Gtk.Box wiki_box; 
}
