class RowOptions : Adw.ActionRow {
	public RowOptions (string name, string lore, string value) {
		base.title = name;
		base.subtitle = lore;

		_switch = new Gtk.Switch () {
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
		};
		if (value == "on")
			_switch.state = true;
		base.add_suffix (_switch);
		init_event ();
	}

	void init_event () {
		_switch.state_set.connect((v)=> {
			try {
				if (v == true)
					Process.spawn_command_line_sync (@"supravim -e $title");
				else
					Process.spawn_command_line_sync (@"supravim -d $title");
				_switch.state = v;
				} catch (Error e) {
					printerr(e.message);
				}
			return v;
		});
	}

	private Gtk.Switch _switch;
}

public class Options {
	public Options(Adw.PreferencesGroup options_group) throws Error {
		this.options_group = options_group;
		foreach_status();
	}

	void foreach_status () throws Error {
		MatchInfo match_info;
		string output;
		Process.spawn_command_line_sync ("supravim -s", out output);

		var regex_opts = /(?P<name>[^\s]+)\s*(?P<value>[^\s]+)(\s*[(](?P<lore>[^]]+)[)])?/;
		foreach (var line in output.split ("\n")) {
			line = new Regex("""\033\[[0-9;]*m""").replace(line, -1, 0, "");
			if (line == "" || line[0] == '-')
				continue; 
			if (regex_opts.match(line, 0, out match_info)) {
				var name = match_info.fetch_named ("name");
				if (name == "theme")
					continue;
				var @value = match_info.fetch_named ("value");
				var lore = match_info.fetch_named ("lore");
				options_group.add (new RowOptions(name, lore ?? "No lore", value));
			}
		}

	}
	unowned Adw.PreferencesGroup options_group;
}

