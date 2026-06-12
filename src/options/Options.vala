/**
 * Options supravim settings
 */
[GtkTemplate (ui = "/ui/options.ui")]
public class OptionsPage : Gtk.Box {
	[GtkChild]
	private unowned Gtk.SearchEntry search_entry;

	[GtkChild]
	private unowned Gtk.DropDown type_dropdown;

	[GtkChild]
	private unowned Adw.PreferencesGroup options_group;

	public GroupONode nodes_general = new GroupONode("general");

	// Maps dropdown index → type string expected by RowOptions (null = all)
	private static string?[] TYPE_FILTER = { null, "bool", "number", "string" };

	construct {
		parse_status.begin (() => {
			add_options_to_group (nodes_general, options_group);
		});
	}

	/* ------------------------------------------------------------------ */
	/*  Callbacks (wired from Blueprint)                                   */
	/* ------------------------------------------------------------------ */

	[GtkCallback]
	public void on_search_changed () {
		apply_filter ();
	}

	[GtkCallback]
	public void on_type_changed () {
		apply_filter ();
	}

	/* ------------------------------------------------------------------ */
	/*  Filtering                                                          */
	/* ------------------------------------------------------------------ */

	private void apply_filter () {
		string query = search_entry.get_text ().down ().strip ();
		uint sel = type_dropdown.selected;
		string? type_filter = (sel < TYPE_FILTER.length) ? TYPE_FILTER[sel] : null;
		filter_recursive (options_group, query, type_filter);
	}

	private bool filter_recursive (Gtk.Widget container, string query, string? type_filter) {
		bool found = false;

		string[] parts = query.split (" ");
		GenericArray<string> keywords = new GenericArray<string> ();
		foreach (unowned string k in parts) {
			if (k._strip () != "")
				keywords.add (k.down ());
		}

		for (var child = container.get_first_child (); child != null; child = child.get_next_sibling ()) {
			bool visible = false;

			if (child is Adw.ActionRow && !(child is Adw.ExpanderRow)) {
				var row = (Adw.ActionRow) child;

				// Type filter
				if (type_filter != null && row is RowOptions) {
					var opt_row = row as RowOptions;
					if (opt_row.get_type_value () != type_filter) {
						child.visible = false;
						continue;
					}
				}

				string content = ((row.subtitle ?? "")).down ();
				if (row is RowOptions) {
					var opt_row = row as RowOptions;
					content += " " + opt_row.get_node_name ().down ();
				}

				bool match = true;
				for (int i = 0; i < keywords.length; i++) {
					if (!(keywords.get (i) in content)) {
						match = false;
						break;
					}
				}
				visible = (keywords.length == 0 || match);
			}
			else if (child is Adw.ExpanderRow) {
				var expander = (Adw.ExpanderRow) child;
				string title = (expander.title ?? "").down ();

				bool title_match = keywords.length > 0;
				for (int i = 0; i < keywords.length; i++) {
					if (!(keywords.get (i) in title)) {
						title_match = false;
						break;
					}
				}

				bool children_match = filter_recursive (expander, query, type_filter);
				visible = (keywords.length == 0 && type_filter == null) || title_match || children_match;
				expander.expanded = (keywords.length > 0 || type_filter != null) && children_match;
			}
			else {
				if (filter_recursive (child, query, type_filter)) found = true;
				continue;
			}

			child.visible = visible;
			if (visible) found = true;
		}

		return found;
	}

	/* ------------------------------------------------------------------ */
	/*  Building the widget tree                                           */
	/* ------------------------------------------------------------------ */

	private void add_options_to_group (GroupONode node, Gtk.Widget row_base) {
		foreach (unowned var child in node) {
			if (child is OptionsONode) {
				var row = new RowOptions (child as OptionsONode);
				if (row_base is Adw.ExpanderRow)
					((Adw.ExpanderRow) row_base).add_row (row);
				else if (row_base is Adw.PreferencesGroup)
					((Adw.PreferencesGroup) row_base).add (row);
			}
		}

		foreach (unowned var child in node) {
			if (child is GroupONode) {
				var row = new Adw.ExpanderRow () {
					title = child.name_of_group,
					subtitle = child.lore_of_group
				};
				add_options_to_group (child as GroupONode, row);
				if (row_base is Adw.ExpanderRow)
					((Adw.ExpanderRow) row_base).add_row (row);
				else if (row_base is Adw.PreferencesGroup)
					((Adw.PreferencesGroup) row_base).add (row);
			}
		}
	}

	/* ------------------------------------------------------------------ */
	/*  Loading options                                                    */
	/* ------------------------------------------------------------------ */

	private async void parse_status () {
		new Thread<void> (null, () => {
			try {
				var options = ListSupraOptions.from_vim ();
				options.sort ((a, b) => (a.id > b.id) ? 1 : -1);
				foreach (var v in options)
					nodes_general.add_element (v);
			}
			catch (Error e) {
				warning (e.message);
			}
			Idle.add (parse_status.callback);
		});
		yield;
	}
}
