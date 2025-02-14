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

		content = box;

		base.present ();
	}
}
