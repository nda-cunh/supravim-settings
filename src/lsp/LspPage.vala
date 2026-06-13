[GtkTemplate (ui = "/ui/lsp.ui")]
public class LspPage : Gtk.Box {

	[GtkChild] private unowned Gtk.SearchEntry      lsp_search;
	[GtkChild] private unowned Adw.PreferencesGroup user_lsp_group;
	[GtkChild] private unowned Adw.PreferencesGroup system_lsp_group;

	private List<LspRow> user_lsp_rows   = new List<LspRow> ();
	private List<LspRow> system_lsp_rows = new List<LspRow> ();

	private static string user_lsp_dir =
		Environment.get_home_dir () + "/.config/supravim/lsp.d";
	private static string system_lsp_dir =
		Environment.get_home_dir () + "/.local/share/supravim/lsp.d";

	construct {
		refresh ();
	}

	/* ---- Search ---- */

	[GtkCallback]
	private void on_lsp_search_changed () {
		var query = lsp_search.text.strip ().down ();
		foreach (unowned var row in user_lsp_rows)
			row.visible = (query == "" || row.search_text.contains (query));
		foreach (unowned var row in system_lsp_rows)
			row.visible = (query == "" || row.search_text.contains (query));
	}

	/* ---- Add LSP ---- */

	[GtkCallback]
	private void on_add_lsp () {
		var parent = get_root () as Gtk.Window;
		var dialog = new AddLspDialog (parent, user_lsp_dir);
		dialog.saved.connect (() => refresh ());
		dialog.present ();
	}

	/* ---- Refresh ---- */

	public void refresh () {
		foreach (unowned var r in user_lsp_rows)   user_lsp_group.remove (r);
		foreach (unowned var r in system_lsp_rows) system_lsp_group.remove (r);
		user_lsp_rows   = new List<LspRow> ();
		system_lsp_rows = new List<LspRow> ();

		load_lsp_dir (user_lsp_dir,   false);
		load_lsp_dir (system_lsp_dir, true);
	}

	private void load_lsp_dir (string dir_path, bool is_system) {
		try {
			var dir   = Dir.open (dir_path);
			var names = new GenericArray<string> ();
			string? n;
			while ((n = dir.read_name ()) != null)
				if (n.has_suffix (".json")) names.add (n);
			names.sort ((a, b) => strcmp (a, b));

			foreach (unowned string fname in names) {
				var entry = LspEntry.from_file (dir_path + "/" + fname, is_system);
				if (entry == null) continue;
				var row = new LspRow (entry);
				var cap = entry.file_path;
				row.deleted.connect (() => {
					FileUtils.unlink (cap);
					refresh ();
				});
				if (is_system) {
					system_lsp_rows.append (row);
					system_lsp_group.add (row);
				} else {
					user_lsp_rows.append (row);
					user_lsp_group.add (row);
				}
			}
		} catch {}
	}

	/* ================================================================== */
	/*  Dialog: add a new user LSP                                         */
	/* ================================================================== */

	public class AddLspDialog : DialogPopup {
		public signal void saved ();

		private Gtk.Entry name_entry;
		private Gtk.Entry cmd_entry;
		private Gtk.Entry ft_entry;
		private Gtk.Entry test_entry;
		private Gtk.Entry hint_entry;
		private string    save_dir;

		public AddLspDialog (Gtk.Window parent, string dir) {
			base (parent, "Add a Language Server", null);
			save_dir = dir;

			set_default_size (520, -1);

			name_entry = make_entry ("e.g. my-lsp");
			cmd_entry  = make_entry ("e.g. my-lsp-server");
			ft_entry   = make_entry ("e.g. python,go");
			test_entry = make_entry ("e.g. my-lsp-server --version  (optional)");
			hint_entry = make_entry ("e.g. suprapack add my-lsp --yes  (optional)");

			base.box_main.append (make_row ("Name",         name_entry));
			base.box_main.append (make_row ("Command",      cmd_entry));
			base.box_main.append (make_row ("Filetypes",    ft_entry));
			base.box_main.append (make_row ("Test command", test_entry));
			base.box_main.append (make_row ("Install hint", hint_entry));

			var save_btn = new Gtk.Button.with_label ("Save") {
				css_classes = {"suggested-action", "button_popup"},
			};
			save_btn.clicked.connect (() => do_save ());
			base.box_buttons.append (save_btn);
			add_cancel_button ();

			name_entry.grab_focus ();
		}

		private static Gtk.Entry make_entry (string placeholder) {
			return new Gtk.Entry () {
				placeholder_text = placeholder,
				hexpand          = true,
			};
		}

		private static Gtk.Box make_row (string label_text, Gtk.Entry entry) {
			var lbl = new Gtk.Label (label_text + ":") {
				width_chars = 14,
				xalign      = 0f,
			};
			lbl.add_css_class ("dim-label");
			var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10) {
				margin_top    = 3,
				margin_bottom = 3,
			};
			box.append (lbl);
			box.append (entry);
			return box;
		}

		private void do_save () {
			var nm = name_entry.text.strip ();
			var cm = cmd_entry.text.strip ();
			var ft = ft_entry.text.strip ();
			if (nm == "" || cm == "" || ft == "") {
				set_subtitle_label ("Name, command and filetypes are required.");
				return;
			}
			var e          = new LspEntry ();
			e.name         = nm;
			e.command      = cm;
			e.allowed      = ft;
			e.test_command = test_entry.text.strip ();
			e.command_help = hint_entry.text.strip ();
			e.is_system    = false;
			e.file_path    = save_dir + "/" + nm + ".json";
			try {
				DirUtils.create_with_parents (save_dir, 0755);
				FileUtils.set_contents (e.file_path, e.to_json ());
				saved ();
				close ();
			} catch (Error err) {
				set_subtitle_label ("Error: " + err.message);
			}
		}
	}
}
