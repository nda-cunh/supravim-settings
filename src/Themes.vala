private HashTable<string, Color> tab_themes;

class ThemeButton : Gtk.ToggleButton {
	construct {
		css_classes = {"themebutton"};
		has_frame = false;
		base.notify["active"].connect (()=>{
			Color color = base.child as Color;
			color.active = active;
			color.queue_draw ();
		});

	}

	public ThemeButton (string name_theme) {
		name = name_theme;
		base.child = tab_themes[name_theme] ;

	}


}

class ThemeGrid : Gtk.Grid {
	public signal void onThemeChange (string theme);
	string actual_theme;
	private ThemeButton [] tab_button;

	construct {
		halign = Gtk.Align.CENTER;
		valign = Gtk.Align.CENTER;
		hexpand = true;

	}

	public ThemeGrid () {
		string []tab_theme = { "dracula", "atom", "gruvbox", "iceberg",
				"molokai", "onehalf", "pablo"};
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

}

public class ThemeGroups : Gtk.Box{
	public ThemeGroups () {
		Object();
		init_themes();
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






/*********************************************************/
/************************* Theme *************************/
/*********************************************************/


private void init_themes() {
	tab_themes = new HashTable<string, Color> (str_hash, str_equal);
		tab_themes["pablo"] = new Color() {
			background_color = {0.0, 0.0, 0.0},
			include = {0.0, 0.74, 0.0},
			stdio = {0.0, 0.94, 0.94},
			typedef = {0.0, 0.44, 0.0},
			struct = {0.0, 0.44, 0.0},
			type_s = {1.0, 1.0, 1.0},
			scope = {1.0, 1.0, 1.0},
			float = {0.0, 0.44, 0.0},
			function = {1.0, 1.0, 1.0},
			format = {0.0, 0.0, 0.90},
			text = {0.0, 0.94, 0.94},
			integer = {0.0, 0.94, 0.94},
		};

		tab_themes["dracula"] = new Color() {
			background_color = {0.11, 0.11, 0.11},
			include = {0.86, 0.42, 0.67},
			stdio = {0.94, 0.98, 0.54},
			typedef = {0.86, 0.42, 0.67},
			struct = {0.86, 0.42, 0.67},
			type_s = {1.0, 1.0, 1.0},
			scope = {1.0, 1.0, 1.0},
			float = {0.50, 0.84, 0.91},
			function = {1.0, 1.0, 1.0},
			format = {0.86, 0.42, 0.67},
			text = {0.94, 0.98, 0.54},
			integer = {0.73, 0.57, 0.97}
		};
		
		tab_themes["iceberg"] = new Color() {
			background_color = {0.08, 0.09, 0.12},
			include = {0.51, 0.62, 0.77},
			stdio = {0.49, 0.65, 0.68},
			typedef= {0.51, 0.62, 0.77},
			struct = {0.51, 0.62, 0.77},
			type_s = {0.80, 0.80, 0.80},
			scope = {0.80, 0.80, 0.80},
			float = {0.50, 0.84, 0.91},
			function = {1.0, 1.0, 1.0},
			format = {0.64, 0.67, 0.47},
			text = {0.49, 0.65, 0.68},
			integer = {0.45, 0.42, 0.55}
		};
		
		tab_themes["onehalf"] = new Color() {
			background_color = {0.15, 0.17, 0.20},
			include = {0.38, 0.68, 0.93},
			stdio = {0.56, 0.76, 0.47},
			typedef = {0.89, 0.75, 0.48},
			struct = {0.89, 0.75, 0.48},
			type_s = {0.67, 0.69, 0.75},
			scope = {0.80, 0.80, 0.80},
			float = {0.89, 0.75, 0.48},
			function = {0.67, 0.69, 0.75},
			format = {0.82, 0.60, 0.40},
			text = {0.56, 0.76, 0.47},
			integer = {0.82, 0.60, 0.40},
		};

		//atom

		tab_themes["atom"] = new Color() {
			background_color = {0.11, 0.12, 0.13},
			include = {0.85, 0.81, 0.52},
			stdio = {0.65, 1.0, 0.37},
			typedef = {0.40, 0.82, 0.93},
			struct= {0.40, 0.82, 0.93},
			type_s = {1.0, 1.0, 1.0},
			scope = {1.0, 1.0, 1.0},
			float = {0.40, 0.82, 0.93},
			function = {1.0, 1.0, 1.0},
			format = {0.57, 0.77, 0.96},
			text = {0.65, 1.0, 0.37},
			integer = {0.60, 0.80, 0.60},
		};
	
		//molokai

		tab_themes["molokai"] = new Color() {
			background_color = {0.10, 0.11, 0.12},
			include = {0.65, 0.88, 0.18},
			stdio = {0.90, 0.85, 0.45},
			typedef = {0.40, 0.85, 0.93},
			struct = {0.40, 0.85, 0.93},
			type_s = {1.0, 1.0, 1.0},
			scope = {1.0, 1.0, 1.0},
			float = {0.40, 0.85, 0.93},
			function = {1.0, 1.0, 1.0},
			format = {0.97, 0.14, 0.44},
			text = {0.90, 0.85, 0.45},
			integer = {0.68, 0.50, 1.0}
		};

		tab_themes["gruvbox"] = new Color() {
			background_color = {0.15, 0.15, 0.15},
			include = {0.55, 0.75, 0.48},
			stdio = {0.72, 0.73, 0.14},
			typedef = {0.99, 0.50, 0.09},
			struct = {0.86, 0.42, 0.67},
			type_s = {0.92, 0.85, 0.70},
			scope = {0.92, 0.85, 0.70},
			float = {0.50, 0.84, 0.91},
			function = {0.92, 0.85, 0.70},
			format = {0.99, 0.50, 0.09},
			text = {0.72, 0.73, 0.14},
			integer = {0.82, 0.52, 0.60}
		};

}

