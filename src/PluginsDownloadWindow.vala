
private class PluginsDownloadWindow : Adw.Window {
	private Gtk.ProgressBar progress_bar;
	private Gtk.Label label_update = new Gtk.Label("");

	public PluginsDownloadWindow (Gtk.Window mainWindow) {
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
