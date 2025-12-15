
[GtkTemplate (ui = "/ui/plugins.ui")]
public class PluginsPage : Gtk.Box {
	construct {
		load_plugins.begin();
		load_external.begin();
		var a = new RowAddPlugin();
		external_group.add (a);
		a.new_plugin.connect(() => {
			print ("New plugin clicked A\n");
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
}
