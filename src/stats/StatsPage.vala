[GtkTemplate (ui = "/ui/stats.ui")]
public class StatsPage : Gtk.Box {

	[GtkChild] private unowned Gtk.Box content_box;

	private bool loaded = false;

	private HashTable<string, int64?> counters      = new HashTable<string, int64?> (str_hash, str_equal);
	private HashTable<string, int64?> active_by_day  = new HashTable<string, int64?> (str_hash, str_equal);
	private HashTable<string, int64?> lines_by_day   = new HashTable<string, int64?> (str_hash, str_equal);
	private HashTable<string, string> unlocked       = new HashTable<string, string> (str_hash, str_equal);

	private int64 streak        = 0;
	private int64 best_streak   = 0;
	private int64 distinct_days = 0;
	private int64 total_active  = 0;

	private GenericArray<Def> defs = new GenericArray<Def> ();

	private class Def {
		public string id;
		public string cat;
		public string icon;
		public string title;
		public string desc;
		public bool hidden;
	}

	private const string[] CAT_ORDER = {
		"onboarding", "motions", "volume", "humour", "ecosystem", "prestige"
	};

	private static string cat_label (string cat) {
		switch (cat) {
		case "onboarding": return "🐣  Débutant";
		case "motions":    return "⚔️  Motions & voie du Vim";
		case "volume":     return "✍️  Volume & endurance";
		case "humour":     return "😅  Auto-dérision";
		case "ecosystem":  return "🎮  Écosystème SupraVim";
		case "prestige":   return "🏆  Prestige";
		default:           return cat;
		}
	}

	public void ensure_loaded () {
		if (loaded)
			return;
		loaded = true;
		load_state ();
		load_defs ();
		build_ui ();
	}

	public void refresh () {
		counters.remove_all ();
		active_by_day.remove_all ();
		lines_by_day.remove_all ();
		unlocked.remove_all ();
		streak = best_streak = distinct_days = total_active = 0;
		defs = new GenericArray<Def> ();
		var child = content_box.get_first_child ();
		while (child != null) {
			var next = child.get_next_sibling ();
			content_box.remove (child);
			child = next;
		}
		load_state ();
		load_defs ();
		build_ui ();
	}

	private int64 get_counter (string k) { return counters[k] ?? 0; }

	private void load_state () {
		string path = Path.build_filename (
			Environment.get_user_config_dir (), "supravim", "achievements.json");
		if (!FileUtils.test (path, FileTest.EXISTS))
			return;
		string data;
		try { FileUtils.get_contents (path, out data); }
		catch (Error e) { return; }

		var doc = YYJson.Doc.read (data, data.length);
		if (doc == null)
			return;
		unowned var root = doc.get_root ();

		read_int_map (root.obj_get ("counters"), counters);
		read_str_map (root.obj_get ("unlocked"), unlocked);

		unowned var hist = root.obj_get ("history");
		if (hist != null) {
			YYJson.ObjIter it;
			if (YYJson.ObjIter.init (hist, out it)) {
				unowned YYJson.Value? key;
				while ((key = it.next ()) != null) {
					unowned var bucket = YYJson.ObjIter.get_val (key);
					if (bucket == null) continue;
					unowned var act = bucket.obj_get ("active_sec");
					unowned var lin = bucket.obj_get ("lines");
					int64 a = act != null ? (int64) act.get_int () : 0;
					active_by_day[key.get_str ()] = a;
					total_active += a;
					if (lin != null)
						lines_by_day[key.get_str ()] = (int64) lin.get_int ();
				}
			}
		}

		unowned var meta = root.obj_get ("meta");
		if (meta != null) {
			unowned var s = meta.obj_get ("streak");
			unowned var b = meta.obj_get ("best_streak");
			unowned var d = meta.obj_get ("distinct_days");
			if (s != null) streak        = s.get_int ();
			if (b != null) best_streak   = b.get_int ();
			if (d != null) distinct_days = d.get_int ();
		}
	}

	private void read_int_map (YYJson.Value? obj, HashTable<string, int64?> dest) {
		if (obj == null) return;
		YYJson.ObjIter it;
		if (!YYJson.ObjIter.init (obj, out it)) return;
		unowned YYJson.Value? key;
		while ((key = it.next ()) != null) {
			unowned var v = YYJson.ObjIter.get_val (key);
			if (v != null) dest[key.get_str ()] = (int64) v.get_int ();
		}
	}

	private void read_str_map (YYJson.Value? obj, HashTable<string, string> dest) {
		if (obj == null) return;
		YYJson.ObjIter it;
		if (!YYJson.ObjIter.init (obj, out it)) return;
		unowned YYJson.Value? key;
		while ((key = it.next ()) != null) {
			unowned var v = YYJson.ObjIter.get_val (key);
			if (v != null) dest[key.get_str ()] = v.get_str ();
		}
	}

	private void load_defs () {
		string? path = find_defs_file ();
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
			if (id_v == null) continue;
			var d = new Def ();
			d.id    = id_v.get_str ();
			d.cat   = str_field (e, "cat");
			d.icon  = str_field (e, "icon");
			d.title = str_field (e, "title");
			d.desc  = str_field (e, "desc");
			unowned var h = e.obj_get ("hidden");
			d.hidden = h != null && h.get_bool ();
			defs.add (d);
		}
	}

	private static string str_field (YYJson.Value e, string key) {
		unowned var v = e.obj_get (key);
		return v != null ? v.get_str () : "";
	}

	private static string? find_defs_file () {
		string user = Path.build_filename (
			Environment.get_user_data_dir (), "supravim", "achievements.json");
		if (FileUtils.test (user, FileTest.EXISTS)) return user;
		foreach (unowned string sys in Environment.get_system_data_dirs ()) {
			string p = Path.build_filename (sys, "supravim", "achievements.json");
			if (FileUtils.test (p, FileTest.EXISTS)) return p;
		}
		return null;
	}

	private void build_ui () {
		content_box.append (build_tiles ());
		content_box.append (build_heatmap ());
		build_achievements ();
	}

	private Gtk.Widget build_tiles () {
		var flow = new Gtk.FlowBox () {
			selection_mode      = Gtk.SelectionMode.NONE,
			homogeneous         = true,
			column_spacing      = 12,
			row_spacing         = 12,
			min_children_per_line = 2,
			max_children_per_line = 4,
		};

		int unlocked_count = 0;
		for (int i = 0; i < (int) defs.length; i++)
			if (defs.data[i].id in unlocked)
				unlocked_count++;

		flow.append (make_tile ("🏆", @"$(unlocked_count) / $((int) defs.length)", "Succès débloqués"));
		flow.append (make_tile ("⏱️", fmt_duration (total_active), "Temps de code"));
		flow.append (make_tile ("🔥", @"$(streak) j", "Streak"));
		flow.append (make_tile ("📅", @"$(distinct_days) j", "Jours actifs"));
		flow.append (make_tile ("📈", @"$(best_streak) j", "Meilleur streak"));
		flow.append (make_tile ("📏", fmt_int (get_counter ("lines")), "Lignes écrites"));
		flow.append (make_tile ("📝", fmt_int (get_counter ("words")), "Mots écrits"));
		flow.append (make_tile ("🔤", fmt_int (get_counter ("chars")), "Caractères"));
		return flow;
	}

	private Gtk.Widget make_tile (string emoji, string value, string caption) {
		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2) {
			halign = Gtk.Align.FILL,
		};
		box.add_css_class ("stat-tile");

		var top = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
		var em = new Gtk.Label (emoji);
		em.add_css_class ("stat-emoji");
		var val = new Gtk.Label (value) { xalign = 0f, hexpand = true };
		val.add_css_class ("stat-value");
		top.append (em);
		top.append (val);

		var cap = new Gtk.Label (caption) { xalign = 0f };
		cap.add_css_class ("stat-caption");

		box.append (top);
		box.append (cap);
		return box;
	}

	private Gtk.Widget build_heatmap () {
		var card = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		card.add_css_class ("stat-card");

		var title = new Gtk.Label ("Activité de code — dernière année") { xalign = 0f };
		title.add_css_class ("section-title");
		card.append (title);

		var now = new DateTime.now_local ();
		int dow = now.get_day_of_week () - 1;
		int weeks = 53;
		int total = weeks * 7;
		var start = now.add_days (- (52 * 7 + dow));

		var grid = new Gtk.Grid () {
			row_spacing    = 3,
			column_spacing = 3,
		};

		for (int d = 0; d < total; d++) {
			var day = start.add_days (d);
			if (day.compare (now) > 0)
				break;
			int col = d / 7;
			int row = d % 7;
			string ds = day.format ("%Y-%m-%d");
			int64 secs = active_by_day[ds] ?? 0;

			var cell = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
				width_request  = 13,
				height_request = 13,
			};
			cell.add_css_class ("hm-cell");
			cell.add_css_class ("hm-b" + bucket_of (secs).to_string ());
			int64 mins = secs / 60;
			int64 lines = lines_by_day[ds] ?? 0;
			cell.tooltip_text = mins > 0
				? @"$(ds) — $(mins) min de code, $(lines) lignes"
				: @"$(ds) — aucune activité";
			grid.attach (cell, col, row, 1, 1);
		}

		var scroller = new Gtk.ScrolledWindow () {
			hscrollbar_policy = Gtk.PolicyType.AUTOMATIC,
			vscrollbar_policy = Gtk.PolicyType.NEVER,
			child             = grid,
		};

		unowned var hadj = scroller.hadjustment;
		ulong id = 0;
		id = hadj.changed.connect (() => {
			if (hadj.upper > hadj.page_size) {
				hadj.value = hadj.upper - hadj.page_size;
				hadj.disconnect (id);
			}
		});

		card.append (scroller);
		card.append (build_legend ());
		return card;
	}

	private Gtk.Widget build_legend () {
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5) { halign = Gtk.Align.END };
		box.append (new Gtk.Label ("Moins") { css_classes = { "stat-caption" } });
		for (int i = 0; i <= 4; i++) {
			var c = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
				width_request = 13, height_request = 13,
			};
			c.add_css_class ("hm-cell");
			c.add_css_class ("hm-b" + i.to_string ());
			box.append (c);
		}
		box.append (new Gtk.Label ("Plus") { css_classes = { "stat-caption" } });
		return box;
	}

	private static int bucket_of (int64 secs) {
		int64 m = secs / 60;
		if (m <= 0)  return 0;
		if (m < 15)  return 1;
		if (m < 45)  return 2;
		if (m < 90)  return 3;
		return 4;
	}

	private void build_achievements () {
		foreach (unowned string cat in CAT_ORDER) {
			int total = 0;
			int got   = 0;
			for (int i = 0; i < (int) defs.length; i++) {
				if (defs.data[i].cat != cat) continue;
				total++;
				if (defs.data[i].id in unlocked) got++;
			}
			if (total == 0)
				continue;

			var group = new Adw.PreferencesGroup () {
				title       = cat_label (cat),
				description = @"$(got) / $(total) débloqués",
			};

			for (int i = 0; i < (int) defs.length; i++) {
				unowned var d = defs.data[i];
				if (d.cat != cat) continue;
				group.add (make_ach_row (d));
			}
			content_box.append (group);
		}
	}

	private Gtk.Widget make_ach_row (Def d) {
		bool is_unlocked = d.id in unlocked;
		bool masked = d.hidden && !is_unlocked;

		var row = new Adw.ActionRow () {
			title    = masked ? "???" : d.title,
			subtitle = masked ? "Succès secret — à découvrir" : markdown_bold (d.desc),
		};

		var icon = new Gtk.Label (masked ? "❓" : d.icon);
		icon.add_css_class ("ach-icon");
		row.add_prefix (icon);

		if (is_unlocked) {
			var badge = new Gtk.Label ("✓ " + unlocked[d.id]) { valign = Gtk.Align.CENTER };
			badge.add_css_class ("ach-unlocked-badge");
			row.add_suffix (badge);
		} else {
			var lockicon = new Gtk.Label ("🔒") { valign = Gtk.Align.CENTER };
			row.add_suffix (lockicon);
			row.add_css_class ("ach-locked");
		}
		return row;
	}

	private static string markdown_bold (string s) {
		try {
			var re = new Regex ("\\*\\*(.+?)\\*\\*");
			return re.replace (s, s.length, 0, "<b>\\1</b>");
		} catch (Error e) {
			return s;
		}
	}

	private static string fmt_duration (int64 secs) {
		int64 h = secs / 3600;
		int64 m = (secs % 3600) / 60;
		if (h > 0)
			return @"$(h)h $(m)m";
		return @"$(m)m";
	}

	private static string fmt_int (int64 n) {
		if (n >= 1000000)
			return "%.1fM".printf (n / 1000000.0);
		if (n >= 1000)
			return "%.1fk".printf (n / 1000.0);
		return n.to_string ();
	}
}
