/**
 * A row with an option control (switch, entry, spinbutton)
 * it represents a supravim option
 */
public class RowOptions : Adw.ActionRow {
	private Gtk.SpinButton _spin;
	private Gtk.Switch _switch;
	private Gtk.Entry _entry;
	private Gtk.Button _reset_defaults;
	
	private uint source_id = 0;
	private OptionsONode node;

	public RowOptions (OptionsONode node) {
		this.node = node;
		
		// 1. Configuration du bouton Reset
		this._reset_defaults = new Gtk.Button.from_icon_name ("view-refresh-symbolic") {
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			tooltip_text = "Reset to default",
			cursor = new Gdk.Cursor.from_name ("pointer", null)
		};
		this._reset_defaults.get_style_context().add_class("flat");

		this._reset_defaults.clicked.connect(() => {
			print("onResetOption: %s\n", node.name);
			this.reset_to_default();
		});

		base.title = Markup.escape_text (node.name); // Utilise display_name pour l'UI
		base.subtitle = Markup.escape_text (node.lore);

		// 2. Initialisation selon le type
		if (node.type_value == "number") {
			_spin = new Gtk.SpinButton.with_range (0, 1000, 1) {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_spin.value = double.parse(node.value);
			_spin.value_changed.connect((v) => {
				print("onChangeOption: [%s] <%d>\n", node.name, (int)v.value);
				check_default();
			});
			base.add_suffix (_reset_defaults);
			base.add_suffix (_spin);
		}
		else if (node.type_value == "string") {
			_entry = new Gtk.Entry () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_entry.text = node.value;
			_entry.changed.connect((v) => {
				if (source_id != 0) Source.remove (source_id);
				source_id = GLib.Timeout.add (200, () => {
					var text = v.text.replace("'", "\\'");
					print("onChangeOption: [%s] <%s>\n", node.name, text);
					check_default();
					source_id = 0;
					return false;
				});
			});
			base.add_suffix (_reset_defaults);
			base.add_suffix (_entry);
		}
		else if (node.type_value == "bool") {
			_switch = new Gtk.Switch () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
			};
			_switch.active = (node.value == "true");
			
			_switch.state_set.connect((v) => {
				print("onChangeOption: [%s] <%s>\n", node.name, v.to_string());
				_switch.active = v;
				check_default();
				return false; // On laisse l'UI se mettre à jour via active
			});
			
			base.add_suffix (_reset_defaults);
			base.add_suffix (_switch);
		}

		// Initialisation de la visibilité du bouton
		check_default();
	}

	/**
	 * Cache le bouton si la valeur actuelle est égale à la valeur par défaut
	 */
	private void check_default() {
		bool is_default = false;
		
		if (node.type_value == "bool") {
			bool def = (node.default_value == "true");
			is_default = (_switch.active == def);
		} 
		else if (node.type_value == "string") {
			is_default = (_entry.text == node.default_value);
		}
		else if (node.type_value == "number") {
			is_default = ((int)_spin.value == int.parse(node.default_value));
		}

		_reset_defaults.visible = !is_default;
	}

	/**
	 * Remet la valeur par défaut dans le widget
	 */
	private void reset_to_default() {
		string def = node.default_value;

		if (node.type_value == "bool") {
			_switch.active = (def == "true");
		} 
		else if (node.type_value == "string") {
			_entry.text = def;
		}
		else if (node.type_value == "number") {
			_spin.value = double.parse(def);
		}
		
		check_default();
	}
}
