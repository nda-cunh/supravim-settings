public const string CFG = "/.local/share/supravim/supravim.cfg";

public struct Bool : bool {
	public static bool my_parse(string s){
		var v = s.ascii_down();
		if ("1" in v || "true" in v)
			return true;
		return false;
	}
	public int to_int() {
		if ((bool)this == true)
			return 1;
		return 0;
	}
}

public enum Theme {
	ATOM,
	ICEBERG,
	ONEHALF,
	TOMORROWNIGHT,
	RACULA,
	MOLOKAI,
	ONELIGHT,
	TOMORROWNIGHTEIGHTIES,
	GRUVBOX,
	ONEDARK,
	PABLO;

	public static Theme parse(string s) {
		var d = s.ascii_down();
		if ("atom" in d)
			return ATOM;
		if ("iceberg" in d)
			return ICEBERG;
		if ("onehalf" in d)
			return ONEHALF;
		if ("tomorrownight" in d)
			return TOMORROWNIGHT;
		if ("racula" in d)
			return RACULA;
		if ("molokai" in d)
			return MOLOKAI;
		if ("onelight" in d)
			return ONELIGHT;
		if ("gruvbox" in d)
			return GRUVBOX;
		if ("onedark" in d)
			return ONEDARK;
		if ("pablo" in d)
			return PABLO;
		return ONELIGHT;
	}
	public string etoa() {
		string s = this.to_string();
		return s;
	}
}

struct Config {
	private string get_value(string symbol, string content) {
		unowned string begin;
		unowned string comma;

		begin = content.offset(content.index_of(symbol));
		comma = begin.offset(begin.index_of_char(':') + 1);
		return comma[0:(comma.index_of_char('\n'))];
	}
	
	public void generate () {
		{
			var fs = FileStream.open(@"$HOME/.local/share/supravim/supravim.cfg", "w");
			if (fs == null)
				error("Can't open supravim.cfg");


			fs.printf("sv_mouse:%d\n", ((Bool)mouse).to_int());
			fs.printf("sv_swap:%d\n",  ((Bool)swap).to_int());
			fs.printf("sv_tree:%d\n",  ((Bool)tree).to_int());
			fs.printf("sv_icons:%d\n", ((Bool)icons).to_int());
			fs.printf("sv_norme:%d\n", ((Bool)norme).to_int());
			fs.printf("sv_theme:%s\n", theme.etoa());
			fs.printf("sv_perso_conf:%s\n", "");
		}
		print("Application :\n");
		try {
			Process.spawn_command_line_sync(@"$HOME/.local/share/supravim/apply_cfg $HOME/.local/share/supravim/supravim.cfg");
		} catch (Error e) {
			printerr(e.message);
		}
	}

	public Config.load() {
		string content;
		
		print("Recuperation de cfg:\n");
		try {
			Process.spawn_command_line_sync(@"$HOME/.local/share/supravim/create_cfg $HOME/.local/share/supravim/supravim.cfg");
		} catch (Error e) {
			printerr(e.message);
		}
		try {
			FileUtils.get_contents(HOME + CFG, out content);
		} catch (Error e) {
			printerr(e.message);
		}
		
		this.mouse = Bool.my_parse(get_value("sv_mouse", content));
		this.swap = Bool.my_parse(get_value("sv_swap", content));
		this.tree = Bool.my_parse(get_value("sv_tree", content));
		this.icons = Bool.my_parse(get_value("sv_icons", content));
		this.norme = Bool.my_parse(get_value("sv_norme", content));

		this.theme = Theme.parse(get_value("sv_norme", content));
		print(@"$mouse $swap $tree $icons $norme\n");
		print(@"$theme\n");
	}
	bool mouse;
	bool swap;
	bool tree;
	bool icons;
	bool norme;
	Theme theme;
}
