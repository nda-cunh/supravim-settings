public class WikiPage : Gtk.Box {
	public WikiPage(string basename) throws Error {
		Object (orientation: Gtk.Orientation.HORIZONTAL, hexpand:true, vexpand:true);
		markdown = new MarkDown ( """# SupraWiki""");
		box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		box_name = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		name_page = new Gtk.Label("SupraWiki"){
			name = "box_named_page",
			halign = Gtk.Align.END
		};

		markdown.onClickLink.connect((url) => {
			try {
				markdown.load_from_file (@"$basename/$(url).md");
			} catch (Error e) {
				printerr(e.message);
			}
		});
		var scrolled = new Gtk.ScrolledWindow ();
		
		scrolled.set_child(new Gtk.Viewport (null, null){child=markdown});
		box_name.append(name_page);
		box_name.append(new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
		box_name.append(scrolled);

		refresh_list(basename);
		base.append (box);
		base.append(new Gtk.Separator (Gtk.Orientation.VERTICAL));
		base.append (box_name);
	}

	void refresh_list (string basename) throws Error {

		MatchInfo match_info;
		string all_md;
		FileUtils.get_contents (@"$basename/_sidebar.md", out all_md);
		foreach (var line in all_md.split("\n")) {
			if (/\[(?P<name>.+?)\]\((?P<url>.+?)\)/.match(line, 0, out match_info)) {
				var name = match_info.fetch_named ("name");
				var url = match_info.fetch_named ("url");

				var btn = new Gtk.Button.with_label (name) {has_frame=false};
				btn.clicked.connect (()=> {
					try {
						markdown.load_from_file (@"$basename/$(url).md");
						name_page.label = btn.label;
					} catch(Error e) {
						printerr(e.message);
					}
				});
				box.append (btn);
			}
		}
		markdown.load_from_file (@"$basename/home.md");
	}

	Gtk.Label name_page;
	Gtk.Box box_name;
	Gtk.Box box;
	MarkDown markdown;
}

