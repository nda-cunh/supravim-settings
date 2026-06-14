/**
 * A row with an option control (switch, entry, spinbutton).
 * Each widget change is immediately persisted via libsupravim.
 */
public class RowOptions : Adw.ActionRow {
	private Gtk.SpinButton _spin;
	private Gtk.Switch _switch;
	private Gtk.Entry _entry;
	private Gtk.Button _reset_btn;

	private uint debounce_id = 0;
	private OptionsONode node;

	public RowOptions (OptionsONode node) {
		this.node = node;

		_reset_btn = new Gtk.Button.from_icon_name ("view-refresh-symbolic") {
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			tooltip_text = "Reset to default",
			cursor = new Gdk.Cursor.from_name ("pointer", null)
		};
		_reset_btn.add_css_class ("flat");
		_reset_btn.clicked.connect (() => reset_to_default ());

		base.title = Markup.escape_text (node.display_name);
		base.subtitle = Markup.escape_text (node.lore);

		if (node.type_value == "number") {
			_spin = new Gtk.SpinButton.with_range (0, 1000, 1) {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_spin.value = double.parse (node.value);
			_spin.value_changed.connect ((v) => {
				if (from_supravim) {
					print ("onChangeOption: [%s] <%d>\n", node.name, (int) v.value);
				} else {
					try {
						Supravim.Options.update_value (node.name, ((int) v.value).to_string ());
					} catch (Error e) {
						warning ("option update: %s", e.message);
					}
				}
				sync_reset_visibility ();
			});
			base.add_suffix (_reset_btn);
			base.add_suffix (_spin);
		}
		else if (node.type_value == "string") {
			_entry = new Gtk.Entry () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_entry.text = node.value;
			_entry.changed.connect ((v) => {
				if (debounce_id != 0) Source.remove (debounce_id);
				debounce_id = GLib.Timeout.add (300, () => {
					var text = v.text.replace ("'", "\\'");
					if (from_supravim) {
						print ("onChangeOption: [%s] <%s>\n", node.name, text);
					} else {
						try {
							Supravim.Options.update_value (node.name, text);
						} catch (Error e) {
							warning ("option update: %s", e.message);
						}
					}
					sync_reset_visibility ();
					debounce_id = 0;
					return false;
				});
			});
			base.add_suffix (_reset_btn);
			base.add_suffix (_entry);
		}
		else if (node.type_value == "bool") {
			_switch = new Gtk.Switch () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_switch.active = (node.value == "true");
			_switch.state_set.connect ((v) => {
				_switch.active = v;
				if (from_supravim) {
					print ("onChangeOption: [%s] <%s>\n", node.name, v.to_string ());
				} else {
					try {
						if (v)
							Supravim.Options.enable (node.name);
						else
							Supravim.Options.disable (node.name);
					} catch (Error e) {
						warning ("option toggle: %s", e.message);
					}
				}
				sync_reset_visibility ();
				return false;
			});
			base.add_suffix (_reset_btn);
			base.add_suffix (_switch);
		}

		sync_reset_visibility ();
	}

	public unowned string get_node_name () {
		return node.name;
	}

	public unowned string get_type_value () {
		return node.type_value;
	}

	/* ------------------------------------------------------------------ */

	private void sync_reset_visibility () {
		bool is_default = false;
		if (node.type_value == "bool")
			is_default = (_switch.active == (node.default_value == "true"));
		else if (node.type_value == "string")
			is_default = (_entry.text == node.default_value);
		else if (node.type_value == "number")
			is_default = ((int) _spin.value == int.parse (node.default_value));
		_reset_btn.visible = !is_default;
	}

	private void reset_to_default () {
		string def = node.default_value;
		if (from_supravim) {
			print ("onResetOption: %s\n", node.name);
		} else {
			try {
				Supravim.Options.reset_value (node.name);
			} catch (Error e) {
				warning ("option reset: %s", e.message);
			}
		}

		if (node.type_value == "bool")
			_switch.active = (def == "true");
		else if (node.type_value == "string")
			_entry.text = def;
		else if (node.type_value == "number")
			_spin.value = double.parse (def);

		sync_reset_visibility ();
	}
}
