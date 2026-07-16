/**
 * A row in the unified "Plugin Store". It shows a catalog plugin and installs
 * it with one click using the right backend, transparently:
 *   - suprapack package  -> `suprapack install plugin-<name>` (with progress)
 *   - git repository     -> Supravim.Plugin.add (url)
 * Clicking the row body opens the plugin's repository page when known.
 */
public class PluginStoreRow : Adw.ActionRow {

	// Emitted after the plugin list changed (install / remove) so the page
	// can reload the installed plugins and refresh every row state.
	public signal void plugin_changed ();

	// Lowercased haystack used by the search filter.
	public string search_text;
	// Repository URL, exposed so the page can match it against installed plugins.
	public string url { get { return entry.url; } }
	// Store category, exposed for the category filter.
	public string category { get { return entry.category; } }
	// True when this plugin is installed through suprapack rather than git.
	public bool is_suprapack { get { return entry.suprapack != ""; } }
	// suprapack package name (without the "plugin-" prefix), empty for git plugins.
	public string suprapack { get { return entry.suprapack; } }

	private CatalogEntry entry;
	private bool installed = false;
	private string? installed_name = null;

	private Gtk.Button action_button;
	private Gtk.Image action_image;

	public PluginStoreRow (CatalogEntry entry) {
		this.entry = entry;

		base.title = entry.name;
		base.subtitle = "by %s — %s".printf (entry.author, entry.description);

		// Clicking the row body opens the repository page (when we have a URL).
		if (entry.url != "") {
			base.tooltip_text = "Open %s".printf (entry.url);
			base.activatable = true;
			base.activated.connect (open_url);
		}

		search_text = "%s %s %s %s %s".printf (
			entry.name, entry.author, entry.description, entry.category, entry.suprapack).down ();

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

		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8) {
			valign = Gtk.Align.CENTER,
			margin_end = 10
		};
		box.append (badge);
		if (is_suprapack) {
			box.append (new Gtk.Label ("suprapack") {
				valign = Gtk.Align.CENTER,
				css_classes = {"plugin-suprapack"}
			});
		}
		box.append (action_button);
		base.add_suffix (box);

		refresh_button ();
	}

	/**
	 * Update the install/remove state of the row. For git plugins, `name` is
	 * the installed plugin name needed to remove it through libsupravim;
	 * suprapack plugins use their package name directly.
	 */
	public void set_installed (bool value, string? name) {
		installed = value;
		installed_name = name;
		refresh_button ();
	}

	/**
	 * Override the displayed description (used to show the one suprapack
	 * provides for its own packages instead of the catalog fallback).
	 */
	public void set_description (string description) {
		if (description != "")
			base.subtitle = "by %s — %s".printf (entry.author, description);
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

	// Open the plugin's repository page in the default browser.
	private void open_url () {
		try {
			AppInfo.launch_default_for_uri (entry.url, null);
		} catch (Error e) {
			warning ("Could not open %s: %s", entry.url, e.message);
		}
	}

	private void on_action () {
		if (is_suprapack)
			install_suprapack ();
		else
			install_git ();
	}

	// suprapack backend: run the package manager with a progress window.
	private void install_suprapack () {
		var window = base.get_root () as Gtk.Window;
		var popup = new PluginsDownloadWindow (window);
		var action = installed ? "uninstall" : "install";
		bool installing = !installed;
		var command = @"suprapack $action 'plugin-$(entry.suprapack)' --yes --simple-print";
		popup.execute.begin (command, (obj, res) => {
			popup.close ();
			if (installing)
				Utils.ach_plugin_install (entry.suprapack);
			plugin_changed ();
		});
	}

	// git backend: clone / remove through libsupravim.
	private void install_git () {
		var window = base.get_root () as Gtk.Window;
		bool installing = !installed;
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
		if (installing)
			Utils.ach_plugin_install (entry.url);
		plugin_changed ();
	}
}
