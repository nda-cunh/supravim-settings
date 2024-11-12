using Gtk;

[GtkTemplate (ui = "/ui/wiki.ui")]
public class Wiki : Gtk.Box {

	private string basename;
	private MarkDown markdown;
	List<string> list = new List<string> ();
	int index_list = -1;

	construct {
		box_revealer.add_controller (motion);
	}
	/** 
	* Constructor for the Wiki class
	* 
	* @param basename The base name of the wiki file
	*/
	public Wiki (string basename) {
		this.basename = basename;

		markdown = new MarkDown() {
			hexpand = true,
			vexpand = true,
			margin_start = 10,
			margin_end = 10,
			margin_top = 10,
		};
		markdown.activate_link.connect (click_link);
		markdown_box.append(markdown);
		markdown.path_dir = basename;
		load_sidebar();
	}

	private void change_page (string uri) {
		markdown.clear();
		markdown.load_file (uri);
		pagename.label = uri.offset(uri.last_index_of ("/") + 1);
	}

	private bool click_link (string uri) {
		print ("Clicked on link: %s\n", uri);
		if (uri.has_prefix ("http")) {
			return false;
		}
		var tmp = @"$basename/$uri.md";
		change_page (tmp);
		if (index_list < list.length() - 1) {
			var tmp_lst = new List<string>();
			for (int i = 0; i <= index_list; i++) {
				tmp_lst.append (list.nth_data(i));
			}
			list = (owned)tmp_lst;
		}
		list.append (tmp);
		index_list++;
		return false;
	}

	private void load_sidebar () {
		MatchInfo info;
		string contents;
		FileUtils.get_contents (basename + "_sidebar.md", out contents);
		contents = contents.replace ("\r", "");
		var regex = new Regex("""\[(?P<name>.+?)\]\((?P<url>.+?)\)""");
		string? first_link = null;

		if  (regex.match (contents, 0, out info)) {
			do {
				var name = info.fetch_named("name");
				var url = info.fetch_named("url");
				if (first_link == null)
					first_link = url;
				var button = new Button.with_label (name) {
					has_frame = false,
				};
				button.clicked.connect (() => click_link (url));
				sidebar.append(button);
			} while (info.next());
		}
		click_link (first_link);
	}
	[GtkCallback]
	private void sig_previous () {
		if (index_list > 0) {
			index_list--;
			change_page (list.nth_data(index_list));
		}
	}
	[GtkCallback]
	private void sig_next () {
		if (index_list < list.length()  - 1) {
			index_list++;
			change_page (list.nth_data(index_list));
		}
	}

	[GtkChild]
	unowned EventControllerMotion motion;
	[GtkChild]
	unowned Box box_revealer;
	[GtkChild]
	unowned Label pagename;
	[GtkChild]
	unowned Box markdown_box;
	[GtkChild]
	unowned Box sidebar;
}
