/**
 * The Window widget of the application.
 */
[GtkTemplate (ui = "/ui/window.ui")]
public class MainWindow : Adw.ApplicationWindow {

	public MainWindow(Gtk.Application app) throws Error {
		Object(application: app);

		home_page.parent_window = this;
		base.set_cursor_from_name ("default");
		wiki_box.append(new Wiki(Environment.get_home_dir() + "/.local/share/supravim-gui/"));
	}

	/* BluePrint Variable */
	[GtkChild]
	public unowned OptionsPage options_page;
	[GtkChild]
	public unowned HomePage home_page;
	[GtkChild]
	public unowned PluginsPage plugins_page;
	[GtkChild]
	unowned Gtk.Box wiki_box; 
}
