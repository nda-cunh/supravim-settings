/**
 * LspEntry: parsed representation of a .json LSP descriptor file.
 * LspRow: an Adw.ActionRow showing one language server with its
 *         availability status and (for user LSPs) a delete button.
 */
public class LspEntry : Object {
	public string  name;
	public string  command;
	public string  allowed;
	public string? test_command;
	public string? command_help;
	public bool    is_system;
	public string  file_path;

	public static LspEntry? from_file (string path, bool is_system) {
		try {
			string content;
			FileUtils.get_contents (path, out content);
			var doc = YYJson.Doc.read (content, content.length);
			if (doc == null) return null;
			unowned YYJson.Value root = doc.get_root ();
			if (root == null || root.get_type () != YYJson.Type.OBJ) return null;

			var e          = new LspEntry ();
			e.name         = obj_str (root, "name");
			e.command      = obj_str (root, "command");
			e.allowed      = obj_str (root, "allowed");
			e.test_command = obj_str_n (root, "test_command");
			e.command_help = obj_str_n (root, "command_help");
			e.is_system    = is_system;
			e.file_path    = path;
			return (e.name != "") ? e : null;
		} catch (Error err) {
			return null;
		}
	}

	public string to_json () {
		var sb = new StringBuilder ("{\n");
		sb.append_printf ("  \"name\": \"%s\",\n",    j (name));
		sb.append_printf ("  \"command\": \"%s\",\n", j (command));
		sb.append_printf ("  \"allowed\": \"%s\"",    j (allowed));
		if (test_command != null && test_command != "")
			sb.append_printf (",\n  \"test_command\": \"%s\"", j (test_command));
		if (command_help != null && command_help != "")
			sb.append_printf (",\n  \"command_help\": \"%s\"", j (command_help));
		sb.append ("\n}\n");
		return sb.str;
	}

	private static string j (string? s) {
		if (s == null) return "";
		return s.replace ("\\", "\\\\").replace ("\"", "\\\"");
	}

	private static string obj_str (YYJson.Value obj, string key) {
		unowned YYJson.Value? v = obj.obj_get (key);
		if (v == null) return "";
		unowned string? s = v.get_str ();
		return s ?? "";
	}

	private static string? obj_str_n (YYJson.Value obj, string key) {
		unowned YYJson.Value? v = obj.obj_get (key);
		if (v == null) return null;
		return v.get_str ();
	}
}


public class LspRow : Adw.ActionRow {
	private LspEntry _entry;
	public LspEntry entry      { get { return _entry; } }
	public string   search_text;

	private Gtk.Label status_label;

	public signal void deleted ();

	public LspRow (LspEntry entry) {
		_entry      = entry;
		search_text = (entry.name + " " + entry.allowed + " " + entry.command).down ();

		title    = Markup.escape_text (entry.name);
		subtitle = Markup.escape_text (entry.allowed.replace (",", "  ·  "));

		status_label = new Gtk.Label ("…") {
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
		};
		status_label.add_css_class ("dim-label");
		add_suffix (status_label);

		if (entry.is_system) {
			var lock_icon = new Gtk.Image () {
				icon_name    = "changes-prevent-symbolic",
				tooltip_text = "System LSP — read-only",
				halign       = Gtk.Align.CENTER,
				valign       = Gtk.Align.CENTER,
			};
			lock_icon.add_css_class ("dim-label");
			add_suffix (lock_icon);
		} else {
			var del = new Gtk.Button () {
				icon_name    = "user-trash-symbolic",
				tooltip_text = "Delete this LSP",
				halign       = Gtk.Align.CENTER,
				valign       = Gtk.Align.CENTER,
				cursor       = new Gdk.Cursor.from_name ("pointer", null),
			};
			del.add_css_class ("flat");
			del.clicked.connect (() => deleted ());
			add_suffix (del);
		}

		check_available.begin ();
	}

	private async void check_available () {
		// Some entries encode args as "bin,--flag" — use only the binary name.
		var bin = _entry.command.split (",")[0].strip ();
		string output, errput;
		int status = yield Utils.run_async_command (
			"sh -c " + Shell.quote ("command -v " + Shell.quote (bin)),
			out output, out errput);
		status_label.remove_css_class ("dim-label");
		if (status == 0) {
			status_label.add_css_class ("success");
			status_label.label = "Installed";
		} else {
			status_label.add_css_class ("error");
			status_label.label = "Not found";
			if (_entry.command_help != null && _entry.command_help != "")
				this.tooltip_text = "Install: " + _entry.command_help;
		}
	}
}
