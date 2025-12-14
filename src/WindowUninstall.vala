public class WindowUninstall: DialogPopup {

	public WindowUninstall (Gtk.Window mainWindow) {
		base (mainWindow, "Uninstall", "Are you sure you want to uninstall Supravim?");

		base.add_cancel_button();

		var uninstall_button = new Gtk.Button.with_label("Uninstall") {
			css_classes = {"destructive-action", "button_popup"},
		};
		
		uninstall_button.clicked.connect (() => {
			box_buttons.visible = false;
			progress_bar.visible = true;
			label_footer.visible = true;
			uninstall.begin (() => {
				Timeout.add(1000, () => {
					base.close();
					GLib.Application.get_default().quit();
					return false;
				});
			});
		});

		box_buttons.append(uninstall_button);

		progress_bar.visible = false;

		base.present ();
	}

	private async void uninstall () {
		try {
			var process = new Subprocess.newv({"suprapack", "remove", "supravim", "--simple-print"}, SubprocessFlags.SEARCH_PATH_FROM_ENVP + SubprocessFlags.STDOUT_PIPE);

			var stdout = process.get_stdout_pipe();
			var reader = new DataInputStream(stdout);
			int progress;
			string line;
			int state = 0;

			while ((line = reader.read_line(null)) != null) {
				print ("%s\n", line);
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
				Idle.add(uninstall.callback);
				yield;
			}
			label_footer.set_text("Done");
		}
		catch (Error e) {
			printerr ("Error: %s\n", e.message);
		}
	}
}
