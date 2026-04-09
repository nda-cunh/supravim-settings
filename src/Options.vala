/**
 * Options supravim settings
 */
[GtkTemplate (ui = "/ui/options.ui")]
public class OptionsPage :  Gtk.Box { 
	// BluePrint Variable
	[GtkChild]
	private unowned Adw.PreferencesGroup options_group;

	[GtkChild]
	private unowned Gtk.SearchBar search_bar;

	[GtkChild]
	private unowned Gtk.SearchEntry search_entry;

	public GroupONode nodes_general = new GroupONode("general");

	construct {
		parse_status.begin( () => {
			add_options_to_group(nodes_general, options_group);
		});

		search_bar.set_key_capture_widget (base);
		Gtk.Editable editable = search_entry;
		editable.changed.connect (search);
	}

	public void search () {
		string query = search_entry.get_text().down();
		// On commence le filtrage à partir du groupe racine
		filter_recursive (options_group, query);
	}

	private bool filter_recursive (Gtk.Widget container, string query) {
		bool found_at_least_one = false;
		
		string[] keywords = query.split (" ");
		GenericArray<string> active_keywords = new GenericArray<string> ();
		foreach (unowned string k in keywords) {
			if (k._strip () != "")
				active_keywords.add (k.down ());
		}

		for (var child = container.get_first_child(); child != null; child = child.get_next_sibling()) {
			bool is_visible = false;

			if (child is Adw.ActionRow && !(child is Adw.ExpanderRow)) {
				var row = (Adw.ActionRow) child;
				string content = ((row.subtitle ?? "")).down ();
				if (row is RowOptions) {
					var option_row = row as RowOptions;
					content += " " + option_row.get_node_name().down ();
				}
				
				bool match = true;
				for (int i = 0; i < active_keywords.length; i++) {
					if (!(active_keywords.get(i) in content)) {
						match = false;
						break;
					}
				}
				is_visible = (active_keywords.length == 0 || match);
			} 
			else if (child is Adw.ExpanderRow) {
				var expander = (Adw.ExpanderRow) child;
				string title = (expander.title ?? "").down ();
				
				bool title_matches = active_keywords.length > 0;
				for (int i = 0; i < active_keywords.length; i++) {
					if (!(active_keywords.get(i) in title)) {
						title_matches = false;
						break;
					}
				}
				
				bool children_match = filter_recursive (expander, query);
				is_visible = (active_keywords.length == 0 || title_matches || children_match);
				expander.expanded = (active_keywords.length > 0 && children_match);
			}
			else {
				if (filter_recursive (child, query)) found_at_least_one = true;
				continue;
			}

			child.visible = is_visible;
			if (is_visible) found_at_least_one = true;
		}

		return found_at_least_one;
	}


	private void add_options_to_group(GroupONode node, Gtk.Widget row_base) {
		foreach (unowned var child in node) {
			if (child is OptionsONode) {
				var row = new RowOptions(child as OptionsONode);
				if (row_base is Adw.ExpanderRow)
					((Adw.ExpanderRow)row_base).add_row(row);
				else if (row_base is Adw.PreferencesGroup)
					((Adw.PreferencesGroup)row_base).add(row);
			}
		}

		foreach (unowned var child in node) {
			if (child is GroupONode) {
				var row = new Adw.ExpanderRow () {
					title = child.name_of_group,
						  subtitle = child.lore_of_group
				};
				add_options_to_group(child as GroupONode, row);
				if (row_base is Adw.ExpanderRow)
					((Adw.ExpanderRow)row_base).add_row(row);
				else if (row_base is Adw.PreferencesGroup)
					((Adw.PreferencesGroup)row_base).add(row);
			}
		}
	}

	/**
	 * parse the supravim --status output
	 * and fill the options nodes (general and plugin)
	 */
	private async void parse_status () {
		new Thread<void>(null, () => {
			try {
				var options = SupraParser.get_from_vim ();
				options.sort ((a, b) => {
					return (a.id > b.id) ? 1 : -1;
				});
				foreach (var v in options) {
					nodes_general.add_element (v);
				}
			}
			catch (Error e) {
				warning (e.message);
			}
			Idle.add(parse_status.callback);
		});
		yield;
	}
}
