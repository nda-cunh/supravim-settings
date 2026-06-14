/**
 * The Window widget of the application.
 */
[GtkTemplate (ui = "/ui/window.ui")]
public class MainWindow : Adw.ApplicationWindow {

	private bool wiki_loaded = false;

	public MainWindow(Gtk.Application app) throws Error {
		Object(application: app);

		home_page.parent_window = this;
		base.set_cursor_from_name ("default");
		base.set_icon_name("supravim");

		viewstack.notify["visible-child-name"].connect (load_visible_page);
		load_visible_page ();
	}

	/**
	 * Build the content of the currently visible page on first display.
	 * Pages already loaded just return early (each keeps its own guard).
	 */
	private void load_visible_page () {
		switch (viewstack.visible_child_name) {
		case "plugins":
			plugins_page.ensure_loaded ();
			break;
		case "lsp":
			lsp_page.ensure_loaded ();
			break;
		case "snippets":
			snippets_page.ensure_loaded ();
			break;
		case "wiki":
			if (!wiki_loaded) {
				wiki_loaded = true;
				wiki_box.append (new Wiki (Environment.get_home_dir () + "/.local/share/supravim-gui/"));
			}
			break;
		default:
			break;
		}
	}

	/* BluePrint Variable */
	[GtkChild]
	unowned Adw.ViewStack viewstack;
	[GtkChild]
	public unowned OptionsPage options_page;
	[GtkChild]
	public unowned LspPage lsp_page;
	[GtkChild]
	public unowned SnippetsPage snippets_page;
	[GtkChild]
	public unowned HomePage home_page;
	[GtkChild]
	public unowned PluginsPage plugins_page;
	[GtkChild]
	unowned Gtk.Box wiki_box; 
}
