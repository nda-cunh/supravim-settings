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
		flags = ApplicationFlags.HANDLES_COMMAND_LINE;
	}

	public override void startup() {
		base.startup();
	}

	public override int command_line(GLib.ApplicationCommandLine command_line) {
		foreach (unowned string arg in command_line.get_arguments()) {
			if (arg == "--from-supravim")
				from_supravim = true;
		}

		this.activate();
		return 0;
	}

	public override void activate() {
		var win = this.active_window;
		if (win == null) {
			foreach (var w in this.get_windows()) {
				win = w;
				break;
			}
		}
		if (win != null) {
			win.present();
			return;
		}

		try {
			Adw.StyleManager.get_default().color_scheme = Adw.ColorScheme.FORCE_DARK;
			var provider = new Gtk.CssProvider();
			provider.load_from_resource("/ui/style.css");
			Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
			var window = new MainWindow(this);
			window.present();
		} catch (Error e) {
			printerr(e.message);
		}
	}

	private static string find_localedir () {
		try {
			string exe = FileUtils.read_link ("/proc/self/exe");
			string prefix = Path.get_dirname (Path.get_dirname (exe));
			string dir = Path.build_filename (prefix, "share", "locale");
			if (FileUtils.test (dir, FileTest.IS_DIR))
				return dir;
		}
		catch (Error e) {
		}
		return Config.LOCALEDIR;
	}

	public static void main(string []args) {
		Intl.setlocale ();
		Intl.bindtextdomain (Config.GETTEXT_PACKAGE, find_localedir ());
		Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
		Intl.textdomain (Config.GETTEXT_PACKAGE);

		Supravim.init ();
		Intl.textdomain (Config.GETTEXT_PACKAGE);
		set_print_handler((msg) => {
			stdout.puts(msg);
			stdout.flush();
		});

		new Application().run(args);
	}
}
