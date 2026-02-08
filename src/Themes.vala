public HashTable<string, Color> tab_themes;

[GtkTemplate (ui = "/ui/theme.ui")]
public class ThemePage : Adw.PreferencesGroup {
	[GtkChild]
	private unowned Gtk.Box box;

	construct {
		init_themes();
		var theme = new ThemeGrid();
		theme.onThemeChange.connect ((theme)=> {
			try {
				if (theme.index_of_char ('-') == -1){
					// Process.spawn_command_line_sync (@"supravim --theme $theme");
					// Colors.change_theme (Dark);
					// print ("change_theme: [%s] <dark>\n", theme);
					// Utils.command_line(@"supravim -S $(node.real_name)=$(int.parse(v.text))");
					print("onChangeOption: [theme] <%s>\n", theme);

				}
				else {
					var named_theme = theme[0:theme.index_of_char('-')];
					// Process.spawn_command_line_sync (@"supravim --theme $(named_theme)");
					// Colors.change_theme (Light);
					// print ("change_theme: [%s] <light>\n", named_theme);
					print("onChangeOption: [theme] <%s>\n", theme);

				}
			}catch (Error e) {
				printerr(e.message);
			}
		});

		box.append(theme);
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
}
