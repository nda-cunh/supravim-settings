public class MarkDown : Gtk.DrawingArea{
	private Gtk.GestureClick controller_click;
	private HashTable<int, string> link_queue;
	private string markdown_text;

	public signal void onClickLink(string url);

	enum Weight{
		MINIBOLD, DEMIBOLD, BOLD, NORMAL
	}

	enum Size {
		H1, H2, H3, NORMAL
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
		ctx.set_source_rgb (1.0, 1.0, 1.0);

		foreach (var line in split) {
			if ((int)x > max_x)
				max_x = (int)x;
			x = 15;
			// IMAGE  ![]() 
			if (/^!\[.*\][(](?P<url>.*)[)]/.match (line, 0, out match_info)) {
				var name = Environment.get_home_dir() + "/.local/share/supravim-gui/" + match_info.fetch_named ("url");
				var image = new Cairo.ImageSurface.from_png (name);
				if (image == null)
					continue;
				ctx.move_to (x, y);
				ctx.set_source_surface (image, x, y);
				ctx.paint();
				ctx.set_source_rgb (1.0, 1.0, 1.0);

				y += image.get_height ();
				x += image.get_width ();
				if ((int)x > max_x)
					max_x = (int)x;
				continue;
			}
			// >>>  >
			else if (/^[>].*/.match(line)) {
				line = line[1:];
				x += 15;
			}
			ctx.set_source_rgb (1.0, 1.0, 1.0);
			// LINK [value](url)
			if (/[^!]\[(?P<name>.*)\]\((?P<url>.*)\)/.match(line, 0, out match_info)) {
				ctx.set_source_rgb (0.0, 0.5, 1.0);
				line = match_info.fetch_named ("name");
				link_queue[(int)y - 10] = match_info.fetch_named ("url");
			}
			foreach (var c in line.data) {
				if (c == '#') {
					if (size == NORMAL)
						size = H1;
					else if (size == H1)
						size = H2;
					else if (size == H2)
						size = H3;
					else
						size = NORMAL;
					continue ;
				}
				if (c == '*') {
					if (weight == NORMAL)
						weight = DEMIBOLD;
					else if (weight == DEMIBOLD)
						weight = BOLD;
					else if (weight == BOLD)
						weight = MINIBOLD;
					else if (weight == MINIBOLD)
						weight = NORMAL;
					continue ;
				}
				if (((char)c).isspace ()) {
					x += 3.0;
					continue;
				}
				if (weight == BOLD || size == H1 || size == H2)
					ctx.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
				else
					ctx.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
				if (size == NORMAL)
					ctx.set_font_size (14);
				if (size == H3)
					ctx.set_font_size (18);
				if (size == H2)
					ctx.set_font_size (22);
				if (size == H1)
					ctx.set_font_size (26);
				ctx.move_to (x, y);
				glph[0] = c;
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
