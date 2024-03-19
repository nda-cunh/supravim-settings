public class Plugins {
	public Plugins (Adw.PreferencesGroup plugins_group) throws Error {
		this.plugins_group = plugins_group;

		MatchInfo match_info;
		string output;
		Process.spawn_command_line_sync("suprapack search_supravim_plugin", out output);
		var lines = output.split("\n");
		foreach (var line in lines) {
			bool installed = false;
			if (line.has_prefix ("[installed] ")) {
				installed = true;
				line = line.offset(12);
			}
			print("%s\n", line);
			if (/plugin-(?P<name>[^ ]*) (?P<version>[^\s]+) \[(?P<lore>[^]]*)\]/.match(line, 0, out match_info)) {
				var name = match_info.fetch_named("name");
				var version = match_info.fetch_named("version");
				var lore = match_info.fetch_named("lore");
				if (line.has_suffix("[installed]"))
					installed = true;
				plugins_group.add (new RowPlugin(name, version, lore, installed));
			}
		}
	}
	public unowned Adw.PreferencesGroup plugins_group;
}

class RowPlugin : Adw.ActionRow {
	public RowPlugin (string name, string version, string lore, bool installed) {
		this._name = name;
		this._version = version; 
		this._installed = installed;

		init_object ();

		base.title = _name;
		base.subtitle = lore.replace("<", "[").replace(">", "]");
		base.add_suffix(new Gtk.Label(_version));
		var actions = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		actions.set_margin_end (10);
		actions.set_valign (Gtk.Align.CENTER);
		actions.append(button);
		base.add_suffix(actions);
		
		button.clicked.connect (event_clicked);
		refresh_css ();
	}

	void event_clicked () {
		int status;

		try {

			if (_installed == true) {
				Process.spawn_command_line_sync (@"suprapack --force uninstall plugin-$(_name)", null, null, out status);
				if (status == 0) {
					_installed = false;
				}
			}
			else {
				Process.spawn_command_line_sync (@"suprapack --force install plugin-$(_name)", null, null, out status);
				if (status == 0) {
					_installed = true;
				}
			}
		} catch (Error e) {
			printerr(e.message);
		}
		refresh_css ();
	}

	void refresh_css () {
		if (_installed == true)
			button.set_css_classes ({"uninstall"});
		else 
			button.set_css_classes ({"install"});
		if (_installed)
			image.icon_name = "user-trash-symbolic";
		else
			image.icon_name = "list-add-symbolic";

	}

	void init_object () {
		button = new Gtk.Button () {
			height_request = 25,
			width_request = 25,
			has_frame = false
		};
		button.set_cursor_from_name ("pointer");
		image = new Gtk.Image ();
		button.child = image;
	}

	private Gtk.Button button;
	private Gtk.Image image;
	private bool _installed;
	private string _name;
	private string _version;
}

