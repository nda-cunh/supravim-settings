Adw.ActionRow create_row(string suffix, Gtk.Switch switch) {
	var row = new Adw.ActionRow();
	row.add_prefix(new Gtk.Label(suffix));
	row.add_suffix(switch);
	return row;
}

public class General : Gtk.Box {
	public General () {
		Object(orientation: Gtk.Orientation.VERTICAL, spacing: 10);
		
		group = new Adw.PreferencesGroup() {title="Options", css_classes={"margin"}};
		s_mouse = new Gtk.Switch(){valign=Gtk.Align.CENTER};
		s_swap = new Gtk.Switch(){valign=Gtk.Align.CENTER};
		s_norme = new Gtk.Switch(){valign=Gtk.Align.CENTER};
		s_tree = new Gtk.Switch(){valign=Gtk.Align.CENTER};
		s_icons = new Gtk.Switch(){valign=Gtk.Align.CENTER};

		supravim_cfg = Config.load();
		
		create_option();
		init_event();
	}

	private void create_option() {
		group.add(create_row("Mouse", s_mouse));
		group.add(create_row("Swap", s_swap));
		group.add(create_row("Tree", s_tree));
		group.add(create_row("Icons", s_icons));
		group.add(create_row("Norme", s_norme));

		s_mouse.state = (bool)supravim_cfg.mouse;
		s_swap.state = (bool)supravim_cfg.swap;
		s_norme.state = (bool)supravim_cfg.norme;
		s_tree.state = (bool)supravim_cfg.tree;
		s_icons.state = (bool)supravim_cfg.icons;
		s_mouse.active = (bool)supravim_cfg.mouse;
		s_swap.active = (bool)supravim_cfg.swap;
		s_norme.active = (bool)supravim_cfg.norme;
		s_tree.active = (bool)supravim_cfg.tree;
		s_icons.active = (bool)supravim_cfg.icons;

		base.append(group);
		var update = new Gtk.Button.with_label("Update"){css_classes = {"margin"}};

		base.append(update);
		base.append(new Gtk.Button.with_label("Uninstall"){css_classes = {"margin"}});
	}

	public void init_event() {
		s_mouse.state_set.connect((lv)=> {
			supravim_cfg.mouse = lv;
			supravim_cfg.generate();
			return false;	
		});
		s_swap.state_set.connect((lv)=> {
			supravim_cfg.swap = lv;
			supravim_cfg.generate();
			return false;	
		});
		s_norme.state_set.connect((lv)=> {
			supravim_cfg.norme = lv;
			supravim_cfg.generate();
			return false;	
		});
		s_tree.state_set.connect((lv)=> {
			supravim_cfg.tree = lv;
			supravim_cfg.generate();
			return false;	
		});
		s_icons.state_set.connect((lv)=> {
			supravim_cfg.icons = lv;
			supravim_cfg.generate();
			return false;	
		});
	}
	
	private Config supravim_cfg;
	private Gtk.Switch s_mouse;
	private Gtk.Switch s_swap;
	private Gtk.Switch s_norme;
	private Gtk.Switch s_tree;
	private Gtk.Switch s_icons;
	private Adw.PreferencesGroup group;
}
