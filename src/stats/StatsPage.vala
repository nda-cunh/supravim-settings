[GtkTemplate (ui = "/ui/stats.ui")]
public class StatsPage : Gtk.Box {

	[GtkChild] private unowned Gtk.Box content_box;

	private bool loaded = false;

	private unowned Gtk.ScrolledWindow? heatmap_scroller = null;
	private uint heatmap_scroll_timeout = 0;

	private Supravim.Ach.State state;
	private Supravim.Ach.Defs  defs;

	public void scroll_heatmap_to_end () {
		if (heatmap_scroller == null)
			return;

		if (heatmap_scroll_timeout != 0)
			Source.remove (heatmap_scroll_timeout);
		heatmap_scroll_timeout = Timeout.add (250, () => {
			heatmap_scroll_timeout = 0;
			if (heatmap_scroller != null)
				heatmap_scroller.hadjustment.value = heatmap_scroller.hadjustment.upper;
			return Source.REMOVE;
		});
	}

	public void ensure_loaded () {
		if (loaded)
			return;
		loaded = true;
		load ();
		build_ui ();
	}

	public void refresh () {
		var child = content_box.get_first_child ();
		while (child != null) {
			var next = child.get_next_sibling ();
			content_box.remove (child);
			child = next;
		}
		load ();
		build_ui ();
	}

	private void load () {
		state = new Supravim.Ach.State ();
		defs  = new Supravim.Ach.Defs ();
	}

	private void build_ui () {
		var stack = new Adw.ViewStack ();

		var activity = new Gtk.Box (Gtk.Orientation.VERTICAL, 18);
		activity.append (build_tiles ());
		activity.append (build_heatmap ());
		var langs = build_breakdown ("⌨️  Temps par langage", "lang:");
		if (langs != null)
			activity.append (langs);
		var projs = build_breakdown ("📁  Temps par projet", "proj:");
		if (projs != null)
			activity.append (projs);

		var achievements = new Gtk.Box (Gtk.Orientation.VERTICAL, 18);
		build_achievements (achievements);
		achievements.prepend (build_notify_toggle ());

		stack.add_titled (activity, "activity", "Activité").icon_name = "starred-symbolic";
		stack.add_titled (achievements, "achievements", "Succès").icon_name = "emblem-favorite-symbolic";

		var switcher = new Adw.ViewSwitcher () {
			stack  = stack,
			policy = Adw.ViewSwitcherPolicy.WIDE,
			halign = Gtk.Align.CENTER,
		};

		content_box.append (switcher);
		content_box.append (stack);
	}

	private Gtk.Widget? build_breakdown (string title, string prefix) {
		var bd = state.breakdown (prefix);
		if (bd.size () == 0)
			return null;

		var names = new GenericArray<string> ();
		bd.foreach ((k, v) => names.add (k));
		names.sort_with_data ((a, b) => {
			int64 va = bd[a] ?? 0;
			int64 vb = bd[b] ?? 0;
			return vb > va ? 1 : (vb < va ? -1 : 0);
		});

		int64 max = bd[names[0]] ?? 0;
		if (max <= 0)
			return null;

		var card = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
		card.add_css_class ("stat-card");
		var head = new Gtk.Label (title) { xalign = 0f };
		head.add_css_class ("section-title");
		card.append (head);

		int shown = int.min (8, (int) names.length);
		for (int i = 0; i < shown; i++) {
			int64 secs = bd[names[i]] ?? 0;
			card.append (make_bar_row (names[i], secs, max));
		}
		return card;
	}

	private Gtk.Widget make_bar_row (string name, int64 secs, int64 max) {
		var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

		var label = new Gtk.Label (name) { xalign = 0f, width_request = 110 };
		label.add_css_class ("stat-caption");
		label.ellipsize = Pango.EllipsizeMode.END;

		var bar = new Gtk.ProgressBar () {
			fraction = (double) secs / (double) max,
			hexpand  = true,
			valign   = Gtk.Align.CENTER,
		};
		bar.add_css_class ("stat-bar");

		var dur = new Gtk.Label (fmt_duration (secs)) { xalign = 1f, width_request = 70 };
		dur.add_css_class ("stat-bar-dur");

		row.append (label);
		row.append (bar);
		row.append (dur);
		return row;
	}

	public static bool notify_enabled () {
		string path = Path.build_filename (
			Environment.get_user_config_dir (), "supravim", "state.json");
		string data;
		try { FileUtils.get_contents (path, out data); }
		catch (Error e) { return true; }
		var doc = YYJson.Doc.read (data, data.length);
		if (doc == null)
			return true;
		unowned var opts = doc.get_root ().obj_get ("options");
		if (opts == null)
			return true;
		unowned var v = opts.obj_get ("achievement_notify");
		return v == null || v.get_bool ();
	}

	private Gtk.Widget build_notify_toggle () {
		var group = new Adw.PreferencesGroup ();
		var sw = new Gtk.Switch () {
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			active = notify_enabled (),
		};
		var row = new Adw.ActionRow () {
			title       = "Notifications de succès",
			subtitle    = "Afficher une notification quand un succès est débloqué",
			activatable_widget = sw,
		};
		row.add_suffix (sw);
		sw.notify["active"].connect (() => {
			string v = sw.active ? "true" : "false";
			if (from_supravim) {
				print ("onChangeOption: [achievement_notify] <%s>\n", v);
			} else {
				try {
					Supravim.Options.update_value ("achievement_notify", v);
				} catch (Error e) {
					warning ("option update: %s", e.message);
				}
			}
		});
		group.add (row);
		return group;
	}

	private int unlocked_count () {
		int n = 0;
		foreach (unowned Supravim.Ach.Def d in defs.list.data)
			if (state.is_unlocked (d.id))
				n++;
		return n;
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

		int total = (int) defs.list.length;
		flow.append (make_tile ("🏆", @"$(unlocked_count ()) / $(total)", "Succès débloqués"));
		flow.append (make_tile ("⏱️", fmt_duration (state.total_of ("active_sec")), "Temps de code"));
		flow.append (make_tile ("🔥", @"$(state.streak) j", "Streak"));
		flow.append (make_tile ("📅", @"$(state.distinct_days) j", "Jours actifs"));
		flow.append (make_tile ("📈", @"$(state.best_streak) j", "Meilleur streak"));
		flow.append (make_tile ("📏", fmt_int (state.counter ("lines")), "Lignes écrites"));
		flow.append (make_tile ("📝", fmt_int (state.counter ("words")), "Mots écrits"));
		flow.append (make_tile ("🔤", fmt_int (state.counter ("chars")), "Caractères"));
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
			int64 secs = state.day_value (ds, "active_sec");

			var cell = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
				width_request  = 13,
				height_request = 13,
			};
			cell.add_css_class ("hm-cell");
			cell.add_css_class ("hm-b" + bucket_of (secs).to_string ());
			int64 mins = secs / 60;
			int64 lines = state.day_value (ds, "lines");
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
		heatmap_scroller = scroller;

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

	private static string cat_title (Supravim.Ach.Category c) {
		return c.icon == "" ? c.label : c.icon + "  " + c.label;
	}

	private void build_achievements (Gtk.Box container) {
		foreach (unowned Supravim.Ach.Category c in defs.categories.data) {
			int total = 0;
			int got   = 0;
			foreach (unowned Supravim.Ach.Def d in defs.list.data) {
				if (d.cat != c.id)
					continue;
				total++;
				if (state.is_unlocked (d.id))
					got++;
			}
			if (total == 0)
				continue;

			var group = new Adw.PreferencesGroup () {
				title       = cat_title (c),
				description = @"$(got) / $(total) débloqués",
			};

			foreach (unowned Supravim.Ach.Def d in defs.list.data)
				if (d.cat == c.id)
					group.add (make_ach_row (d));
			container.append (group);
		}
	}

	private Gtk.Widget make_ach_row (Supravim.Ach.Def d) {
		bool is_unlocked = state.is_unlocked (d.id);
		bool masked = d.hidden && !is_unlocked;

		var row = new Adw.ActionRow () {
			title    = masked ? "???" : d.title,
			subtitle = masked ? "Succès secret — à découvrir" : markdown_bold (d.desc),
		};

		var icon = new Gtk.Label (masked ? "❓" : d.icon);
		icon.add_css_class ("ach-icon");
		row.add_prefix (icon);

		if (is_unlocked) {
			var badge = new Gtk.Label ("✓ " + state.unlocked_at (d.id)) { valign = Gtk.Align.CENTER };
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
