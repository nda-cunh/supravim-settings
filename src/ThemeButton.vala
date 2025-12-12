/**
 * A toggle button with a color theme preview.
 */
public class ThemeButton : Gtk.ToggleButton {
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
