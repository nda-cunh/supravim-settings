
[GtkTemplate (ui = "/ui/plugins.ui")]
public class PluginsPage : Gtk.Box {

	[GtkChild]
	public unowned Gtk.Button btn_add_plugin;

	construct {
		load_plugins.begin();
		load_external.begin();
		btn_add_plugin.clicked.connect(() => {
			var parent = this.get_root() as Gtk.Window;
			var dialog = new WindowAddPlugin(parent);
			dialog.present ();
		});
	}

	private async void load_plugins() throws Error {
		MatchInfo match_info;
		string output;
		yield Utils.run_async_command("suprapack search_supravim_plugin", out output);
		var lines = output.split("\n");
		foreach (unowned var line in lines) {
			bool installed = false;
			if (line.has_prefix ("[installed] ")) {
				installed = true;
				line = line.offset(12);
			}
			if (/plugin-(?P<name>[^ ]*) (?P<version>[^\s]+) \[(?P<lore>[^]]*)\]/.match(line, 0, out match_info)) {
				var name = match_info.fetch_named("name");
				var version = match_info.fetch_named("version");
				var lore = match_info.fetch_named("lore");
				if (line.has_suffix("[installed]"))
					installed = true;
				plugins_group.add (new PluginRow(name, version, lore, installed));
			}
		}
	}

	private async void load_external() throws Error {
		foreach (unowned var row in external_rows) {
			external_group.remove (row);
		}
		// MatchInfo match_info;
		MatchInfo match_info;
		string output;
		yield Utils.run_async_command("supravim --list-plugin", out output);
		output = Utils.remove_color(output);
		var lines = output.split("\n");
		foreach (unowned var line in lines) {
			bool installed = false;
			if (line.has_prefix ("[installed] ")) {
				installed = true;
				line = line.offset(12);
			}
			if (/(?P<name>[\S]+)\s+(?P<status>[\S]+)/.match(line, 0, out match_info)) {
				var name = match_info.fetch_named("name");
				var status = match_info.fetch_named("status");
				var row = new RowPluginExternal(name, status);
				row.refresh.connect(() => {
					print ("Refresh external plugins\n");
					load_external.begin();
				});
				external_rows.append(row);
				external_group.add (row);
			}
		}
	}
	private List<RowPluginExternal> external_rows = new List<RowPluginExternal>();

	[GtkChild]
	public unowned Adw.PreferencesGroup plugins_group;
	[GtkChild]
	public unowned Adw.PreferencesGroup external_group;

	/**
	  * Class for the Popup Window to add a plugin 
	  */
	public class WindowAddPlugin : DialogPopup {

		/**
		  * Attributes
		  */
		private Gtk.Entry url_entry = new Gtk.Entry() {
			hexpand = true,
		};

		private Gtk.Button add_button = new Gtk.Button() {
			icon_name = "list-add-symbolic",
			width_request = 42,
			height_request = 42,
			css_classes = {"install"},
		};

		/**
		  * Methods
		  */
		private void adding_plugin() {
			var regex = /https?:\/\/(www\.)?(github\.com|gitlab\.com)\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+(\/)?/; 
			if (!regex.match(url_entry.text)) {
				var error_dialog = new DialogPopup (this.get_root() as Gtk.Window,
					"Invalid URL",
					"The URL provided is not a valid GitHub or GitLab repository URL."
				);
				error_dialog.add_cancel_button();
				error_dialog.present ();
				return;
			}
			else {
				string errput;
				var url_pl = url_entry.text.strip();
				if (Utils.command_line("supravim --add-plugin " + url_pl, null, out errput) != 0) {
					errput = Utils.remove_color(errput);
					var error_dialog = new DialogPopup (this.get_root() as Gtk.Window,
						"Error Adding Plugin",
						errput
					);
					error_dialog.add_cancel_button();
					error_dialog.present ();
					return;
				}
				else {
					this.close();
					// Refresh the external plugins list
					var parent = this.get_root() as Gtk.Window;
					var plugins_page = parent.get_child() as PluginsPage;
					plugins_page.load_external.begin();
				}
			}
		}
		
		public WindowAddPlugin (Gtk.Window mainWindow) {
			base (mainWindow,
				"Add an url github/gitlab",
"""To add an external plugin, please provide the URL to the plugin repository.
The plugin will be downloaded and installed automatically."""
			);
			url_entry.placeholder_text = "https://github.com/tpope/vim-fugitive";

			var box_url = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
			base.box_main.append(box_url);
			box_url.append(url_entry);
			box_url.append(add_button);

			add_button.clicked.connect(() => {
				adding_plugin();
			});

			base.present();
		}

		private void append_cancel_button () {
			var cancel_button = new Gtk.Button.with_label("Cancel") {
				css_classes = {"button_popup"},
			};
			cancel_button.clicked.connect (() => base.close());
			box_main.append(cancel_button);
		}
	}
}
