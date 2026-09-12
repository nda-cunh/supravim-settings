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
			halign = Align.CENTER,
			margin_start = 10,
			margin_end = 10,
			margin_top = 10,
		};
		markdown.activate_link.connect (click_link);
		markdown_box.append(markdown);
		load.begin();
	}

	private async void clone_wiki () {
		stack.set_visible_child_name ("loading");
		DirUtils.create_with_parents (this.basename, 0755);
		yield Utils.run_async_command(@"git clone https://gitlab.com/nda-cunh/SupraVim.wiki.git $(this.basename) --depth 1");
	}


	private async void load () {
		try {
			if (FileUtils.test(this.basename, FileTest.IS_DIR | FileTest.EXISTS) == false) {
				printerr ("Wiki folder not found\n");
				throw new FileError.ACCES("Wiki folder not found");
			}
			else {
				Process.spawn_async(this.basename, {"git", "pull"}, null, SEARCH_PATH, null, null);
			}
			load_sidebar();
			stack.set_visible_child_name ("wiki");
		}
		catch (Error e) {
			printerr ("Retry\n");
			if (e is FileError.ACCES) {
				yield clone_wiki();
				load.begin();
			}
			else {
				Timeout.add(1000, () => {
					load.begin();
					return false;
				});
			}
		}
	} 

	private void change_page (string uri) throws Error {
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
		try {
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
		}
		catch (Error e) {
			printerr ("Error: %s\n", e.message);
		}
		return false;
	}

	private void load_sidebar () throws Error {
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
			try {
				change_page (list.nth_data(index_list));
			}
			catch (Error e) {
				printerr ("Error: %s\n", e.message);
			}
		}
	}
	[GtkCallback]
	private void sig_next () {
		if (index_list < list.length()  - 1) {
			index_list++;
			try {
				change_page (list.nth_data(index_list));
			}
			catch (Error e) {
				printerr ("Error: %s\n", e.message);
			}
		}
	}

	[GtkChild]
	unowned Gtk.Stack stack;
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
