
public class WindowUpdate : DialogPopup {

	public WindowUpdate (Gtk.Window mainWindow) {
		base (mainWindow, "Update", "            Updating Supravim...            ");

		progress_bar.set_fraction(0.01);
		progress_bar.visible = true;
		update.begin(() => {
			Timeout.add(300, () => {
				base.close();
				return false;
			});
		});
		base.present();
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
					label_footer.set_text("Download");
				state = 1;
			}
			else if (line.has_prefix("install: [")) {
				line.scanf("install: [%d]", out progress);
				progress_bar.set_fraction(progress / 100.0);
				if (state != 2)
					label_footer.set_text("Install");
				state = 2;
			}
			else if (line.has_prefix("remove: [")) {
				line.scanf("remove: [%d]", out progress);
				progress_bar.set_fraction(progress / 100.0);
				if (state != 3)
					label_footer.set_text("Removing");
				state = 3;
			}
			Idle.add(update.callback);
			yield;
		}
		label_footer.set_text("Done");
	}
}

