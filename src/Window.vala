/**
 * The Window widget of the application.
 */
[GtkTemplate (ui = "/ui/window.ui")]
public class MainWindow : Adw.ApplicationWindow {

	private bool wiki_loaded = false;

	public MainWindow(Gtk.Application app) throws Error {
		Object(application: app);

		home_page.parent_window = this;
		base.set_cursor_from_name ("default");
		base.set_icon_name("supravim");

		viewstack.notify["visible-child-name"].connect (load_visible_page);
		load_visible_page ();

		var konami_ctrl = new Gtk.EventControllerKey ();
		konami_ctrl.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
		konami_ctrl.key_pressed.connect ((keyval, keycode, state) => {
			uint k = Gdk.keyval_to_lower (keyval);
			if (k == KONAMI[konami_pos]) {
				konami_pos++;
				if (konami_pos >= KONAMI.length) {
					konami_pos = 0;
					Utils.ach_metric ("konami");
					do_toast_ach ("konami");
				}
			} else {
				konami_pos = (k == KONAMI[0]) ? 1 : 0;
			}
			return false;
		});
		((Gtk.Widget) this).add_controller (konami_ctrl);

		seed_achievements ();
		current_window = this;
	}

	private static unowned MainWindow? current_window = null;
	private HashTable<string, bool>   ach_unlocked = new HashTable<string, bool> (str_hash, str_equal);
	private HashTable<string, string> ach_titles   = new HashTable<string, string> (str_hash, str_equal);

	private void seed_achievements () {
		load_ach_titles ();
		foreach (unowned string id in read_unlocked ().get_keys ())
			ach_unlocked[id] = true;
	}

	/**
	 * Show a toast for the achievement `id` if it is not already unlocked.
	 * Called from GUI actions that grant an achievement (konami, wiki, …).
	 */
	public static void toast_ach (string id) {
		if (current_window != null)
			current_window.do_toast_ach (id);
	}

	private void do_toast_ach (string id) {
		if (id in ach_unlocked)
			return;
		ach_unlocked[id] = true;
		string? info = ach_titles[id];
		string label;
		if (info != null) {
			var parts = info.split ("\t", 2);
			label = "🏆 " + parts[0] + "  " + (parts.length > 1 ? parts[1] : id);
		} else {
			label = "🏆 " + id;
		}
		toast_overlay.add_toast (new Adw.Toast (label) { timeout = 4 });
	}

	private HashTable<string, bool> read_unlocked () {
		var res = new HashTable<string, bool> (str_hash, str_equal);
		string path = Path.build_filename (Environment.get_user_config_dir (), "supravim", "achievements.json");
		if (!FileUtils.test (path, FileTest.EXISTS))
			return res;
		string data;
		try { FileUtils.get_contents (path, out data); }
		catch (Error e) { return res; }
		var doc = YYJson.Doc.read (data, data.length);
		if (doc == null)
			return res;
		unowned var un = doc.get_root ().obj_get ("unlocked");
		if (un == null)
			return res;
		YYJson.ObjIter it;
		if (YYJson.ObjIter.init (un, out it)) {
			unowned YYJson.Value? key;
			while ((key = it.next ()) != null)
				res[key.get_str ()] = true;
		}
		return res;
	}

	private void load_ach_titles () {
		string? path = null;
		string user = Path.build_filename (Environment.get_user_data_dir (), "supravim", "achievements.json");
		if (FileUtils.test (user, FileTest.EXISTS)) {
			path = user;
		} else {
			foreach (unowned string sys in Environment.get_system_data_dirs ()) {
				string p = Path.build_filename (sys, "supravim", "achievements.json");
				if (FileUtils.test (p, FileTest.EXISTS)) { path = p; break; }
			}
		}
		if (path == null)
			return;
		string data;
		try { FileUtils.get_contents (path, out data); }
		catch (Error e) { return; }
		var doc = YYJson.Doc.read (data, data.length);
		if (doc == null)
			return;
		unowned var arr = doc.get_root ().obj_get ("achievements");
		if (arr == null)
			return;
		for (size_t i = 0; i < arr.arr_size (); i++) {
			unowned var e = arr.arr_get (i);
			unowned var id_v = e.obj_get ("id");
			if (id_v == null)
				continue;
			unowned var ic = e.obj_get ("icon");
			unowned var ti = e.obj_get ("title");
			ach_titles[id_v.get_str ()] =
				(ic != null ? ic.get_str () : "🏆") + "\t" + (ti != null ? ti.get_str () : id_v.get_str ());
		}
	}

	private const uint[] KONAMI = {
		Gdk.Key.Up, Gdk.Key.Up, Gdk.Key.Down, Gdk.Key.Down,
		Gdk.Key.Left, Gdk.Key.Right, Gdk.Key.Left, Gdk.Key.Right,
		Gdk.Key.b, Gdk.Key.a
	};
	private int konami_pos = 0;

	/**
	 * Build the content of the currently visible page on first display.
	 * Pages already loaded just return early (each keeps its own guard).
	 */
	private void load_visible_page () {
		switch (viewstack.visible_child_name) {
		case "plugins":
			plugins_page.ensure_loaded ();
			break;
		case "lsp":
			lsp_page.ensure_loaded ();
			break;
		case "stats":
			stats_page.ensure_loaded ();
			break;
		case "snippets":
			snippets_page.ensure_loaded ();
			break;
		case "wiki":
			Utils.ach_metric ("wiki_open");
			do_toast_ach ("rtfm");
			if (!wiki_loaded) {
				wiki_loaded = true;
				wiki_box.append (new Wiki (Environment.get_home_dir () + "/.local/share/supravim-gui/"));
			}
			break;
		default:
			break;
		}
	}

	/* BluePrint Variable */
	[GtkChild]
	unowned Adw.ToastOverlay toast_overlay;
	[GtkChild]
	unowned Adw.ViewStack viewstack;
	[GtkChild]
	public unowned OptionsPage options_page;
	[GtkChild]
	public unowned LspPage lsp_page;
	[GtkChild]
	public unowned StatsPage stats_page;
	[GtkChild]
	public unowned SnippetsPage snippets_page;
	[GtkChild]
	public unowned HomePage home_page;
	[GtkChild]
	public unowned PluginsPage plugins_page;
	[GtkChild]
	unowned Gtk.Box wiki_box; 
}
