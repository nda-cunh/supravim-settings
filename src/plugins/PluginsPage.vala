
[GtkTemplate (ui = "/ui/plugins.ui")]
public class PluginsPage : Gtk.Box {

	[GtkChild]
	public unowned Gtk.SearchEntry search_entry;
	[GtkChild]
	public unowned Adw.PreferencesGroup store_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup external_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup plugins_group;

	private List<PluginStoreRow> store_rows = new List<PluginStoreRow> ();
	private List<RowPluginExternal> external_rows = new List<RowPluginExternal> ();

	construct {
		build_store ();
		load_external.begin ();
		load_plugins.begin ();
	}

	/**
	  * Open the "add a plugin from a Git URL" dialog.
	  */
	[GtkCallback]
	public void on_add_plugin () {
		var parent = this.get_root () as Gtk.Window;
		var dialog = new WindowAddPlugin (parent);
		dialog.refresh.connect (() => load_external.begin ());
		dialog.present ();
	}

	/**
	  * Update every installed plugin at once.
	  */
	[GtkCallback]
	public void on_update_all () {
		try {
			Supravim.Plugin.update_all ();
		} catch (Error e) {
			var parent = this.get_root () as Gtk.Window;
			var dialog = new DialogPopup (parent,
				"Error Updating Plugins",
				Utils.remove_color (e.message));
			dialog.add_cancel_button ();
			dialog.present ();
		}
		load_external.begin ();
	}

	/**
	  * Filter the store rows as the user types in the search entry.
	  */
	[GtkCallback]
	public void on_search_changed () {
		var query = search_entry.text.strip ().down ();
		foreach (unowned var row in store_rows)
			row.visible = (query == "" || row.search_text.contains (query));
	}

	/**
	  * Build the store once from the embedded catalog. Rows are kept around
	  * so the search filter and the installed-state can update them in place.
	  */
	private void build_store () {
		foreach (unowned var entry in PluginCatalog.load ()) {
			var row = new PluginStoreRow (entry);
			row.plugin_changed.connect (() => load_external.begin ());
			store_rows.append (row);
			store_group.add (row);
		}
	}

	/**
	  * Mark every store row as installed/not-installed by matching its URL
	  * against the list of installed external plugins.
	  */
	private void refresh_store_state (List<Supravim.Plugin.PluginEntry> installed) {
		foreach (unowned var row in store_rows) {
			string? name = null;
			foreach (unowned var plugin in installed) {
				if (PluginCatalog.same_repo (plugin.url, row.url)) {
					name = plugin.name;
					break;
				}
			}
			row.set_installed (name != null, name);
		}
	}

	/**
	  * Load the plugins installed from Git repositories and refresh the
	  * store state accordingly.
	  */
	private async void load_external () throws Error {
		foreach (unowned var row in external_rows)
			external_group.remove (row);
		external_rows = new List<RowPluginExternal> ();

		var plugins = Supravim.Plugin.get_all ();
		foreach (var entry in plugins) {
			var row = new RowPluginExternal (entry.name, entry.enabled ? "Enable" : "Disable");
			row.refresh.connect (() => load_external.begin ());
			external_rows.append (row);
			external_group.add (row);
		}

		refresh_store_state (plugins);
	}

	/**
	  * Load the official plugins available through Suprapack.
	  */
	private async void load_plugins () throws Error {
		MatchInfo match_info;
		string output;
		yield Utils.run_async_command ("suprapack search_supravim_plugin", out output);
		var lines = output.split ("\n");
		foreach (unowned var line in lines) {
			bool installed = false;
			if (line.has_prefix ("[installed] ")) {
				installed = true;
				line = line.offset (12);
			}
			if (/plugin-(?P<name>[^ ]*) (?P<version>[^\s]+) \[(?P<lore>[^]]*)\]/.match (line, 0, out match_info)) {
				var name = match_info.fetch_named ("name");
				var version = match_info.fetch_named ("version");
				var lore = match_info.fetch_named ("lore");
				if (line.has_suffix ("[installed]"))
					installed = true;
				plugins_group.add (new PluginRow (name, version, lore, installed));
			}
		}
	}

	/**
	  * Class for the Popup Window to add a plugin
	  */
	public class WindowAddPlugin : DialogPopup {

		public signal void refresh ();

		private Gtk.Entry url_entry = new Gtk.Entry () {
			hexpand = true,
		};

		private Gtk.Button add_button = new Gtk.Button () {
			icon_name = "list-add-symbolic",
			width_request = 42,
			height_request = 42,
			css_classes = {"install"},
		};

		private void adding_plugin () {
			var regex = /https?:\/\/(www\.)?(github\.com|gitlab\.com)\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+(\/)?/;
			if (!regex.match (url_entry.text)) {
				var error_dialog = new DialogPopup (this.get_root () as Gtk.Window,
					"Invalid URL",
					"The URL provided is not a valid GitHub or GitLab repository URL."
				);
				error_dialog.add_cancel_button ();
				error_dialog.present ();
				return;
			}
			try {
				Supravim.Plugin.add (url_entry.text.strip ());
				this.close ();
				this.refresh ();
			} catch (Error e) {
				var error_dialog = new DialogPopup (this.get_root () as Gtk.Window,
					"Error Adding Plugin",
					Utils.remove_color (e.message)
				);
				error_dialog.add_cancel_button ();
				error_dialog.present ();
			}
		}

		public WindowAddPlugin (Gtk.Window mainWindow) {
			base (mainWindow,
				"Add an url github/gitlab",
"""To add an external plugin, please provide the URL to the plugin repository.
The plugin will be downloaded and installed automatically."""
			);
			url_entry.placeholder_text = "https://github.com/tpope/vim-fugitive";

			var box_url = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
			base.box_main.append (box_url);
			box_url.append (url_entry);
			box_url.append (add_button);

			add_button.clicked.connect (() => {
				adding_plugin ();
			});

			base.present ();
		}
	}
}
