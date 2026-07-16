
[GtkTemplate (ui = "/ui/plugins.ui")]
public class PluginsPage : Gtk.Box {

	[GtkChild]
	public unowned Gtk.SearchEntry search_entry;
	[GtkChild]
	public unowned Gtk.DropDown category_dropdown;
	// Discover (one unified catalog)
	[GtkChild]
	public unowned Adw.PreferencesGroup store_group;
	// Installed
	[GtkChild]
	public unowned Adw.PreferencesGroup external_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup suprapack_installed_group;

	private List<PluginStoreRow> store_rows = new List<PluginStoreRow> ();
	private List<RowPluginExternal> external_rows = new List<RowPluginExternal> ();
	private List<PluginRow> suprapack_installed_rows = new List<PluginRow> ();

	// Category names, index aligned with the dropdown model (index 0 = "All").
	private string[] categories = {};

	private bool loaded = false;

	construct {
	}

	/** Build the catalog and installed-state the first time the page shows. */
	public void ensure_loaded () {
		if (loaded)
			return;
		loaded = true;
		build_store.begin ();
	}

	/* ----------------------------- Callbacks ----------------------------- */

	[GtkCallback]
	public void on_add_plugin () {
		var parent = this.get_root () as Gtk.Window;
		var dialog = new WindowAddPlugin (parent);
		dialog.refresh.connect (() => refresh.begin ());
		dialog.present ();
	}

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
		refresh.begin ();
	}

	[GtkCallback]
	public void on_search_changed () {
		apply_filter ();
	}

	[GtkCallback]
	public void on_category_changed () {
		apply_filter ();
	}

	/* ------------------------------ Filtering ---------------------------- */

	private string? selected_category () {
		var sel = category_dropdown.selected;
		if (sel == 0 || sel >= categories.length)
			return null; // "All categories"
		return categories[sel];
	}

	private void apply_filter () {
		var query = search_entry.text.strip ().down ();
		var category = selected_category ();

		uint visible = 0;
		foreach (unowned var row in store_rows) {
			bool match_cat = (category == null || row.category == category);
			bool match_query = (query == "" || row.search_text.contains (query));
			row.visible = match_cat && match_query;
			if (row.visible)
				visible++;
		}

		// Live count in the store header.
		if (query == "" && category == null)
			store_group.description = "%u plugins available — install in one click".printf (store_rows.length ());
		else if (visible == 1)
			store_group.description = "1 plugin found";
		else
			store_group.description = "%u plugins found".printf (visible);
	}

	/* -------------------------------- Store ------------------------------ */

	private const uint STORE_BATCH = 12;

	private async void build_store () {
		var entries = PluginCatalog.load ();

		// Collect the distinct categories for the dropdown filter.
		var found = new GenericArray<string> ();
		foreach (unowned var entry in entries) {
			bool seen = false;
			for (uint i = 0; i < found.length; i++)
				if (found[i] == entry.category) { seen = true; break; }
			if (!seen)
				found.add (entry.category);
		}
		found.sort ((a, b) => strcmp (a, b));

		categories = new string[found.length + 1];
		categories[0] = "All categories";
		var model = new Gtk.StringList (null);
		model.append ("All categories");
		for (uint i = 0; i < found.length; i++) {
			categories[i + 1] = found[i];
			model.append (found[i]);
		}
		category_dropdown.model = model;

		uint n = 0;
		foreach (unowned var entry in entries) {
			var row = new PluginStoreRow (entry);
			row.plugin_changed.connect (() => refresh.begin ());
			store_rows.append (row);
			store_group.add (row);

			if (++n % STORE_BATCH == 0) {
				apply_filter ();
				Idle.add (build_store.callback);
				yield;
			}
		}

		apply_filter ();

		try {
			yield refresh ();
		} catch (Error e) {
			warning ("Failed to refresh plugins: %s", e.message);
		}
	}

	/* ------------------------------ Refresh ------------------------------ */

	/**
	  * Single source of truth: gather the installed state from both backends
	  * (libsupravim git plugins + suprapack packages), update every store row
	  * and rebuild the "Installed" view.
	  */
	private async void refresh () throws Error {
		// Reset the installed view.
		foreach (unowned var row in external_rows)
			external_group.remove (row);
		foreach (unowned var row in suprapack_installed_rows)
			suprapack_installed_group.remove (row);
		external_rows = new List<RowPluginExternal> ();
		suprapack_installed_rows = new List<PluginRow> ();

		// --- Git plugins (libsupravim) ---
		var git_plugins = Supravim.Plugin.get_all ();
		foreach (var entry in git_plugins) {
			var row = new RowPluginExternal (entry);
			row.refresh.connect (() => refresh.begin ());
			external_rows.append (row);
			external_group.add (row);
		}

		// --- Suprapack packages ---
		var sp_installed = new GenericArray<string> ();
		// Descriptions provided by suprapack itself (package name -> lore).
		var sp_lore = new HashTable<string, string> (str_hash, str_equal);
		MatchInfo match_info;
		string output;
		yield Utils.run_async_command ("suprapack search_supravim_plugin", out output);
		foreach (unowned var line in output.split ("\n")) {
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

				if (lore != null && lore != "")
					sp_lore.insert (name, lore);

				if (installed) {
					sp_installed.add (name);
					var irow = new PluginRow (name, version, lore, true);
					irow.plugin_changed.connect (() => refresh.begin ());
					suprapack_installed_rows.append (irow);
					suprapack_installed_group.add (irow);
				}
			}
		}

		// --- Update the unified store rows from both backends ---
		foreach (unowned var row in store_rows) {
			if (row.is_suprapack) {
				bool inst = false;
				for (uint i = 0; i < sp_installed.length; i++)
					if (sp_installed[i] == row.suprapack) { inst = true; break; }
				row.set_installed (inst, row.suprapack);
				// Prefer the description suprapack provides over the catalog one.
				var lore = sp_lore.lookup (row.suprapack);
				if (lore != null)
					row.set_description (lore);
			}
			else {
				string? name = null;
				foreach (unowned var plugin in git_plugins) {
					if (PluginCatalog.same_repo (plugin.url, row.url)) {
						name = plugin.name;
						break;
					}
				}
				row.set_installed (name != null, name);
			}
		}

		apply_filter ();
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
				Utils.ach_plugin_install (url_entry.text.strip ());
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
