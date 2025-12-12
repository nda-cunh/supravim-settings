public class ThemeGrid : Gtk.Grid {
	public signal void onThemeChange (string theme);
	string actual_theme;
	private ThemeButton [] tab_button;

	construct {
		halign = Gtk.Align.CENTER;
		valign = Gtk.Align.CENTER;
		hexpand = true;

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
		actual_theme = get_actual_theme ();
		foreach (unowned var i in tab_theme) {
			var tmp = new ThemeButton (i);
			if (i == actual_theme)
				tmp.active = true;


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

	private string get_actual_theme () {
		try {
			unowned var HOME = Environment.get_home_dir ();
			const string search = "g:sp_theme = \"";
			string result;
			int index;
			string vimrc;

			FileUtils.get_contents (@"$HOME/.vimrc", out vimrc);
			index = vimrc.index_of(search);
			if (index == -1)
				throw new FileError.FAILED("");
			result = vimrc[index + search.length: vimrc.index_of_char('"', index + search.length)];
			if (vimrc.index_of("""set background=light""") != -1)
				result = result + "-light";

			return result;
		} catch (Error e) {
			warning (e.message);
			return "onedark";
		}
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
