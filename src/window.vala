[GtkTemplate (ui = "/ui/window.ui")]
public class MainWindow : Adw.ApplicationWindow {

	public MainWindow(Gtk.Application app) throws Error {
		Object(application: app);
		base.set_cursor_from_name ("default");
		try {
			wiki_box.append(new WikiPage(Environment.get_home_dir() + "/.local/share/supravim-gui/"));
		} catch (Error e) {
			printerr("Cant load the wiki\n");
		}
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
