/**
 * Options supravim settings
 */
[GtkTemplate (ui = "/ui/options.ui")]
public class OptionsPage :  Gtk.Box { 
	// BluePrint Variable
	[GtkChild]
	private unowned Adw.PreferencesGroup options_group;
	[GtkChild]
	private unowned Adw.PreferencesGroup options_group_pl;

	public OptionsNode nodes_general = new OptionsNode();
	public OptionsNode nodes_plugin = new OptionsNode();

	construct {
		parse_status();
		nodes_plugin.display_tree ();
		add_options_to_group(nodes_general, options_group);
		add_options_to_group(nodes_plugin, options_group_pl);
	}

	/**
	  * recursively add options to the group
	  */
	private void add_options_to_group(OptionsNode node, Gtk.Widget row_base) {
		foreach (unowned var child in node) {
			if (child.children.length > 0) {
				var row = new Adw.ExpanderRow () {title = child.name};
				add_options_to_group(child, row);
				if (row_base is Adw.ExpanderRow)
					row_base.add_row (row);
				else if (row_base is Adw.PreferencesGroup)
					row_base.add (row);
			}
			else {
				if (row_base is Adw.ExpanderRow)
					row_base.add_row (new RowOptions(child.name, child.lore, child.value));
				else if (row_base is Adw.PreferencesGroup)
					row_base.add (new RowOptions(child.name, child.lore, child.value));
			}
		}
	}

	/**
	  * parse the supravim --status output
	  * and fill the options nodes (general and plugin)
	  */
	private void parse_status () {
		try {
			MatchInfo match_info;
			string output;
			Process.spawn_command_line_sync ("supravim -s", out output);
			var regex_color = new Regex("""\033\[[0-9;]*m""");

			bool is_plugin_mode = false;
			output = regex_color.replace(output, -1, 0, "");
			var regex_opts = /(?P<name>[^\s]+)\s*(?P<value>[^\s]+)(\s*[(](?P<lore>[^]]+)[)])?/;
			foreach (unowned var line in output.split ("\n")) {
				if (line == "" || line[0] == '-') {
					if (line == "-- PLUGINS --")
						is_plugin_mode = true;
					continue; 
				}
				if (regex_opts.match(line, 0, out match_info)) {
					var name = match_info.fetch_named ("name");
					if (name == "theme")
						continue;
					var @value = match_info.fetch_named ("value");
					var lore = match_info.fetch_named ("lore");
					if (!is_plugin_mode)
						nodes_general.append (name, lore ?? "No lore", @value);
					else
						nodes_plugin.append (name, lore ?? "No lore", @value);
				}
			}
		}
		catch (Error e) {
			warning (e.message);
		}
	}
}
