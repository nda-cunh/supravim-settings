public class WindowClearCache : DialogPopup {

	public WindowClearCache (Gtk.Window mainWindow) {
		base (mainWindow, "ClearCache", "Are you sure you want to clear vim undo cache?");

		base.add_cancel_button();

		var uninstall_button = new Gtk.Button.with_label("Clear cache") {
			css_classes = {"destructive-action", "button_popup"},
		};

		uninstall_button.clicked.connect (() => {
			unowned string _home = Environment.get_home_dir();
			Utils.command_line (@"/bin/rm -rf $(_home)/.cache/vim/undo/");
			DirUtils.create (@"$(_home)/.cache/vim/undo/", 0755);
			base.close();
		});

		box_buttons.append(uninstall_button);

		base.present ();
	}
}
