public class MarkDown : Gtk.DrawingArea{
	struct Color {
		public double r;
		public double g;
		public double b;
		public void set_color (Cairo.Context ctx) {
			ctx.set_source_rgb (r, g, b);
		}
	}
	Color color;
	private Gtk.GestureClick controller_click;
	private HashTable<int, string> link_queue;
	private string markdown_text;

	public signal void onClickLink(string url);

	enum Weight{
		ITALIC_BOLD, BOLD, ITALIC, NORMAL
	}

	enum Size {
		H1, H2, H3, H4, H5, NORMAL
	}

	public MarkDown(string text) {
		Object (hexpand:true, vexpand:true);
		controller_click = new Gtk.GestureClick ();
		base.add_controller (controller_click);
		link_queue = new HashTable<int, string>(null, null);
		controller_click.pressed.connect ((n, x, y)=> {
			link_queue.foreach ((i, s) => {
				if (i - 5 <= y && i + 15 >= y)
					onClickLink (s);
			});
		});
		this.set_draw_func (func);
		load_from_text (text);
	}

	public void load_from_text(string txt) {
		this.markdown_text = txt.to_ascii ();
		base.queue_draw ();
	}

	public void load_from_file(string url_file) throws Error {
		string text;
		FileUtils.get_contents (url_file, out text);
		load_from_text(text);
	}


	bool is_bold = false;
	bool is_code = false;

	public void func (Gtk.DrawingArea drawing_area, Cairo.Context ctx, int width, int height) {
		link_queue.remove_all ();
		MatchInfo match_info;
		Cairo.TextExtents extents;
		uint8 glph[2] = {0, 0};
		int max_x = 0;
		var split = markdown_text.split("\n");
		var x = 0.0;
		var y = 30.0;
		Size size = NORMAL;
		Weight weight = NORMAL;
		is_bold = false;

		foreach (var line in split) {
			size = NORMAL;
			weight = NORMAL;
			color = {1.0, 1.0, 1.0};
			if ((int)x > max_x)
				max_x = (int)x;
			x = 15;
			// IMAGE  ![]()
			if (/^!\[.*\][(](?P<url>.*)[)]/.match (line, 0, out match_info)) {
				var name = Environment.get_home_dir() + "/.local/share/supravim-gui/" + match_info.fetch_named ("url");
				var image = new Cairo.ImageSurface.from_png (name);
				if (image == null || image.get_width () == 0) {
					string new_name = name[0:name.last_index_of_char ('.')];
					if (FileUtils.test(new_name + "-0.png", FileTest.EXISTS) == false) {
						FileUtils.remove (new_name);
						Process.spawn_command_line_sync (@"convert $name $(new_name).png");
					}
					else
						warning ("Image not found: %s", name);
					image = new Cairo.ImageSurface.from_png (new_name + "-0.png");
					if (image == null || image.get_width () == 0) {
						warning ("Image not found: %s", new_name);
						continue;
					}
				}
				ctx.move_to (x, y);
				ctx.set_source_surface (image, x, y);
				ctx.paint();
				color = {1.0, 1.0, 1.0};

				y += image.get_height () + 20;
				x += image.get_width ();
				if ((int)x > max_x)
					max_x = (int)x;
				continue;
			}
			// >>>  >
			else if (line.has_prefix (">")) {
				size = H5;
				x += 15;
				if (line.has_prefix (">>")) {
					color = {0.40, 1.0, 1.0};
					line = line[2:];
					x += 5;
				}
				else {
					line = line[1:];
					color = {0.80, 1.0, 1.0};
				}
			}
			else
				color = {1.0, 1.0, 1.0};
			color.set_color (ctx);
			// LINK [value](url)
			if (/[^!]\[(?P<name>.*)\]\((?P<url>.*)\)/.match(line, 0, out match_info)) {
				ctx.set_source_rgb (0.0, 0.5, 1.0);
				line = match_info.fetch_named ("name");
				link_queue[(int)y - 10] = match_info.fetch_named ("url");
				color = {0.0, 0.5, 1.0};
			}
			// foreach (var c in line.data) {
			int length_tmp = line.length;
			unowned string c = line;
			for (int i = 0; i < length_tmp; ++i) {
				if (c[i] == '#') {
					if (size == NORMAL)
						size = H1;
					else if (size == H1)
						size = H2;
					else if (size == H2)
						size = H3;
					else if (size == H3)
						size = H4;
					else if (size == H4)
						size = H5;
					else
						size = NORMAL;
					continue ;
				}
				else if (c[i] == '`') {
					if (is_code == false) {
						weight = BOLD;
						color = {0.88, 0.88, 0.88};
						is_code = true;
					}
					else {
						color = {1.0, 1.0, 1.0};
						is_code = false;
					}
					continue ;
				}
				else if (c[i] == '*') {
					if (is_bold == false) {
						if (c.offset(i).has_prefix ("****"))
							continue;
						if (c.offset(i).has_prefix ("***")){
							weight = ITALIC_BOLD;
							i += 2;
						}
						else if (c.offset(i).has_prefix("**")){
							weight = BOLD;
							i += 1;
						}
						else if (c.offset(i).has_prefix("*")){
							weight = ITALIC;
							i += 0;
						}
						is_bold = true;
					}
					else {
						if (c.offset(i).has_prefix ("****"))
							continue;
						if (c.offset(i).has_prefix ("***")){
							weight = NORMAL;
							i += 2;
						}
						else if (c.offset(i).has_prefix("**")){
							weight = NORMAL;
							i += 1;
						}
						else if (c.offset(i).has_prefix("*")){
							weight = NORMAL;
							i += 0;
						}
						is_bold = false;
					}
					continue ;
				}
				else if (((char)c[i]).isspace ()) {
					x += 3.0;
					continue;
				}

				if (size == H1 || size == H2) {
					ctx.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
				}
				if (weight == BOLD) {
					ctx.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
				}
				else if (weight == ITALIC)
					ctx.select_font_face ("Arial", Cairo.FontSlant.ITALIC, Cairo.FontWeight.NORMAL);
				else if (weight == ITALIC_BOLD)
					ctx.select_font_face ("Arial", Cairo.FontSlant.ITALIC, Cairo.FontWeight.BOLD);
				else
					ctx.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
				if (size == NORMAL)
					ctx.set_font_size (14);
				else if (size == H5)
					ctx.set_font_size (16);
				else if (size == H4)
					ctx.set_font_size (20);
				else if (size == H3)
					ctx.set_font_size (22);
				else if (size == H2)
					ctx.set_font_size (26);
				else if (size == H1)
					ctx.set_font_size (32);

				color.set_color (ctx);

				ctx.move_to (x, y);
				glph[0] = c[i];
				ctx.text_extents ((string)glph, out extents);
				ctx.show_text ((string)glph);
				x += extents.x_advance;
			}
			if (size == H1) {
				ctx.move_to (15 , y + 10);
				ctx.line_to (800, y + 10);
				y += 20;
			}
			y += 20;
			size = NORMAL;
			ctx.stroke ();
		}
		base.set_content_height ((int)y);
		base.set_content_width (max_x);
	}
}

