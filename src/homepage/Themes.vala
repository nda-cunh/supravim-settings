public HashTable<string, Color> tab_themes;

[GtkTemplate (ui = "/ui/theme.ui")]
public class ThemePage : Adw.PreferencesGroup {
	[GtkChild]
	private unowned Gtk.Box box;

	private ThemeGrid theme_grid;

	construct {
		init_themes();
		theme_grid = new ThemeGrid();
		theme_grid.onThemeChange.connect ((theme)=> {
			try {
				if (theme.index_of_char ('-') == -1){
					print("onChangeOption: [theme] <%s>\n", theme);

				}
				else {
					var named_theme = theme[0:theme.index_of_char('-')];
					print("onChangeOption: [theme] <%s>\n", theme);

				}
			}catch (Error e) {
				printerr(e.message);
			}
		});

		box.append(theme_grid);
		init_default_theme.begin ();
	}

	private async void init_default_theme() throws Error {
		var lst = yield SupraParser.async_get_from_vim();
		var value = lst.get_from_name("theme");
		theme_grid.change_theme(value.value);
	}
}
