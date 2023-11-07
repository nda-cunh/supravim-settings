public string HOME;

public class Supravim : Adw.Application {
	public Supravim () {
		Object (application_id: "com.example.supravim");
	}

	public override void activate () {
		var win = new Adw.ApplicationWindow (this) {
			default_height=500,
			default_width=400
		};
		var provider = new Gtk.CssProvider();
		provider.load_from_data(css.data);
		Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, 0);

		var body = new Body();
		
		win.content = body;
		win.present ();
	}

	public static int main (string[] args) {
		print("%s\n", Adw.VERSION_S);
		HOME = Environment.get_home_dir();
		var app = new Supravim ();
		return app.run (args);
	}
}

public const string css = """
.stack {
	padding:25px;
}
""";
