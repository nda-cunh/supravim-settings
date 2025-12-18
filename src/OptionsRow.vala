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

	private OptionsNode node;

	/**
	 * Constructor
	 *
	 * @param name The option name
	 * @param lore The option lore/description
	 * @param value The option value
	 */
	public RowOptions (OptionsNode node) {
		this.node = node;
		base.title = Markup.escape_text (node.name);
		base.subtitle = Markup.escape_text (node.lore);

		if (/^[0-9]+/.match(node.value)) {
			_spin = new Gtk.SpinButton.with_range (0, 100, 1) {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_spin.value = int.parse(node.value);
			base.add_suffix (_spin);
			_spin.value_changed.connect((v) => {
				Utils.command_line(@"supravim -S $(node.real_name)=$(int.parse(v.text))");
				print("onChangeOption: [%s] <%d>\n", node.real_name, int.parse(v.text));
			});
		}
		else if (node.value.has_prefix ("'")) {
			_entry = new Gtk.Entry () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_entry.text = node.value[1:node.value.length - 1];
			base.add_suffix (_entry);
			_entry.changed.connect((v) => {

				if (source_id != 0) {
					Source.remove (source_id);
				}

				source_id = GLib.Timeout.add (200, () => {
					var text = v.text.replace("'", "\\'");
					Utils.command_line(@"supravim -S $(node.real_name)=\"$(text)\"");
					print("onChangeOption: [%s] <%s>\n", node.real_name, text);
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
			if (node.value == "on")
				_switch.active = true;
			base.add_suffix (_switch);
			init_event_switch ();
		}
	}

	void init_event_switch () {
		_switch.state_set.connect((v)=> {
			if (v == true) {
				Utils.command_line(@"supravim -e $(node.real_name)");
				print("onChangeOption: [%s] <true>\n", node.real_name);
			}
			else {
				Utils.command_line(@"supravim -d $(node.real_name)");
				print("onChangeOption: [%s] <false>\n", node.real_name);
			}
			_switch.active = v;
			_switch.state = v;
			return v;
		});
	}
}
