/**
 * Color Scheme Preview Widget
 *
 * This widget displays a preview of a color scheme for syntax highlighting.
 * It shows various code elements like includes, typedefs, structs, types,
 * functions, formats, text, and integers in their respective colors.
 */
public class Color : Gtk.Box {

	private const double size_h = 8.0;
	private Gtk.DrawingArea drawing_area;
	private bool hover = false;
	public bool active = false;

	construct {
		orientation = VERTICAL;
		drawing_area = new Gtk.DrawingArea ();
		append(drawing_area);
	}

	/**
	 * Constructor
	 * @param name Name of the color scheme
	 */
	public Color (string name = "default") {
		drawing_area.set_draw_func (this.drawing);
		drawing_area.set_size_request (180, 76);
		// drawing_area.child = drawing_area;
		var motion = new Gtk.EventControllerMotion();

		motion.enter.connect (()=> {
			hover = true;
			drawing_area.queue_draw();
		});

		motion.leave.connect (()=> {
			hover = false;
			drawing_area.queue_draw();
		});

		drawing_area.add_controller(motion);
		prepend(new Gtk.Label(name));
	}

	/**
	 * Queue a redraw of the widget
	 * it's necessary to clear the mark when the themes is changed
	 */
	public new void queue_draw () {
		base.queue_draw();
		drawing_area.queue_draw();
	}

	/**
	 * Draw a rectangle
	 */
	private void draw_rect(Cairo.Context ctx, DataColor color, double x, double y, double width) {
		ctx.set_source_rgb (color.red, color.green, color.blue);
		ctx.rectangle (x, y, width, size_h);
		ctx.fill();
	}

	private void rounded_rectangle(Cairo.Context ctx, int x, int y, int width, int height, int radius) {
		ctx.new_path();
		ctx.move_to(x + radius, y);
		ctx.line_to(x + width - radius, y);
		ctx.arc(x + width - radius, y + radius, radius, -90 * Math.PI / 180, 0 * Math.PI / 180);
		ctx.line_to(x + width, y + height - radius);
		ctx.arc(x + width - radius, y + height - radius, radius, 0 * Math.PI / 180, 90 * Math.PI / 180);
		ctx.line_to(x + radius, y + height);
		ctx.arc(x + radius, y + height - radius, radius, 90 * Math.PI / 180, 180 * Math.PI / 180);
		ctx.line_to(x, y + radius);
		ctx.arc(x + radius, y + radius, radius, 180 * Math.PI / 180, 270 * Math.PI / 180);
		ctx.close_path();
		ctx.fill();


		// ici dessin du retcangle sur le cote gauche
		ctx.new_path();
		ctx.move_to(x + radius, y);
		ctx.line_to(x + 10 + radius, y);
		ctx.line_to(x + 10 + radius, y + height);
		ctx.line_to(x, y + height);
		ctx.arc(x + radius, y + height - radius, radius, 90 * Math.PI / 180, 180 * Math.PI / 180);
		ctx.line_to(x, y + radius);
		ctx.arc(x + radius, y + radius, radius, 180 * Math.PI / 180, 270 * Math.PI / 180);
		ctx.close_path();
		ctx.set_source_rgb(background_color.green - 0.07, background_color.red -0.07, background_color.blue -0.07);
		ctx.fill();


		ctx.new_path();
		ctx.move_to(x + width, y + radius);
		ctx.line_to(x + width, y);
		ctx.line_to(x + width, y + height);
		ctx.line_to(x + width, y + height);
		ctx.arc(x + width - radius, y + height - radius, radius, 0 * Math.PI / 180, 90 * Math.PI / 180); // Bottom right corner
		ctx.line_to(x + width - radius, y + radius);
		ctx.arc(x + width - radius, y + radius, radius, 135 * Math.PI / 90, 30 * Math.PI / 180); // Top right corner
		ctx.close_path();
		ctx.set_source_rgb(background_color.green -0.05, background_color.red -0.05, background_color.blue -0.05);
		ctx.fill();


		if (active == true) {
			ctx.set_source_rgb(0.60, 0.60, 1.0);
			ctx.new_path();
			ctx.move_to(x + radius, y);
			ctx.line_to(x + width - radius, y);
			ctx.arc(x + width - radius, y + radius, radius, -90 * Math.PI / 180, 0 * Math.PI / 180);
			ctx.line_to(x + width, y + height - radius);
			ctx.arc(x + width - radius, y + height - radius, radius, 0 * Math.PI / 180, 90 * Math.PI / 180);
			ctx.line_to(x + radius, y + height);
			ctx.arc(x + radius, y + height - radius, radius, 90 * Math.PI / 180, 180 * Math.PI / 180);
			ctx.line_to(x, y + radius);
			ctx.arc(x + radius, y + radius, radius, 180 * Math.PI / 180, 270 * Math.PI / 180);
			ctx.close_path();
			ctx.stroke();
		}
		else if (hover == true) {
			ctx.set_source_rgb(1.0, 1.0, 1.0);
			ctx.new_path();
			ctx.move_to(x + radius, y);
			ctx.line_to(x + width - radius, y);
			ctx.arc(x + width - radius, y + radius, radius, -90 * Math.PI / 180, 0 * Math.PI / 180);
			ctx.line_to(x + width, y + height - radius);
			ctx.arc(x + width - radius, y + height - radius, radius, 0 * Math.PI / 180, 90 * Math.PI / 180);
			ctx.line_to(x + radius, y + height);
			ctx.arc(x + radius, y + height - radius, radius, 90 * Math.PI / 180, 180 * Math.PI / 180);
			ctx.line_to(x, y + radius);
			ctx.arc(x + radius, y + radius, radius, 180 * Math.PI / 180, 270 * Math.PI / 180);
			ctx.close_path();
			ctx.stroke();
		}
	}

	private void check_mark(Cairo.Context cr, int width, int height, int x) {
        // Fond bleu
        cr.set_source_rgb(0.31, 0.63, 1);
        cr.arc(x + width / 2, height / 2, width / 2 - 5, 0, 2 * Math.PI);
        cr.fill();

        // Coche blanche
        cr.set_source_rgb(1, 1, 1);
		cr.set_line_width(width * 0.05); // Adjust line width if needed
		cr.move_to(x + width * 0.30, height * 0.55 - 2);
		cr.line_to(x + width * 0.45, height * 0.7 - 2);
		cr.line_to(x + width * 0.7, height * 0.45  - 2);
		cr.stroke();
    }

	private void drawing (Gtk.DrawingArea drawing_area, Cairo.Context ctx, int width, int height) {
		const double padding_w = 25.0;
		const double padding_h = 9.0;

		ctx.set_source_rgb (background_color.red - 0.02, background_color.green - 0.02, background_color.blue - 0.02);
		rounded_rectangle (ctx, 0, 0, width, height, 8);
		ctx.fill();

		// ctx.rectangle (160.0, 0.0, 20, 80);

		// 1 lines
		draw_rect (ctx, include, padding_w, padding_h, 44);
		draw_rect (ctx, stdio, padding_w + 48, padding_h, 28);

		// 2 lines
		draw_rect (ctx, typedef, padding_w, padding_h + size_h + 4, 44);
		draw_rect (ctx, struct, padding_w + 48, padding_h + size_h + 4, 36);
		draw_rect (ctx, type_s, padding_w + 88, padding_h + size_h + 4, 31);
		// draw_rect (ctx, scope, padding_w + 123, padding_h + size_h + 4, 4);

		// 3 lines
		draw_rect (ctx, float, padding_w + 20, padding_h + (size_h*2) + 8, 38);
		draw_rect (ctx, type_s, padding_w + 62, padding_h + (size_h*2) + 8, 28);
		draw_rect (ctx, scope, padding_w + 94, padding_h + (size_h * 2) + 8, 3);

		// scope and type 4 lines
		draw_rect (ctx, scope, padding_w, padding_h + (size_h*3) + 12, 5);
		draw_rect (ctx, type_s, padding_w + 8, padding_h + (size_h*3) + 12, 40);

		// lines 5 printf
		//  printf ("%s %d", "Hello, World! im a long text ", 42);
		draw_rect (ctx, function, padding_w, padding_h + (size_h*4) + 16, 28);
		draw_rect (ctx, format, padding_w + 31, padding_h + (size_h*4) + 16, 14);
		draw_rect (ctx, text, padding_w + 48, padding_h + (size_h*4) + 16, 77);
		draw_rect (ctx, integer, padding_w + 128, padding_h + (size_h*4) + 16, 12);
		// draw_rect (ctx, scope, padding_w + 137, padding_h + (size_h*4) + 16, 2);
		if (active)
			check_mark(ctx, 33, 33, 142);


	}

	public DataColor background_color {get;set;}
	public DataColor include {get;set;}
	public DataColor stdio {get;set;}
	public DataColor typedef {get;set;}
	public DataColor struct {get;set;}
	public DataColor type_s {get;set;}
	public DataColor scope {get;set;}
	public DataColor float {get;set;}
	public DataColor function {get;set;}
	public DataColor format {get;set;}
	public DataColor text {get;set;}
	public DataColor integer {get;set;}
}
