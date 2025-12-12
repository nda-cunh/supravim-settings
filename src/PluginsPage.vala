
[GtkTemplate (ui = "/ui/plugins.ui")]
public class PluginsPage : Gtk.Box {
	construct {

		MatchInfo match_info;
		string output;
		Process.spawn_command_line_sync("suprapack search_supravim_plugin", out output);
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
	[GtkChild]
	public unowned Adw.PreferencesGroup plugins_group;
}
