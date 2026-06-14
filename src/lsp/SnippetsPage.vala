[GtkTemplate (ui = "/ui/snippets.ui")]
public class SnippetsPage : Gtk.Box {

	[GtkChild] private unowned Gtk.SearchEntry      snippets_search;
	[GtkChild] private unowned Adw.PreferencesGroup user_snippets_group;
	[GtkChild] private unowned Adw.PreferencesGroup system_snippets_group;

	// Tracked for filtering and removal
	private List<FiletypeData> user_data   = new List<FiletypeData> ();
	private List<FiletypeData> system_data = new List<FiletypeData> ();

	private static string user_snip_dir =
		Environment.get_home_dir () + "/.config/supravim/snippets";
	private static string system_snip_dir =
		Environment.get_home_dir () + "/.local/share/supravim/data/snippets";

	private bool loaded = false;

	construct {
	}

	/** Build the page content the first time it becomes visible. */
	public void ensure_loaded () {
		if (loaded)
			return;
		loaded = true;
		refresh ();
	}

	/* ---- Search ---- */

	[GtkCallback]
	private void on_search_changed () {
		var query = snippets_search.text.strip ().down ();
		apply_filter (user_data,   query);
		apply_filter (system_data, query);
	}

	private void apply_filter (List<FiletypeData> data, string query) {
		foreach (unowned FiletypeData fd in data) {
			if (query == "") {
				fd.expander.visible  = true;
				fd.expander.expanded = false;
				foreach (unowned SnippetData sd in fd.snippets)
					sd.row.visible = true;
				continue;
			}

			bool ft_match       = fd.search_key.contains (query);
			bool any_child      = false;

			foreach (unowned SnippetData sd in fd.snippets) {
				bool match    = ft_match || sd.search_key.contains (query);
				sd.row.visible = match;
				if (match) any_child = true;
			}

			fd.expander.visible  = ft_match || any_child;
			// Auto-expand when a child matches (but not when only the filetype name matched)
			fd.expander.expanded = any_child;
		}
	}

	/* ---- Add filetype ---- */

	[GtkCallback]
	private void on_add_snippet () {
		var parent = get_root () as Gtk.Window;
		var dialog = new AddSnippetFiletypeDialog (parent, user_snip_dir);
		dialog.saved.connect ((ft, path) => {
			refresh ();
			var editor = new SnippetItemEditDialog (
				get_root () as Gtk.Window, "", "", "", "", path, ft);
			editor.saved.connect (() => refresh ());
			editor.present ();
		});
		dialog.present ();
	}

	/* ---- Refresh ---- */

	public void refresh () {
		foreach (unowned FiletypeData fd in user_data)
			user_snippets_group.remove (fd.expander);
		foreach (unowned FiletypeData fd in system_data)
			system_snippets_group.remove (fd.expander);

		user_data   = new List<FiletypeData> ();
		system_data = new List<FiletypeData> ();

		load_snip_dir (user_snip_dir,   false);
		load_snip_dir (system_snip_dir, true);
	}

	private void load_snip_dir (string dir_path, bool is_system) {
		try {
			var dir   = Dir.open (dir_path);
			var names = new GenericArray<string> ();
			string? n;
			while ((n = dir.read_name ()) != null)
				if (n.has_suffix (".json")) names.add (n);
			names.sort ((a, b) => strcmp (a, b));

			foreach (unowned string fname in names) {
				var path     = dir_path + "/" + fname;
				var filetype = fname.slice (0, fname.length - 5);
				var snippets = parse_snippets (path);
				var fd       = build_expander (filetype, path, is_system, snippets);

				if (is_system) {
					system_data.append (fd);
					system_snippets_group.add (fd.expander);
				} else {
					user_data.append (fd);
					user_snippets_group.add (fd.expander);
				}
			}
		} catch {}
	}

	/* ---- Delete one snippet from its JSON file ---- */

	private void delete_snippet (string path, string name) {
		string content;
		try {
			FileUtils.get_contents (path, out content);
		} catch { return; }

		var doc = YYJson.Doc.read (content, content.length);
		if (doc == null) return;
		unowned YYJson.Value root = doc.get_root ();
		if (root == null || root.get_type () != YYJson.Type.OBJ) return;

		var sb = new StringBuilder ("{\n");
		bool first = true;

		YYJson.ObjIter iter;
		if (YYJson.ObjIter.init (root, out iter)) {
			unowned YYJson.Value? key;
			while ((key = iter.next ()) != null) {
				string sname = key.get_str () ?? "";
				if (sname == name) continue;
				unowned YYJson.Value? val = YYJson.ObjIter.get_val (key);
				if (val == null) continue;

				if (!first) sb.append (",\n");
				first = false;

				string e_desc   = SnippetItemEditDialog.json_obj_str (val, "description");
				string e_prefix = SnippetItemEditDialog.json_build_prefix (val);
				string e_body   = SnippetItemEditDialog.json_build_body (val);
				SnippetItemEditDialog.append_snippet_json (sb, sname, e_prefix, e_desc, e_body);
			}
		}

		sb.append ("\n}\n");

		try {
			FileUtils.set_contents (path, sb.str);
		} catch { return; }

		refresh ();
	}

	/* ---- Build one ExpanderRow per filetype ---- */

	private FiletypeData build_expander (string filetype, string path,
	                                     bool is_system,
	                                     GenericArray<SnippetInfo> snippets) {
		var expander = new Adw.ExpanderRow () {
			title    = Markup.escape_text (filetype),
			subtitle = (snippets.length == 1)
			           ? "1 snippet"
			           : "%u snippets".printf (snippets.length),
		};

		var fd = new FiletypeData (expander, filetype);

		// One child row per snippet
		foreach (unowned SnippetInfo s in snippets) {
			var row = new Adw.ActionRow () {
				title       = Markup.escape_text (s.name),
				subtitle    = Markup.escape_text (s.description),
				activatable = true,
			};

			if (s.prefix != "") {
				var badge = new Gtk.Label (s.prefix) {
					halign = Gtk.Align.CENTER,
					valign = Gtk.Align.CENTER,
				};
				badge.add_css_class ("caption");
				badge.add_css_class ("dim-label");
				row.add_suffix (badge);
			}

			var cap_name     = s.name;
			var cap_prefix   = s.prefix;
			var cap_desc     = s.description;
			var cap_body     = s.body;
			var cap_filetype = filetype;
			var cap_path     = path;

			if (!is_system) {
				var del_btn = new Gtk.Button () {
					icon_name    = "user-trash-symbolic",
					tooltip_text = "Delete this snippet",
					halign       = Gtk.Align.CENTER,
					valign       = Gtk.Align.CENTER,
					cursor       = new Gdk.Cursor.from_name ("pointer", null),
				};
				del_btn.add_css_class ("flat");
				del_btn.add_css_class ("destructive-action");
				del_btn.clicked.connect (() => delete_snippet (cap_path, cap_name));
				row.add_suffix (del_btn);
			}

			row.activated.connect (() => {
				if (is_system) {
					var popup = new SnippetDetailDialog (
						get_root () as Gtk.Window,
						cap_name, cap_filetype, cap_body, true);
					popup.present ();
				} else {
					var popup = new SnippetItemEditDialog (
						get_root () as Gtk.Window,
						cap_name, cap_prefix, cap_desc, cap_body, cap_path);
					popup.saved.connect (() => refresh ());
					popup.present ();
				}
			});

			expander.add_row (row);

			var sd = new SnippetData (row, s.name, s.description, s.prefix);
			fd.snippets.add (sd);
		}

		// Action buttons
		if (is_system) {
			var lock_icon = new Gtk.Image () {
				icon_name    = "changes-prevent-symbolic",
				tooltip_text = "System snippets — read-only",
				halign       = Gtk.Align.CENTER,
				valign       = Gtk.Align.CENTER,
			};
			lock_icon.add_css_class ("dim-label");
			expander.add_action (lock_icon);
		} else {
			var cap_ft   = filetype;
			var cap_path = path;

			var add_btn = new Gtk.Button () {
				icon_name    = "list-add-symbolic",
				tooltip_text = "Add a snippet",
				halign       = Gtk.Align.CENTER,
				valign       = Gtk.Align.CENTER,
				cursor       = new Gdk.Cursor.from_name ("pointer", null),
			};
			add_btn.add_css_class ("flat");
			add_btn.clicked.connect (() => {
				var dialog = new SnippetItemEditDialog (
					get_root () as Gtk.Window, "", "", "", "", cap_path, cap_ft);
				dialog.saved.connect (() => refresh ());
				dialog.present ();
			});
			expander.add_action (add_btn);

			var edit_btn = new Gtk.Button () {
				icon_name    = "document-edit-symbolic",
				tooltip_text = "Edit snippets file",
				halign       = Gtk.Align.CENTER,
				valign       = Gtk.Align.CENTER,
				cursor       = new Gdk.Cursor.from_name ("pointer", null),
			};
			edit_btn.add_css_class ("flat");
			edit_btn.clicked.connect (() => {
				var editor = new SnippetEditorDialog (
					get_root () as Gtk.Window, cap_ft, cap_path);
				editor.saved.connect (() => refresh ());
				editor.present ();
			});
			expander.add_action (edit_btn);

			var del_btn = new Gtk.Button () {
				icon_name    = "user-trash-symbolic",
				tooltip_text = "Delete these snippets",
				halign       = Gtk.Align.CENTER,
				valign       = Gtk.Align.CENTER,
				cursor       = new Gdk.Cursor.from_name ("pointer", null),
			};
			del_btn.add_css_class ("flat");
			del_btn.clicked.connect (() => {
				FileUtils.unlink (cap_path);
				refresh ();
			});
			expander.add_action (del_btn);
		}

		return fd;
	}

	/* ---- JSON parsing ---- */

	private class SnippetInfo {
		public string name;
		public string description;
		public string prefix;
		public string body;

		public SnippetInfo (string name, string desc, string prefix, string body) {
			this.name        = name;
			this.description = desc;
			this.prefix      = prefix;
			this.body        = body;
		}
	}

	private GenericArray<SnippetInfo> parse_snippets (string path) {
		var result = new GenericArray<SnippetInfo> ();
		try {
			string content;
			FileUtils.get_contents (path, out content);
			var doc = YYJson.Doc.read (content, content.length);
			if (doc == null) return result;
			unowned YYJson.Value root = doc.get_root ();
			if (root == null || root.get_type () != YYJson.Type.OBJ) return result;

			YYJson.ObjIter iter;
			if (!YYJson.ObjIter.init (root, out iter)) return result;

			unowned YYJson.Value? key;
			while ((key = iter.next ()) != null) {
				string sname = key.get_str () ?? "";
				unowned YYJson.Value? val = YYJson.ObjIter.get_val (key);
				if (val == null || val.get_type () != YYJson.Type.OBJ) continue;

				string desc   = obj_str (val, "description");
				string prefix = build_prefix (val);
				string body   = build_body (val);

				result.add (new SnippetInfo (sname, desc, prefix, body));
			}
		} catch {}
		return result;
	}

	private static string obj_str (YYJson.Value obj, string key) {
		unowned YYJson.Value? v = obj.obj_get (key);
		if (v == null) return "";
		return v.get_str () ?? "";
	}

	private static string build_prefix (YYJson.Value snippet_obj) {
		unowned YYJson.Value? pv = snippet_obj.obj_get ("prefix");
		if (pv == null) return "";
		if (pv.get_type () == YYJson.Type.STR)
			return pv.get_str () ?? "";
		if (pv.get_type () != YYJson.Type.ARR) return "";
		var parts = new GenericArray<string> ();
		for (size_t i = 0; i < pv.arr_size (); i++) {
			unowned YYJson.Value? p = pv.arr_get (i);
			if (p != null) parts.add (p.get_str () ?? "");
		}
		return string.joinv (", ", parts.data);
	}

	private static string build_body (YYJson.Value snippet_obj) {
		unowned YYJson.Value? bv = snippet_obj.obj_get ("body");
		if (bv == null) return "";
		if (bv.get_type () == YYJson.Type.STR)
			return bv.get_str () ?? "";
		if (bv.get_type () != YYJson.Type.ARR) return "";
		var lines = new GenericArray<string> ();
		for (size_t i = 0; i < bv.arr_size (); i++) {
			unowned YYJson.Value? l = bv.arr_get (i);
			if (l != null) lines.add (l.get_str () ?? "");
		}
		return string.joinv ("\n", lines.data);
	}

	/* ---- Tracking helpers ---- */

	private class FiletypeData {
		public Adw.ExpanderRow         expander;
		public string                  search_key;
		public GenericArray<SnippetData> snippets;

		public FiletypeData (Adw.ExpanderRow e, string filetype) {
			expander   = e;
			search_key = filetype.down ();
			snippets   = new GenericArray<SnippetData> ();
		}
	}

	private class SnippetData {
		public Adw.ActionRow row;
		public string        search_key;

		public SnippetData (Adw.ActionRow r, string name, string desc, string prefix) {
			row        = r;
			search_key = (name + " " + desc + " " + prefix).down ();
		}
	}

	/* ================================================================== */
	/*  Dialog: edit a single snippet (name, prefix, desc, body)           */
	/* ================================================================== */

	public class SnippetItemEditDialog : DialogPopup {
		public signal void saved ();

		private Gtk.Entry  name_entry;
		private Gtk.Entry  prefix_entry;
		private Gtk.Entry  desc_entry;
		private Gtk.TextView body_view;
		private string       file_path;
		private string       original_name;

		public SnippetItemEditDialog (Gtk.Window parent,
		                              string name, string prefix,
		                              string description, string body,
		                              string path, string filetype = "") {
			base (parent, name == "" ? "New Snippet" : "Edit Snippet",
			      filetype != "" ? filetype : null);
			file_path     = path;
			original_name = name;

			set_default_size (620, 540);

			name_entry = new Gtk.Entry () {
				placeholder_text = "Snippet name",
				hexpand          = true,
				text             = name,
			};
			prefix_entry = new Gtk.Entry () {
				placeholder_text = "Prefix (e.g. fn, for, if)",
				hexpand          = true,
				text             = prefix,
			};
			desc_entry = new Gtk.Entry () {
				placeholder_text = "Description",
				hexpand          = true,
				text             = description,
			};

			var fields = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);

			var lbl_name = new Gtk.Label ("Name") {
				halign = Gtk.Align.START, width_chars = 12, xalign = 0.0f,
			};
			lbl_name.add_css_class ("dim-label");
			var row_name = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
			row_name.append (lbl_name);
			row_name.append (name_entry);
			fields.append (row_name);

			var lbl_prefix = new Gtk.Label ("Prefix") {
				halign = Gtk.Align.START, width_chars = 12, xalign = 0.0f,
			};
			lbl_prefix.add_css_class ("dim-label");
			var row_prefix = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
			row_prefix.append (lbl_prefix);
			row_prefix.append (prefix_entry);
			fields.append (row_prefix);

			var lbl_desc = new Gtk.Label ("Description") {
				halign = Gtk.Align.START, width_chars = 12, xalign = 0.0f,
			};
			lbl_desc.add_css_class ("dim-label");
			var row_desc = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
			row_desc.append (lbl_desc);
			row_desc.append (desc_entry);
			fields.append (row_desc);

			base.box_main.append (fields);

			var body_label = new Gtk.Label ("Body") {
				halign        = Gtk.Align.START,
				margin_top    = 4,
				margin_bottom = 2,
			};
			body_label.add_css_class ("heading");
			base.box_main.append (body_label);

			var scrolled = new Gtk.ScrolledWindow () {
				vexpand        = true,
				hexpand        = true,
				height_request = 220,
			};
			body_view = new Gtk.TextView () {
				monospace     = true,
				left_margin   = 10,
				right_margin  = 10,
				top_margin    = 8,
				bottom_margin = 8,
				wrap_mode     = Gtk.WrapMode.NONE,
			};
			body_view.buffer.set_text (body, -1);
			scrolled.set_child (body_view);
			base.box_main.append (scrolled);

			var save_btn = new Gtk.Button.with_label ("Save") {
				css_classes = {"suggested-action", "button_popup"},
			};
			save_btn.clicked.connect (() => do_save ());
			base.box_buttons.append (save_btn);
			add_cancel_button ();
		}

		private void do_save () {
			var new_name   = name_entry.text.strip ();
			var new_prefix = prefix_entry.text.strip ();
			var new_desc   = desc_entry.text.strip ();

			Gtk.TextIter start, end;
			body_view.buffer.get_bounds (out start, out end);
			var new_body = body_view.buffer.get_text (start, end, false);

			if (new_name == "") {
				set_subtitle_label ("Name cannot be empty.");
				return;
			}

			string content;
			try {
				FileUtils.get_contents (file_path, out content);
			} catch {
				set_subtitle_label ("Could not read file.");
				return;
			}

			var doc = YYJson.Doc.read (content, content.length);
			if (doc == null) {
				set_subtitle_label ("Invalid JSON in file.");
				return;
			}

			unowned YYJson.Value root = doc.get_root ();
			if (root == null || root.get_type () != YYJson.Type.OBJ) {
				set_subtitle_label ("Unexpected JSON structure.");
				return;
			}

			var sb = new StringBuilder ("{\n");
			bool first = true;

			YYJson.ObjIter iter;
			if (YYJson.ObjIter.init (root, out iter)) {
				unowned YYJson.Value? key;
				while ((key = iter.next ()) != null) {
					string sname = key.get_str () ?? "";
					unowned YYJson.Value? val = YYJson.ObjIter.get_val (key);
					if (val == null) continue;

					if (!first) sb.append (",\n");
					first = false;

					if (original_name != "" && sname == original_name) {
						append_snippet_json (sb, new_name, new_prefix, new_desc, new_body);
					} else {
						string e_desc   = json_obj_str (val, "description");
						string e_prefix = json_build_prefix (val);
						string e_body   = json_build_body (val);
						append_snippet_json (sb, sname, e_prefix, e_desc, e_body);
					}
				}
			}

			// New snippet (original_name == "") → append at end
			if (original_name == "") {
				if (!first) sb.append (",\n");
				append_snippet_json (sb, new_name, new_prefix, new_desc, new_body);
			}

			sb.append ("\n}\n");

			try {
				FileUtils.set_contents (file_path, sb.str);
				saved ();
				close ();
			} catch (Error err) {
				set_subtitle_label ("Error saving: " + err.message);
			}
		}

		internal static string json_escape (string s) {
			var sb = new StringBuilder ();
			unichar c;
			int i = 0;
			while (s.get_next_char (ref i, out c)) {
				switch (c) {
				case '"':  sb.append ("\\\""); break;
				case '\\': sb.append ("\\\\"); break;
				case '\n': sb.append ("\\n");  break;
				case '\r': sb.append ("\\r");  break;
				case '\t': sb.append ("\\t");  break;
				default:   sb.append_unichar (c); break;
				}
			}
			return sb.str;
		}

		internal static void append_snippet_json (StringBuilder sb,
		                                         string name, string prefix,
		                                         string description, string body) {
			sb.append ("  \"%s\": {\n".printf (json_escape (name)));
			sb.append ("    \"description\": \"%s\",\n".printf (json_escape (description)));
			if (prefix == "") {
				sb.append ("    \"prefix\": \"\",\n");
			} else if (prefix.contains (",")) {
				var parts = prefix.split (",");
				sb.append ("    \"prefix\": [");
				bool f = true;
				foreach (unowned string p in parts) {
					if (!f) sb.append (", ");
					sb.append ("\"%s\"".printf (json_escape (p.strip ())));
					f = false;
				}
				sb.append ("],\n");
			} else {
				sb.append ("    \"prefix\": \"%s\",\n".printf (json_escape (prefix)));
			}
			var lines = body.split ("\n");
			sb.append ("    \"body\": [\n");
			for (int li = 0; li < lines.length; li++) {
				sb.append ("      \"%s\"".printf (json_escape (lines[li])));
				if (li < lines.length - 1) sb.append (",");
				sb.append ("\n");
			}
			sb.append ("    ]\n");
			sb.append ("  }");
		}

		internal static string json_obj_str (YYJson.Value obj, string key) {
			unowned YYJson.Value? v = obj.obj_get (key);
			if (v == null) return "";
			return v.get_str () ?? "";
		}

		internal static string json_build_prefix (YYJson.Value snippet_obj) {
			unowned YYJson.Value? pv = snippet_obj.obj_get ("prefix");
			if (pv == null) return "";
			if (pv.get_type () == YYJson.Type.STR)
				return pv.get_str () ?? "";
			if (pv.get_type () != YYJson.Type.ARR) return "";
			var parts = new GenericArray<string> ();
			for (size_t i = 0; i < pv.arr_size (); i++) {
				unowned YYJson.Value? p = pv.arr_get (i);
				if (p != null) parts.add (p.get_str () ?? "");
			}
			return string.joinv (", ", parts.data);
		}

		internal static string json_build_body (YYJson.Value snippet_obj) {
			unowned YYJson.Value? bv = snippet_obj.obj_get ("body");
			if (bv == null) return "";
			if (bv.get_type () == YYJson.Type.STR)
				return bv.get_str () ?? "";
			if (bv.get_type () != YYJson.Type.ARR) return "";
			var lines = new GenericArray<string> ();
			for (size_t i = 0; i < bv.arr_size (); i++) {
				unowned YYJson.Value? l = bv.arr_get (i);
				if (l != null) lines.add (l.get_str () ?? "");
			}
			return string.joinv ("\n", lines.data);
		}
	}

	/* ================================================================== */
	/*  Dialog: preview a snippet body (read-only)                         */
	/* ================================================================== */

	public class SnippetDetailDialog : DialogPopup {
		public SnippetDetailDialog (Gtk.Window parent, string name,
		                            string filetype, string body, bool is_system) {
			base (parent, name, filetype + (is_system ? "  •  read-only" : ""));

			set_default_size (600, 420);

			var scrolled = new Gtk.ScrolledWindow () {
				vexpand        = true,
				hexpand        = true,
				height_request = 340,
			};
			var text_view = new Gtk.TextView () {
				monospace      = true,
				editable       = false,
				cursor_visible = false,
				left_margin    = 12,
				right_margin   = 12,
				top_margin     = 10,
				bottom_margin  = 10,
				wrap_mode      = Gtk.WrapMode.NONE,
			};
			text_view.buffer.set_text (body != "" ? body : "(empty body)", -1);
			scrolled.set_child (text_view);
			base.box_main.append (scrolled);

			add_cancel_button ();
		}
	}

	/* ================================================================== */
	/*  Dialog: create a new snippet file for a filetype                   */
	/* ================================================================== */

	public class AddSnippetFiletypeDialog : DialogPopup {
		public signal void saved (string filetype, string path);

		private Gtk.Entry ft_entry;
		private string    save_dir;

		public AddSnippetFiletypeDialog (Gtk.Window parent, string dir) {
			base (parent, "New Snippet File",
				"Enter the filetype name (e.g. python, go, rust)");
			save_dir = dir;

			ft_entry = new Gtk.Entry () {
				placeholder_text = "python",
				hexpand          = true,
			};
			base.box_main.append (ft_entry);
			ft_entry.activate.connect (() => do_save ());

			var create_btn = new Gtk.Button.with_label ("Create") {
				css_classes = {"suggested-action", "button_popup"},
			};
			create_btn.clicked.connect (() => do_save ());
			base.box_buttons.append (create_btn);
			add_cancel_button ();

			ft_entry.grab_focus ();
		}

		private void do_save () {
			var ft = ft_entry.text.strip ().down ();
			if (ft == "") return;
			var path = save_dir + "/" + ft + ".json";
			try {
				DirUtils.create_with_parents (save_dir, 0755);
				if (!FileUtils.test (path, FileTest.EXISTS))
					FileUtils.set_contents (path, "{\n}\n");
				saved (ft, path);
				close ();
			} catch (Error err) {
				set_subtitle_label ("Error: " + err.message);
			}
		}
	}

	/* ================================================================== */
	/*  Dialog: full-text JSON editor for a snippet file                   */
	/* ================================================================== */

	public class SnippetEditorDialog : DialogPopup {
		public signal void saved ();

		private Gtk.TextView text_view;
		private string       file_path;

		public SnippetEditorDialog (Gtk.Window parent, string filetype, string path) {
			base (parent, "Edit — " + filetype, null);
			file_path = path;

			set_default_size (720, 560);

			var scrolled = new Gtk.ScrolledWindow () {
				vexpand        = true,
				hexpand        = true,
				height_request = 440,
			};
			text_view = new Gtk.TextView () {
				monospace     = true,
				left_margin   = 10,
				right_margin  = 10,
				top_margin    = 10,
				bottom_margin = 10,
				wrap_mode     = Gtk.WrapMode.NONE,
			};
			scrolled.set_child (text_view);
			base.box_main.append (scrolled);

			try {
				string content;
				FileUtils.get_contents (path, out content);
				text_view.buffer.set_text (content, -1);
			} catch {
				text_view.buffer.set_text ("{\n}\n", -1);
			}

			var save_btn = new Gtk.Button.with_label ("Save") {
				css_classes = {"suggested-action", "button_popup"},
			};
			save_btn.clicked.connect (() => do_save ());
			base.box_buttons.append (save_btn);
			add_cancel_button ();
		}

		private void do_save () {
			Gtk.TextIter start, end;
			text_view.buffer.get_bounds (out start, out end);
			var content = text_view.buffer.get_text (start, end, false);
			var doc = YYJson.Doc.read (content, content.length);
			if (doc == null) {
				set_subtitle_label ("Invalid JSON — please check your syntax.");
				return;
			}
			try {
				FileUtils.set_contents (file_path, content);
				saved ();
				close ();
			} catch (Error err) {
				set_subtitle_label ("Error saving: " + err.message);
			}
		}
	}
}
