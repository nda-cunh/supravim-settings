/**
 * A row with an option control (switch, entry, spinbutton).
 * Each widget change is immediately persisted via libsupravim.
 */
public class RowOptions : Adw.ActionRow {
	private Gtk.SpinButton _spin;
	private Gtk.Switch _switch;
	private Gtk.Entry _entry;
	private Gtk.DropDown _drop;
	private Gtk.MenuButton _multi;
	private GenericArray<Gtk.CheckButton> _checks;
	private Gtk.Button _reset_btn;

	private bool syncing = false;

	private uint debounce_id = 0;
	private OptionsONode node;

	public RowOptions (OptionsONode node) {
		this.node = node;

		_reset_btn = new Gtk.Button.from_icon_name ("view-refresh-symbolic") {
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			tooltip_text = _("Reset to default"),
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
		else if (node.type_value == "choice") {
			var model = new Gtk.StringList (null);
			foreach (unowned var c in node.choice)
				model.append (c);

			_drop = new Gtk.DropDown (model, null) {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_drop.selected = index_of_choice (node.value);
			_drop.notify["selected"].connect (() => {
				var text = selected_choice ();
				if (text == null)
					return;
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
			});
			base.add_suffix (_reset_btn);
			base.add_suffix (_drop);
		}
		else if (node.type_value == "multiple_choice") {
			var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
				margin_top = 6, margin_bottom = 6, margin_start = 6, margin_end = 6
			};
			var selected = split_choices (node.value);
			_checks = new GenericArray<Gtk.CheckButton> ();
			foreach (unowned var c in node.choice) {
				var check = new Gtk.CheckButton.with_label (c) {
					active = (c in selected)
				};
				check.toggled.connect (() => {
					if (syncing)
						return;
					var text = selected_choices ();
					if (from_supravim) {
						print ("onChangeOption: [%s] <%s>\n", node.name, text);
					} else {
						try {
							Supravim.Options.update_value (node.name, text);
						} catch (Error e) {
							warning ("option update: %s", e.message);
						}
					}
					update_multi_label ();
					sync_reset_visibility ();
				});
				_checks.add (check);
				box.append (check);
			}

			_multi = new Gtk.MenuButton () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
				popover = new Gtk.Popover () { child = box }
			};
			update_multi_label ();
			base.add_suffix (_reset_btn);
			base.add_suffix (_multi);
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

	private uint index_of_choice (string value) {
		for (uint i = 0; i < node.choice.length; i++) {
			if (node.choice[i] == value)
				return i;
		}
		return Gtk.INVALID_LIST_POSITION;
	}

	private static string[] split_choices (string value) {
		string[] result = {};
		foreach (unowned var part in value.split (",")) {
			var item = part.strip ();
			if (item != "")
				result += item;
		}
		return result;
	}

	private string selected_choices () {
		string[] result = {};
		for (uint i = 0; i < _checks.length; i++) {
			if (_checks[i].active)
				result += node.choice[i];
		}
		return string.joinv (",", result);
	}

	private string canonical_choices (string value) {
		var selected = split_choices (value);
		string[] result = {};
		foreach (unowned var c in node.choice) {
			if (c in selected)
				result += c;
		}
		return string.joinv (",", result);
	}

	private void update_multi_label () {
		var text = selected_choices ();
		_multi.label = (text == "") ? _("None") : text.replace (",", ", ");
	}

	private void set_multi_selection (string value) {
		var selected = split_choices (value);
		syncing = true;
		for (uint i = 0; i < _checks.length; i++)
			_checks[i].active = (node.choice[i] in selected);
		syncing = false;
		update_multi_label ();
	}

	private unowned string? selected_choice () {
		var index = _drop.selected;
		if (index == Gtk.INVALID_LIST_POSITION || index >= node.choice.length)
			return null;
		return node.choice[index];
	}

	private void sync_reset_visibility () {
		bool is_default = false;
		if (node.type_value == "bool")
			is_default = (_switch.active == (node.default_value == "true"));
		else if (node.type_value == "string")
			is_default = (_entry.text == node.default_value);
		else if (node.type_value == "number")
			is_default = ((int) _spin.value == int.parse (node.default_value));
		else if (node.type_value == "choice")
			is_default = (selected_choice () == node.default_value);
		else if (node.type_value == "multiple_choice")
			is_default = (selected_choices () == canonical_choices (node.default_value));
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
		else if (node.type_value == "choice")
			_drop.selected = index_of_choice (def);
		else if (node.type_value == "multiple_choice")
			set_multi_selection (def);

		sync_reset_visibility ();
	}
}
