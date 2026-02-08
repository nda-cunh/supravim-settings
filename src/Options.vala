/**
 * Options supravim settings
 */
[GtkTemplate (ui = "/ui/options.ui")]
public class OptionsPage :  Gtk.Box { 
	// BluePrint Variable
	[GtkChild]
	private unowned Adw.PreferencesGroup options_group;

	public GroupONode nodes_general = new GroupONode("general");
	// public GroupONode nodes_plugin = new GroupONode("general");

	construct {
		parse_status.begin( () => {
			add_options_to_group(nodes_general, options_group);
		});
	}

	/**
	  * recursively add options to the group
	  */
	private void add_options_to_group(GroupONode node, Gtk.Widget row_base) {
		foreach (unowned var child in node) {
			if (child is GroupONode) {
				var row = new Adw.ExpanderRow () {
					title = child.name_of_group,
					subtitle = child.lore_of_group
				};
				add_options_to_group(child as GroupONode, row);
				if (row_base is Adw.ExpanderRow)
					row_base.add_row (row);
				else if (row_base is Adw.PreferencesGroup)
					row_base.add (row);
			}
			else if (child is OptionsONode) {
				if (row_base is Adw.ExpanderRow)
					row_base.add_row (new RowOptions(child as OptionsONode));
				else if (row_base is Adw.PreferencesGroup)
					row_base.add (new RowOptions(child as OptionsONode));
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
				options.foreach ((v) => {
					nodes_general.add_element (v);
				});
			}
			catch (Error e) {
				warning (e.message);
			}
			Idle.add(parse_status.callback);
		});
		yield;
	}
}
