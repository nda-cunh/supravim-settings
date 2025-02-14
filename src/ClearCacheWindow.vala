public class ClearCacheWindow : Adw.Window {


	public ClearCacheWindow (Gtk.Window mainWindow) {
		base.set_title("ClearCache");
		base.set_default_size(400, 40);
		base.set_modal(true);
		base.set_transient_for(mainWindow);

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0) {
			margin_top = 10,
			margin_bottom = 10,
			margin_start = 10,
			margin_end = 10
		};

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

		var uninstall_button = new Gtk.Button.with_label("clear UNDODIR") {
			css_classes = {"destructive-action", "button_popup"},
		};

		uninstall_button.clicked.connect (() => {
			try {
				unowned string _home = Environment.get_home_dir();
				Process.spawn_command_line_sync (@"/bin/rm -rf $(_home)/.cache/vim/undo/");
				DirUtils.create (@"$(_home)/.cache/vim/undo/", 0755);
			}
			catch (Error e) {
				printerr ("Error: %s\n", e.message);
			}
			base.close();
		});

		box_buttons.append(cancel_button);
		box_buttons.append(uninstall_button);

		box.append(box_buttons);
		content = box;

		base.present ();
	}
}
