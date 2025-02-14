
public class UpdateWindow : Adw.Window {

	private Gtk.ProgressBar progress_bar;
	private Gtk.Label label_update = new Gtk.Label("");

	public UpdateWindow (Gtk.Window mainWindow) {
		base.set_title("Update");
		base.set_default_size(400, 40);
		base.set_modal(true);
		base.set_transient_for(mainWindow);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
			margin_top = 10,
			margin_bottom = 10,
			margin_start = 10,
			margin_end = 10
		};
		progress_bar = new Gtk.ProgressBar(){
			inverted = false,
			show_text = true,
			valign = Gtk.Align.END,
		};

		with (box) {
			append (label_update);
			append (progress_bar);
		}
		progress_bar.set_fraction(0.01);
		base.set_content(box);
		update.begin(() => {
			Timeout.add(300, () => {
				base.close();
				return false;
			});
		});
		present();
	}

	private async void update() throws GLib.Error {
		var process = new Subprocess.newv({"suprapack", "update", "--yes", "--simple-print"}, SubprocessFlags.SEARCH_PATH_FROM_ENVP + SubprocessFlags.STDOUT_PIPE);

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
			Idle.add(update.callback);
			yield;
		}
		label_update.set_text("Done");
	}
}

