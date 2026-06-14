/**
 * True when the GUI was launched from within VIM (via the `--from-supravim` flag).
 * In that case option/theme changes are streamed to VIM through stdout prints and
 * VIM takes care of persisting them. Otherwise (launched from the GNOME menu or the
 * command line directly) we apply the changes ourselves through the libsupravim API.
 */
bool from_supravim = false;

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
		Supravim.init ();
		set_print_handler((msg) => {
			stdout.puts(msg);
			stdout.flush();
		});

		// Strip our custom flag before handing the args to GApplication, which
		// would otherwise reject the unknown option.
		string[] filtered = {};
		foreach (unowned string arg in args) {
			if (arg == "--from-supravim")
				from_supravim = true;
			else
				filtered += arg;
		}

		pull_updates();
		new Application().run(filtered);
	}
}
