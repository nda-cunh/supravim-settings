public class ThemeGrid : Gtk.Grid {
	public signal void onThemeChange (string theme);
	private ThemeButton [] tab_button;

	construct {
		halign = Gtk.Align.CENTER;
		valign = Gtk.Align.CENTER;
		hexpand = true;

	}

	public void change_theme (string theme) {
		foreach (unowned var d in tab_button) {
			if (theme == d.name)
				d.set_active (true);
			else
				d.set_active (false);
		}
	}

	public ThemeGrid () {
		tab_button = {};
		const string [] tab_theme = {
"atom",
"dracula",
"gruvbox",
"iceberg",
"pablo",
"kyotonight",
"molokai",
"onedark",
"tokyonight",
"tokyostorm",
"rosepine",
"rosepine_moon",
"catppuccin_frappe",
"catppuccin_macchiato",
"catppuccin_mocha",
"rosepine_dawn-light",
"iceberg-light",
"catppuccin_latte"
};
		foreach (unowned var i in tab_theme) {
			var tmp = new ThemeButton (i);

			tmp.toggled.connect (()=> {
				if (tmp.active == false)
					return;
				print("%s\n", tmp.name);
				onThemeChange(tmp.name);
				foreach (unowned var d in tab_button) {
					if (tmp.name != d.name) {
						d.set_active (false);
					}
				}
			});


			tab_button += tmp;
		}
		fill_grid ();
	}

	private void fill_grid () {
		var x = 0;
		var y = 0;
		while (x != tab_button.length) {
			base.attach (tab_button[x], x % 3, y);
			if (x % 3 == 2)
				y++;
			x++;
		}
	}

}
