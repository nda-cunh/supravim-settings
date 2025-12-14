/**
 * A row with an option control (switch, entry, spinbutton)
 * it represents a supravim option
 */
public class RowOptions : Adw.ActionRow {
	// For number
	private Gtk.SpinButton _spin;
	// for boolean
	private Gtk.Switch _switch;
	// for string
	private Gtk.Entry	_entry;
	// the id of the timeout source for block spamming the entry change event
	private uint source_id = 0;


	/**
	 * Constructor
	 *
	 * @param name The option name
	 * @param lore The option lore/description
	 * @param value The option value
	 */
	public RowOptions (string name, string lore, string value) {
		base.title = Markup.escape_text (name);

		base.subtitle = Markup.escape_text (lore);
		// base.set_use

		if (/^[0-9]+/.match(value)) {
			_spin = new Gtk.SpinButton.with_range (0, 100, 1) {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_spin.value = int.parse(value);
			base.add_suffix (_spin);
			_spin.value_changed.connect((v) => {
				Utils.command_line(@"supravim -S $title=$(int.parse(v.text))");
				print("onChangeOption: [%s] <%d>\n", title, int.parse(v.text));
			});
		}
		else if (value.has_prefix ("'")) {
			_entry = new Gtk.Entry () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_entry.text = value[1:value.length - 1];
			base.add_suffix (_entry);
			_entry.changed.connect((v) => {

				if (source_id != 0) {
					Source.remove (source_id);
				}

				source_id = GLib.Timeout.add (200, () => {
					var text = v.text.replace("'", "\\'");
					Utils.command_line(@"supravim -S $title=\"$(text)\"");
					print("onChangeOption: [%s] <%s>\n", title, text);
					source_id = 0;
					return false;
				});

			});
		}
		else {
			_switch = new Gtk.Switch () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			if (value == "on")
				_switch.active = true;
			base.add_suffix (_switch);
			init_event_switch ();
		}
	}

	void init_event_switch () {
		_switch.state_set.connect((v)=> {
			if (v == true) {
				Utils.command_line(@"supravim -e $title");
				print("onChangeOption: [%s] <true>\n", title);
			}
			else {
				Utils.command_line(@"supravim -d $title");
				print("onChangeOption: [%s] <false>\n", title);
			}
			_switch.active = v;
			_switch.state = v;
			return v;
		});
	}
}
