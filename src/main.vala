class Application : Adw.Application {

	public Application() {
		Object(application_id: "org.supravim.gui");
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

	public static void main(string []args) {
		try {
			unowned string HOME = Environment.get_home_dir();
			Process.spawn_command_line_async(@"git pull $HOME/.local/share/supravim-gui");
		}
		catch (Error e) {
			printerr(e.message);
		}
		var app = new Application();
		app.run(null);
	}
}
