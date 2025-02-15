private class RowOptions : Adw.ActionRow {
	
	uint source_id = 0;

	public RowOptions (string name, string lore, string value) {
		base.title = name;
		base.subtitle = lore;

		if (value.has_prefix ("'")) {
			_entry = new Gtk.Entry () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_entry.text = value[1:value.length - 1];
			base.add_suffix (_entry);
			_entry.changed.connect((v)=> {

				if (source_id != 0) {
					Source.remove (source_id);
				}

				source_id = GLib.Timeout.add (200, () => {
					var text = v.text.replace("'", "\\'");
					Utils.command_line(@"supravim -S $title=\"$(text)\"");
					print("onChangeOption: [%s] <%s>\n", title, text);
					source_id = 0;
					return false;
				});

			});
		}
		else {
			_switch = new Gtk.Switch () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			if (value == "on")
				_switch.state = true;
			base.add_suffix (_switch);
			init_event_switch ();
		}
	}

	void init_event_switch () {
		_switch.state_set.connect((v)=> {
			if (v == true) {
				Utils.command_line(@"supravim -e $title");
				print("onChangeOption: [%s] <true>\n", title);
			}
			else {
				Utils.command_line(@"supravim -d $title");
				print("onChangeOption: [%s] <false>\n", title);
			}
			_switch.state = v;
			return v;
		});
	}

	private Gtk.Switch _switch;
	private Gtk.Entry	_entry;
}

public class Options {
	public Options (Adw.PreferencesGroup options_group, Adw.PreferencesGroup options_group_pl) throws Error {
		this.options_group = options_group;
		this.options_group_pl = options_group_pl;
		foreach_status();
	}

	void foreach_status () throws Error {
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
				if (is_plugin_mode)
					options_group_pl.add (new RowOptions(name, lore ?? "No lore", @value));
				else
					options_group.add (new RowOptions(name, lore ?? "No lore", @value));
			}
		}

	}

	private unowned Adw.PreferencesGroup options_group;
	private unowned Adw.PreferencesGroup options_group_pl;
}
