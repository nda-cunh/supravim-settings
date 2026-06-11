private void init_themes () {
	tab_themes = new HashTable<string, Color> (str_hash, str_equal);

	unowned string HOME = Environment.get_home_dir ();
	string colors_dir = HOME + "/.vim/colors";
	Dir dir;
	try {
		dir = Dir.open (colors_dir);
	} catch (FileError e) {
		warning ("Cannot open colors dir %s: %s", colors_dir, e.message);
		return;
	}

	string? fname;
	while ((fname = dir.read_name ()) != null) {
		if (!fname.has_suffix (".vim"))
			continue;
		string path = Path.build_filename (colors_dir, fname);
		string? tag = find_supra_gui_line (path);
		if (tag == null)
			continue;
		string name = fname[0 : fname.length - 4]; // strip .vim
		Color? c = parse_color (name, tag);
		if (c != null)
			tab_themes[name] = c;
	}
}

private string? find_supra_gui_line (string path) {
	try {
		var file = File.new_for_path (path);
		var stream = new DataInputStream (file.read ());
		string? line;
		int n = 0;
		while ((line = stream.read_line ()) != null && n < 10) {
			if (line.has_prefix ("# supra-gui:") || line.has_prefix ("\" supra-gui:"))
				return line;
			n++;
		}
	} catch (Error e) {}
	return null;
}

private Color? parse_color (string name, string tag) {
	// tag format: "# supra-gui: key=#rrggbb key=#rrggbb ..."
	int colon = tag.index_of (":");
	if (colon < 0) return null;
	string rest = tag[colon + 1 :].strip ();

	var map = new HashTable<string, DataColor?> (str_hash, str_equal);
	bool is_light = false;
	foreach (string part in rest.split (" ")) {
		if (part == "is_light=true") { is_light = true; continue; }
		string[] kv = part.split ("=", 2);
		if (kv.length != 2) continue;
		DataColor? dc = parse_hex (kv[1]);
		if (dc != null)
			map[kv[0]] = dc;
	}

	const string[] required = {"background","include","stdio","typedef","struct",
	                     "type_s","scope","float","function","format","text","integer"};
	foreach (string k in required)
		if (!map.contains (k)) return null;

	return new Color (name) {
		background_color = map["background"],
		include          = map["include"],
		stdio            = map["stdio"],
		typedef          = map["typedef"],
		struct           = map["struct"],
		type_s           = map["type_s"],
		scope            = map["scope"],
		float            = map["float"],
		function         = map["function"],
		format           = map["format"],
		text             = map["text"],
		integer          = map["integer"],
		is_light         = is_light,
	};
}

private DataColor? parse_hex (string hex) {
	if (hex.length != 7 || hex[0] != '#') return null;
	string s = hex[1:];
	int64 val;
	if (!int64.try_parse (s, out val, null, 16)) return null;
	return DataColor.rgb (
		(int) ((val >> 16) & 0xff),
		(int) ((val >>  8) & 0xff),
		(int) ( val        & 0xff)
	);
}
