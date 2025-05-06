public class Plugins {
	public Plugins (Adw.PreferencesGroup plugins_group) throws Error {
		this.plugins_group = plugins_group;

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
				plugins_group.add (new RowPlugin(name, version, lore, installed));
			}
		}
	}
	public unowned Adw.PreferencesGroup plugins_group;
}


class RowPlugin : Adw.ActionRow {
	public RowPlugin (owned string name, owned string version, owned string lore, bool installed) {
		this._name = name;
		this._version = version; 
		base.title = _name;
		this._installed = installed;

		init_object ();

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
		var window = base.get_root() as MainWindow;
		var popup = new DownloadWindow(window);
		if (_installed == true) {
			popup.execute.begin(@"suprapack uninstall 'plugin-$(_name)' --yes --simple-print", (obj, res) => {
				popup.close();
				if (popup.execute.end(res) == 0)
					_installed = false;
				refresh_css ();
			});
		}
		else {
			popup.execute.begin(@"suprapack install 'plugin-$(_name)' --yes --simple-print", (obj, res) => {
				popup.close();
				if (popup.execute.end(res) == 0)
					_installed = true;
				refresh_css ();
			});
		}
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


private class DownloadWindow : Adw.Window {
	private Gtk.ProgressBar progress_bar;
	private Gtk.Label label_update = new Gtk.Label("");

	public DownloadWindow (Gtk.Window mainWindow) {
		this.title = "Download Plugins";
		this.set_default_size (-1, -1);
		this.set_resizable (true);
		this.set_modal (true);
		base.set_transient_for(mainWindow);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
			margin_top = 10,
			margin_bottom = 10,
			margin_start = 10,
			margin_end = 10
		};
		progress_bar = new Gtk.ProgressBar();
		box.append(label_update);
		box.append(progress_bar);

		content = box;
		base.present ();
	}

	public async int execute (string command) {
		string[] args;
		try {
			Shell.parse_argv (command, out args);
			var process = new Subprocess.newv(args,
				SubprocessFlags.SEARCH_PATH_FROM_ENVP + SubprocessFlags.STDOUT_PIPE);

			var stdout = process.get_stdout_pipe();
			var reader = new DataInputStream(stdout);
			int progress;
			string line;
			int state = 0;

			while ((line = reader.read_line(null)) != null) {
				if (line.has_prefix("download: [")) {
					line.scanf("download: [%d]", out progress);
					progress_bar.set_fraction(progress / 100.0);
					if (state != 1)
						label_update.set_text("Download");
					state = 1;
				}
				else if (line.has_prefix("install: [")) {
					line.scanf("install: [%d]", out progress);
					progress_bar.set_fraction(progress / 100.0);
					if (state != 2)
						label_update.set_text("Install");
					state = 2;
				}
				else if (line.has_prefix("remove: [")) {
					line.scanf("remove: [%d]", out progress);
					progress_bar.set_fraction(progress / 100.0);
					if (state != 3)
						label_update.set_text("Removing");
					state = 3;
				}
				Idle.add(execute.callback);
				yield;
			}
			label_update.set_text("Done");
			process.wait(null);
			return process.get_status ();
		}
		catch (Error e) {
			printerr(e.message);
			Process.exit (1);
		}
	}
}

