/**
  * Main entry point of the application
  */
class Application : Adw.Application {

	construct {
		application_id = "org.supravim.gui";
	}

	public override void activate() {
		try {
			var provider = new Gtk.CssProvider();
			provider.load_from_resource("/ui/style.css");
			Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			var win = new MainWindow(this);
			win.present();
		} catch (Error e) {
			printerr(e.message);
		}
	}

	/**
	 * Pull updates from the supravim-gui git repository
	 * it's get the latest changes of the wikis
	 */
	private static void pull_updates() {
		try {
			unowned string HOME = Environment.get_home_dir();
			string path = HOME + "/.local/share/supravim-gui";
			Process.spawn_async(path, {"git", "pull"}, null, SEARCH_PATH, null, null);
		}
		catch (Error e) {
			printerr(e.message);
		}
	}

	public static void main(string []args) {
		pull_updates();
		new Application().run(args);
	}
}
