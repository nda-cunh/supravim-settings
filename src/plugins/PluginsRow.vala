public class PluginRow : Adw.ActionRow {
	// Emitted after an install / uninstall completes so the page can reload.
	public signal void plugin_changed ();
	// Lowercased haystack used by the search filter.
	public string search_text;

	public PluginRow (owned string name, owned string version, owned string lore, bool installed) {
		this._name = name;
		this._version = version;
		base.title = _name;
		this._installed = installed;
		this.search_text = (name + " " + lore).down ();

		init_object ();

		base.subtitle = lore.replace("<", "[").replace(">", "]");
		base.add_suffix(new Gtk.Label(_version));
		var actions = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
		actions.set_margin_end (10);
		actions.set_valign (Gtk.Align.CENTER);
		actions.append(button);
		base.add_suffix(actions);
		
		button.clicked.connect (event_clicked);
		refresh_css ();
	}

	void event_clicked () {
		var window = base.get_root() as MainWindow;
		var popup = new PluginsDownloadWindow(window);
		if (_installed == true) {
			popup.execute.begin(@"suprapack uninstall 'plugin-$(_name)' --yes --simple-print", (obj, res) => {
				popup.close();
				if (popup.execute.end(res) == 0)
					_installed = false;
				refresh_css ();
				plugin_changed ();
			});
		}
		else {
			popup.execute.begin(@"suprapack install 'plugin-$(_name)' --yes --simple-print", (obj, res) => {
				popup.close();
				if (popup.execute.end(res) == 0)
					_installed = true;
				refresh_css ();
				plugin_changed ();
			});
		}
	}

	void refresh_css () {
		if (_installed == true)
			button.set_css_classes ({"uninstall"});
		else 
			button.set_css_classes ({""});
		if (_installed)
			image.icon_name = "user-trash-symbolic";
		else
			image.icon_name = "list-add-symbolic";

	}

	void init_object () {
		button = new Gtk.Button () {
			height_request = 25,
			width_request = 25,
			has_frame = false
		};
		button.set_cursor_from_name ("pointer");
		image = new Gtk.Image ();
		button.child = image;
	}

	private Gtk.Button button;
	private Gtk.Image image;
	private bool _installed;
	private string _name;
	private string _version;
}


