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
			if (from_supravim) {
				print("onChangeOption: [theme] <%s>\n", theme);
			} else {
				try {
					Supravim.Theme.change (theme);
				} catch (Error e) {
					warning (e.message);
				}
			}
		});

		box.append(theme_grid);
		init_default_theme.begin ();
	}

	private async void init_default_theme () throws Error {
		ListSupraOptions? lst = null;
		new Thread<void> (null, () => {
			try {
				lst = ListSupraOptions.from_vim ();
			} catch (Error e) {
				warning (e.message);
			}
			Idle.add (init_default_theme.callback);
		});
		yield;
		if (lst == null)
			return;
		var value = lst.get_from_name ("theme");
		if (value != null)
			theme_grid.change_theme (value.value);
	}
}
