/**
 * A row in the "Plugin Store". It shows a catalog plugin (name, author,
 * description and category) and lets the user install it from its Git URL
 * with one click, or remove it again if it is already installed.
 */
public class PluginStoreRow : Adw.ActionRow {

	// Emitted after the plugin list changed (install / remove) so the page
	// can reload the installed plugins and refresh every row state.
	public signal void plugin_changed ();

	// Lowercased haystack used by the search filter.
	public string search_text;
	// Repository URL, exposed so the page can match it against installed plugins.
	public string url { get { return entry.url; } }

	private CatalogEntry entry;
	private bool installed = false;
	private string? installed_name = null;

	private Gtk.Button action_button;
	private Gtk.Image action_image;

	public PluginStoreRow (CatalogEntry entry) {
		this.entry = entry;

		base.title = entry.name;
		base.subtitle = "by %s — %s".printf (entry.author, entry.description);
		base.tooltip_text = entry.url;

		search_text = "%s %s %s %s".printf (
			entry.name, entry.author, entry.description, entry.category).down ();

		var badge = new Gtk.Label (entry.category) {
			valign = Gtk.Align.CENTER,
			css_classes = {"plugin-category"}
		};

		action_image = new Gtk.Image ();
		action_button = new Gtk.Button () {
			width_request = 34,
			height_request = 34,
			valign = Gtk.Align.CENTER,
			child = action_image
		};
		action_button.set_cursor_from_name ("pointer");
		action_button.clicked.connect (on_action);

		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
			valign = Gtk.Align.CENTER,
			margin_end = 10
		};
		box.append (badge);
		box.append (action_button);
		base.add_suffix (box);

		refresh_button ();
	}

	/**
	 * Update the install/remove state of the row. When installed, the
	 * plugin name is needed so it can be removed through libsupravim.
	 */
	public void set_installed (bool value, string? name) {
		installed = value;
		installed_name = name;
		refresh_button ();
	}

	private void refresh_button () {
		if (installed) {
			action_image.icon_name = "user-trash-symbolic";
			action_button.set_css_classes ({"uninstall"});
			action_button.tooltip_text = "Remove this plugin";
		}
		else {
			action_image.icon_name = "list-add-symbolic";
			action_button.set_css_classes ({"install"});
			action_button.tooltip_text = "Install this plugin";
		}
	}

	private void on_action () {
		var window = base.get_root () as Gtk.Window;
		try {
			if (installed && installed_name != null)
				Supravim.Plugin.remove (installed_name);
			else
				Supravim.Plugin.add (entry.url);
		}
		catch (Error e) {
			var dialog = new DialogPopup (window,
				installed ? "Error Removing Plugin" : "Error Installing Plugin",
				Utils.remove_color (e.message));
			dialog.add_cancel_button ();
			dialog.present ();
			return;
		}
		plugin_changed ();
	}
}
