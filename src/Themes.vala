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

		base.clicked.connect (()=> {
			if (active == false)
				active = true;
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
		// string []tab_theme = { "dracula", "atom", "gruvbox", "iceberg",
				// "molokai", "onedark", "pablo", "rosepine", "rosepine_moon", "kyotonight", "tokyonight", "tokyostorm",
		// "rosepine_dawn-light", "one-light", "iceberg-light"};
		tab_button = {};

string [] tab_theme = {"atom",
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
"rosepine_dawn-light",
"iceberg-light"};
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

	string get_actual_theme () {
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


private enum Colors {
	Dark,
	Light;

	unowned string to_string() {
		switch (this) {
			default:
			case Dark:
				return "dark";
			case Light:
				return "light";
		}
	}

	public static void change_theme (Colors color) throws Error {
		unowned var HOME = Environment.get_home_dir ();
		string vimrc;

		FileUtils.get_contents (@"$HOME/.vimrc", out vimrc);
		var regex = new Regex (@"^set background[=].*", RegexCompileFlags.MULTILINE);
		vimrc = regex.replace (vimrc, -1, 0, @"set background=$color");
		FileUtils.set_contents (@"$HOME/.vimrc", vimrc);
	}
}

public class ThemeGroups : Gtk.Box{
	public ThemeGroups () {
		Object();
		init_themes();
		var theme = new ThemeGrid();
		theme.onThemeChange.connect ((theme)=> {
			try {
				if (theme.index_of_char ('-') == -1){
					Process.spawn_command_line_sync (@"supravim --theme $theme");
					Colors.change_theme (Dark);
					print ("change_theme: [%s] <dark>\n", theme);
				}
				else {
					var named_theme = theme[0:theme.index_of_char('-')];
					Process.spawn_command_line_sync (@"supravim --theme $(named_theme)");
					Colors.change_theme (Light);
					print ("change_theme: [%s] <light>\n", named_theme);

				}
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
		tab_themes["pablo"] = new Color("pablo") {
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

		tab_themes["dracula"] = new Color("dracula") {
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
		
		tab_themes["iceberg"] = new Color("iceberg") {
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
		
		tab_themes["iceberg-light"] = new Color("iceberg-light") {
			background_color = {0.91, 0.91, 0.92},
			include = {0.17, 0.32, 0.62},
			stdio = {0.24, 0.51, 0.65},
			typedef = {0.17, 0.32, 0.62},
			struct = {0.17, 0.32, 0.62},
			type_s = {0.20, 0.21, 0.30},
			scope = {0.20, 0.21, 0.30},
			float = {0.28, 0.41, 0.66},
			function = {0.20, 0.21, 0.30},
			format = {0.43, 0.58, 0.28},
			text = {0.24, 0.51, 0.65},
			integer = {0.46, 0.34, 0.70}
		};
		
		tab_themes["onedark"] = new Color("onedark") {
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

		tab_themes["atom"] = new Color("atom") {
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

		tab_themes["molokai"] = new Color("molokai") {
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

		tab_themes["gruvbox"] = new Color("gruvbox") {
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

		tab_themes["one"] = new Color("onedark") {
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

		tab_themes["one-light"] = new Color("one-light") {
			background_color = {0.98, 0.98, 0.98},
			include = {0.65, 0.14, 0.65},
			stdio = {0.31, 0.63, 0.31},
			typedef = {0.75, 0.51, 0.04},
			struct = {0.65, 0.14, 0.65},
			type_s = {0.28, 0.29, 0.32},
			scope = {0.28, 0.29, 0.32},
			float = {0.65, 0.14, 0.65},
			function = {0.28, 0.29, 0.32},
			format = {0.04, 0.52, 0.74},
			text = {0.32, 0.63, 0.31},
			integer = {0.60, 0.40, 0.60}
		};

		tab_themes["kyotonight"] = new Color("kyotonight") {
			background_color = {0.10, 0.10, 0.14},
			include = {0.42, 0.69, 0.85},
			stdio = {0.45, 0.85, 0.79},
			typedef = {0.72, 0.59, 0.94},
			struct = {0.72, 0.59, 0.94},
			type_s = {0.39, 0.72, 0.68},
			scope = {0.28, 0.29, 0.32},
			float = {1.0, 0.62, 0.39},
			function = {0.28, 0.29, 0.32},
			format = {0.80, 0.63, 0.38},
			text = {0.62, 0.80, 0.41},
			integer = {1.0, 0.62, 0.39}
		};

		tab_themes["tokyonight"] = new Color("tokyonight") {
			background_color = {0.13, 0.13, 0.19},
			include = {0.93, 0.44, 0.53},
			stdio = {0.74, 0.58, 0.36},
			typedef = {0.47, 0.63, 0.96},
			struct = {0.47, 0.63, 0.96},
			type_s = {0.44, 0.59, 0.90},
			scope = {0.66, 0.69, 0.83},
			float = {0.67, 0.55, 0.90},
			function = {0.66, 0.69, 0.83},
			format = {0.62, 0.51, 0.83},
			text = {0.84, 0.66, 0.39},
			integer = {0.67, 0.55, 0.90}
		};

		tab_themes["tokyostorm"] = new Color("tokyostorm") {
			background_color = {0.14, 0.15, 0.23},
			include = {0.89, 0.43, 0.52},
			stdio = {0.87, 0.68, 0.40},
			typedef = {0.47, 0.63, 0.96},
			struct = {0.47, 0.62, 0.96},
			type_s = {0.44, 0.59, 0.90},
			scope = {0.66, 0.69, 0.83},
			float = {0.67, 0.55, 0.90},
			function = {0.66, 0.69, 0.83},
			format = {0.67, 0.55, 0.90},
			text = {0.87, 0.68, 0.40},
			integer = {0.67, 0.55, 0.90}
		};

		tab_themes["rosepine_moon"] = new Color("rosepine_moon") {
			background_color = {0.13, 0.12, 0.21}, // Base
			include = {0.72, 0.61, 0.85}, // Iris
			stdio = {0.96, 0.75, 0.56}, // Gold
			typedef = {0.61, 0.81, 0.84}, // Pine
			struct = {0.61, 0.81, 0.84}, // Pine
			type_s = {0.61, 0.81, 0.84}, // Pine
			scope = {1.0, 1.0, 1.0}, // White
			float = {0.61, 0.81, 0.84}, // Pine
			function = {1.0, 1.0, 1.0}, // White
			format = {0.91, 0.60, 0.59}, // Rose
			text = {0.96, 0.75, 0.56}, // Gold
			integer = {0.61, 0.81, 0.84}, // Pine
		};
		
		tab_themes["rosepine"] = new Color("rosepine") {
			background_color = {0.10, 0.09, 0.14}, // Base
			include = DataColor.rgb(196, 167, 231), // Iris
			stdio = DataColor.rgb(246, 193, 119), // Gold
			typedef = DataColor.rgb(156, 207, 216), // Foam
			struct = DataColor.rgb(156, 207, 216), // Foam
			type_s = DataColor.rgb(156, 207, 216), // Foam
			scope = DataColor.white,
			float = DataColor.rgb(156, 207, 216), // Foam
			function = DataColor.white, 
			format = DataColor.rgb(235, 188, 186), // Rose
			text = DataColor.rgb(246, 193, 119), // Gold 
			integer = DataColor.rgb(156, 207, 216), // Foam 
		};
		
		tab_themes["rosepine_dawn-light"] = new Color("rosepine_dawn-light") {
			background_color = DataColor.rgb(250, 244, 237), 
			include = DataColor.rgb(144, 122, 169),
			stdio = DataColor.rgb(234, 157, 52),
			typedef = DataColor.rgb(86, 148, 159),
			struct = DataColor.rgb(86, 148, 159),
			type_s = DataColor.rgb(86, 148, 159),
			scope = DataColor.rgb(87, 82, 121),
			float = DataColor.rgb(86, 148, 159),
			function = DataColor.rgb(121, 117, 147),
			format = DataColor.rgb(180, 99, 122),
			text = DataColor.rgb(234, 157, 52),
			integer = DataColor.rgb(86, 148, 159),
		};


}

