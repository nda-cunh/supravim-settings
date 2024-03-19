class ThemeButton : Gtk.ToggleButton {
	construct {
		css_classes = {"themebutton"};
		has_frame = false;
	}

	public ThemeButton (string name_theme) {
		name = name_theme;
		base.child = new Gtk.Picture.for_filename (@"/nfs/homes/nda-cunh/Pictures/Screenshots/$name_theme.png");
	}
}

class ThemeGrid : Gtk.Grid {
	construct {}
	public ThemeGrid () {
		string []tab_theme = { "dracula", "atom", "gruvbox", "iceberg",
				"molokai", "onedark", "onehalf", "pablo", "Tomorrow-Night"};
		tab_button = {};

		actual_theme = get_actual_theme ();
		foreach (var i in tab_theme) {
			var tmp = new ThemeButton (i);
			if (i == actual_theme)
				tmp.active = true;



			tmp.toggled.connect (()=> {
				if (tmp.active == false)
					return;
				print("%s\n", tmp.name);
				onThemeChange(tmp.name);
				foreach (var d in tab_button) {
					if (tmp.name != d.name) {
						d.set_active (false);
					}
				}
			});


			tab_button += tmp;
		}
		fill_grid ();
	}
	public signal void onThemeChange (string theme);

	string get_actual_theme () {
		try {
			string output;
			Process.spawn_command_line_sync (@"head -n 13 $(Environment.get_home_dir())/.vimrc", out output);
			string search = "g:sp_theme = '";
			unowned string begin = output.offset(output.index_of(search)+search.length);
			return begin[0:begin.index_of_char('\'')];
		} catch (Error e) {
			return "onehalf";
		}
	}

	void fill_grid () {
		var x = 0;
		var y = 0;
		while (x != tab_button.length) {
			base.attach (tab_button[x], x % 3, y);
			if (x % 3 == 2)
				y++;
			x++;
		}
	}
	string actual_theme;
	ThemeButton [] tab_button;
}

public class ThemeGroups : Gtk.Box{
	public ThemeGroups () {
		Object();
		var theme = new ThemeGrid();
		theme.onThemeChange.connect ((theme)=> {
			try {
				Process.spawn_command_line_sync (@"supravim --theme $theme");
			}catch (Error e) {
				printerr(e.message);
			}
		});

		base.append(theme);
	}
}
