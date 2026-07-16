/**
 * The hidden "magic" popup of the easter egg: click the SupraVim logo enough
 * times on the home page and this shows up.
 *
 * Each button fires a troll effect inside VIM. Like the options and the theme,
 * the effect travels through the stdout channel VIM listens to
 * (`onEasterEgg: [name]`), so it only does something when the GUI was started
 * from VIM itself.
 */
public class MagicPopup : DialogPopup {

	private struct Effect {
		string emoji;
		string label;
		string id;
	}

	private const Effect[] EFFECTS = {
		{ "🐍", "Snake",    "snake" },
		{ "🟡", "Pacman",   "pacman" },
		{ "💧", "Rain",     "rain" },
		{ "🌀", "Scramble", "scramble" }
	};

	public MagicPopup (Gtk.Window parent) {
		base (parent, "✨ Magic Mode ✨", "You found it. Now pick your chaos.");

		var grid = new Gtk.Grid () {
			row_spacing = 10,
			column_spacing = 10,
			column_homogeneous = true,
			halign = Gtk.Align.CENTER
		};

		for (int i = 0; i < EFFECTS.length; i++) {
			unowned Effect effect = EFFECTS[i];
			grid.attach (make_effect_button (effect), i % 2, i / 2, 1, 1);
		}

		box_main.append (grid);
		box_main.reorder_child_after (grid, label_subtitle);

		if (!from_supravim) {
			label_footer.set_text ("Open the GUI from inside VIM to see the effects.");
			label_footer.visible = true;
		}
	}

	private Gtk.Button make_effect_button (Effect effect) {
		var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 4) {
			halign = Gtk.Align.CENTER
		};
		var emoji = new Gtk.Label (effect.emoji);
		emoji.add_css_class ("magic_emoji");
		content.append (emoji);
		content.append (new Gtk.Label (effect.label));

		var button = new Gtk.Button () {
			child = content,
			css_classes = {"magic_button"},
			cursor = new Gdk.Cursor.from_name ("pointer", null)
		};
		string id = effect.id;
		button.clicked.connect (() => {
			send_effect (id);
			close ();
		});
		return button;
	}

	private void send_effect (string id) {
		if (from_supravim)
			print ("onEasterEgg: [%s]\n", id);
	}
}
