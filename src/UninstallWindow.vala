public class UninstallWindow : Adw.Window {

	Gtk.ProgressBar progress_bar = new Gtk.ProgressBar();
	Gtk.Label label_update = new Gtk.Label("Preparing to uninstall...");

	public UninstallWindow (Gtk.Window mainWindow) {
		base.set_default_size(-1, -1);
		base.set_modal(true);
		base.set_transient_for(mainWindow);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
			margin_top = 20,
			margin_bottom = 10,
			margin_start = 20,
			margin_end = 20,
			spacing = 20,
		};

		box.append(new Gtk.Label("<b>Are you sure you want to uninstall Supravim?</b>") {
			use_markup = true,
		});

		var box_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
			margin_top = 10,
			margin_bottom = 10,
			margin_start = 10,
			margin_end = 10,
			homogeneous = true,
			hexpand = true,
			spacing = 40,
		};

		var cancel_button = new Gtk.Button.with_label("Cancel") {
			css_classes = {"button_popup"},
		};
		cancel_button.clicked.connect (() => {
			base.close();
		});

		var uninstall_button = new Gtk.Button.with_label("Uninstall") {
			css_classes = {"destructive-action", "button_popup"},
		};
		
		uninstall_button.clicked.connect (() => {
			box_buttons.visible = false;
			progress_bar.visible = true;
			label_update.visible = true;
			uninstall.begin (() => {
				Timeout.add(1000, () => {
					base.close();
					GLib.Application.get_default().quit();
					return false;
				});
			});
		});

		box_buttons.append(cancel_button);
		box_buttons.append(uninstall_button);

		box.append(label_update);
		box.append(progress_bar);
		label_update.visible = false;
		progress_bar.visible = false;

		box.append(box_buttons);


		content = box;
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
				Idle.add(uninstall.callback);
				yield;
			}
			label_update.set_text("Done");
		}
		catch (Error e) {
			printerr ("Error: %s\n", e.message);
		}
	}
}
