private Gtk.CssProvider? theme_css_provider = null;

public void apply_theme_css (string theme) {
	if (tab_themes == null || !tab_themes.contains (theme))
		return;
	Color c = tab_themes[theme];

	var display = Gdk.Display.get_default ();
	if (display == null)
		return;

	Adw.StyleManager.get_default ().color_scheme =
		c.is_light ? Adw.ColorScheme.FORCE_LIGHT : Adw.ColorScheme.FORCE_DARK;

	if (theme_css_provider != null)
		Gtk.StyleContext.remove_provider_for_display (display, theme_css_provider);

	theme_css_provider = new Gtk.CssProvider ();
	theme_css_provider.load_from_data (build_palette_css (c).data);
	Gtk.StyleContext.add_provider_for_display (display, theme_css_provider,
	                                           Gtk.STYLE_PROVIDER_PRIORITY_USER + 1);
}

private string build_palette_css (Color c) {
	bool light = c.is_light;
	DataColor bg = c.background_color;

	DataColor bg_deep = light ? shade (bg, 0.95) : shade (bg, 0.72);
	DataColor bg_alt  = light ? shade (bg, 0.96) : lift (bg, 0.055);
	DataColor bg_soft = light ? shade (bg, 0.91) : lift (bg, 0.105);
	DataColor border  = light ? shade (bg, 0.85) : lift (bg, 0.165);

	DataColor fg, fg_bright;
	pick_text_tones (c, bg, out fg, out fg_bright);

	DataColor muted = readable (mix (fg, bg, 0.45), bg, 4.5);

	DataColor accent = readable (nearest_hue (c, 215.0, c.include), bg, 4.5);
	DataColor green  = readable (nearest_hue (c, 120.0, light ? DataColor.rgb (38, 162, 105) : DataColor.rgb (139, 205, 91)), bg, 4.5);
	DataColor yellow = readable (nearest_hue (c, 48.0, light ? DataColor.rgb (229, 165, 10) : DataColor.rgb (239, 189, 93)), bg, 4.5);
	DataColor orange = readable (nearest_hue (c, 28.0, light ? DataColor.rgb (198, 70, 0) : DataColor.rgb (221, 144, 70)), bg, 4.5);
	DataColor red    = readable (nearest_hue (c, 358.0, light ? DataColor.rgb (192, 28, 40) : DataColor.rgb (246, 88, 102), 26.0), bg, 4.5);
	DataColor purple = readable (nearest_hue (c, 285.0, light ? DataColor.rgb (136, 57, 239) : DataColor.rgb (199, 90, 232)), bg, 4.5);
	DataColor cyan   = readable (nearest_hue (c, 190.0, light ? DataColor.rgb (14, 116, 144) : DataColor.rgb (52, 191, 208)), bg, 4.5);

	var sb = new StringBuilder ();

	sb.append ("@define-color sd_bg %s;\n".printf (hex (bg)));
	sb.append ("@define-color sd_bg_deep %s;\n".printf (hex (bg_deep)));
	sb.append ("@define-color sd_bg_alt %s;\n".printf (hex (bg_alt)));
	sb.append ("@define-color sd_bg_soft %s;\n".printf (hex (bg_soft)));
	sb.append ("@define-color sd_border %s;\n".printf (hex (border)));
	sb.append ("@define-color sd_muted %s;\n".printf (hex (muted)));
	sb.append ("@define-color sd_fg %s;\n".printf (hex (fg)));
	sb.append ("@define-color sd_fg_bright %s;\n".printf (hex (fg_bright)));
	sb.append ("@define-color sd_blue %s;\n".printf (hex (accent)));
	sb.append ("@define-color sd_green %s;\n".printf (hex (green)));
	sb.append ("@define-color sd_yellow %s;\n".printf (hex (yellow)));
	sb.append ("@define-color sd_orange %s;\n".printf (hex (orange)));
	sb.append ("@define-color sd_red %s;\n".printf (hex (red)));
	sb.append ("@define-color sd_purple %s;\n".printf (hex (purple)));

	DataColor heat = readable (c.stdio, bg, 3.0);
	sb.append ("@define-color sd_heat_1 %s;\n".printf (hex (tint (heat, bg, 0.22, 0.55))));
	sb.append ("@define-color sd_heat_2 %s;\n".printf (hex (tint (heat, bg, 0.46, 0.55))));
	sb.append ("@define-color sd_heat_3 %s;\n".printf (hex (tint (heat, bg, 0.72, 0.55))));
	sb.append ("@define-color sd_heat_4 %s;\n".printf (hex (heat)));

	DataColor install_bg, install_fg, uninstall_bg, uninstall_fg;
	solid_action (green, out install_bg, out install_fg);
	solid_action (red, out uninstall_bg, out uninstall_fg);
	sb.append ("@define-color sd_install_bg %s;\n".printf (hex (install_bg)));
	sb.append ("@define-color sd_install_bg_hover %s;\n".printf (hex (lighten (install_bg, 1.12))));
	sb.append ("@define-color sd_install_fg %s;\n".printf (hex (install_fg)));
	sb.append ("@define-color sd_uninstall_bg %s;\n".printf (hex (uninstall_bg)));
	sb.append ("@define-color sd_uninstall_bg_hover %s;\n".printf (hex (lighten (uninstall_bg, 1.12))));
	sb.append ("@define-color sd_uninstall_fg %s;\n".printf (hex (uninstall_fg)));

	string fg_h = hex (fg);
	string bg_h = hex (bg);
	string shadow = light ? "rgba(0, 0, 0, 0.12)" : "rgba(0, 0, 0, 0.36)";

	sb.append ("@define-color window_bg_color %s;\n".printf (bg_h));
	sb.append ("@define-color window_fg_color %s;\n".printf (fg_h));
	sb.append ("@define-color view_bg_color %s;\n".printf (bg_h));
	sb.append ("@define-color view_fg_color %s;\n".printf (fg_h));
	sb.append ("@define-color theme_bg_color %s;\n".printf (bg_h));
	sb.append ("@define-color theme_fg_color %s;\n".printf (fg_h));
	sb.append ("@define-color theme_base_color %s;\n".printf (bg_h));
	sb.append ("@define-color theme_text_color %s;\n".printf (fg_h));

	sb.append ("@define-color headerbar_bg_color %s;\n".printf (hex (bg_deep)));
	sb.append ("@define-color headerbar_fg_color %s;\n".printf (hex (fg_bright)));
	sb.append ("@define-color headerbar_border_color %s;\n".printf (hex (border)));
	sb.append ("@define-color headerbar_backdrop_color %s;\n".printf (bg_h));
	sb.append ("@define-color headerbar_shade_color %s;\n".printf (shadow));

	sb.append ("@define-color sidebar_bg_color %s;\n".printf (hex (bg_deep)));
	sb.append ("@define-color sidebar_fg_color %s;\n".printf (fg_h));
	sb.append ("@define-color sidebar_backdrop_color %s;\n".printf (bg_h));
	sb.append ("@define-color sidebar_border_color %s;\n".printf (hex (border)));
	sb.append ("@define-color sidebar_shade_color %s;\n".printf (shadow));
	sb.append ("@define-color secondary_sidebar_bg_color %s;\n".printf (hex (bg_deep)));
	sb.append ("@define-color secondary_sidebar_fg_color %s;\n".printf (fg_h));

	sb.append ("@define-color card_bg_color %s;\n".printf (hex (bg_alt)));
	sb.append ("@define-color card_fg_color %s;\n".printf (fg_h));
	sb.append ("@define-color card_shade_color %s;\n".printf (shadow));
	sb.append ("@define-color dialog_bg_color %s;\n".printf (hex (bg_alt)));
	sb.append ("@define-color dialog_fg_color %s;\n".printf (fg_h));
	sb.append ("@define-color popover_bg_color %s;\n".printf (hex (bg_soft)));
	sb.append ("@define-color popover_fg_color %s;\n".printf (fg_h));

	sb.append ("@define-color borders %s;\n".printf (hex (border)));
	sb.append ("@define-color shade_color %s;\n".printf (shadow));

	sb.append ("@define-color accent_color %s;\n".printf (hex (accent)));
	sb.append ("@define-color accent_bg_color %s;\n".printf (hex (accent)));
	sb.append ("@define-color accent_fg_color %s;\n".printf (hex (on_color (accent))));
	sb.append ("@define-color destructive_color %s;\n".printf (hex (red)));
	sb.append ("@define-color destructive_bg_color %s;\n".printf (hex (red)));
	sb.append ("@define-color destructive_fg_color %s;\n".printf (hex (on_color (red))));
	sb.append ("@define-color success_color %s;\n".printf (hex (green)));
	sb.append ("@define-color success_bg_color %s;\n".printf (hex (green)));
	sb.append ("@define-color success_fg_color %s;\n".printf (hex (on_color (green))));
	sb.append ("@define-color warning_color %s;\n".printf (hex (yellow)));
	sb.append ("@define-color warning_bg_color %s;\n".printf (hex (yellow)));
	sb.append ("@define-color warning_fg_color %s;\n".printf (hex (on_color (yellow))));
	sb.append ("@define-color error_color %s;\n".printf (hex (red)));
	sb.append ("@define-color error_bg_color %s;\n".printf (hex (red)));
	sb.append ("@define-color error_fg_color %s;\n".printf (hex (on_color (red))));

	return sb.str;
}

private void pick_text_tones (Color c, DataColor bg, out DataColor fg, out DataColor fg_bright) {
	double h, s_type, l, s_scope;
	to_hsl (c.type_s, out h, out s_type, out l);
	to_hsl (c.scope, out h, out s_scope, out l);

	if (Math.fabs (s_type - s_scope) > 0.25) {
		DataColor neutral = s_type < s_scope ? c.type_s : c.scope;
		fg = readable (neutral, bg, 4.5);
		fg_bright = mix (fg, on_color (bg), 0.45);
	} else {
		bool type_is_dimmer = contrast (c.type_s, bg) <= contrast (c.scope, bg);
		fg        = readable (type_is_dimmer ? c.type_s : c.scope, bg, 4.5);
		fg_bright = readable (type_is_dimmer ? c.scope : c.type_s, bg, 4.5);
	}
}

private DataColor nearest_hue (Color c, double target, DataColor fallback, double max_dist = 46.0) {
	DataColor[] candidates = {c.include, c.stdio, c.typedef, c.struct, c.float,
	                          c.function, c.format, c.text, c.integer,
	                          c.type_s, c.scope};
	DataColor best = fallback;
	double best_dist = max_dist;	foreach (var d in candidates) {
		double h, sat, l;
		to_hsl (d, out h, out sat, out l);
		if (sat < 0.30)
			continue;		double dist = Math.fabs (h - target);
		if (dist > 180.0)
			dist = 360.0 - dist;
		if (dist < best_dist) {
			best_dist = dist;
			best = d;
		}
	}
	return best;
}

private double clamp01 (double v) {
	return v < 0.0 ? 0.0 : (v > 1.0 ? 1.0 : v);
}

private DataColor shade (DataColor c, double factor) {
	return { clamp01 (c.red * factor),
	         clamp01 (c.green * factor),
	         clamp01 (c.blue * factor) };
}

private DataColor lift (DataColor c, double amount) {
	return { clamp01 (c.red + amount),
	         clamp01 (c.green + amount),
	         clamp01 (c.blue + amount) };
}

private DataColor mix (DataColor a, DataColor b, double t) {
	return { a.red + (b.red - a.red) * t,
	         a.green + (b.green - a.green) * t,
	         a.blue + (b.blue - a.blue) * t };
}

private double channel_luminance (double c) {
	return c <= 0.03928 ? c / 12.92 : Math.pow ((c + 0.055) / 1.055, 2.4);
}

private double luminance (DataColor c) {
	return 0.2126 * channel_luminance (c.red)
	     + 0.7152 * channel_luminance (c.green)
	     + 0.0722 * channel_luminance (c.blue);
}

private double contrast (DataColor a, DataColor b) {
	double la = luminance (a);
	double lb = luminance (b);
	double hi = double.max (la, lb);
	double lo = double.min (la, lb);
	return (hi + 0.05) / (lo + 0.05);
}

private DataColor readable (DataColor fg, DataColor bg, double target) {
	if (contrast (fg, bg) >= target)
		return fg;

	double h, sat, l;
	to_hsl (fg, out h, out sat, out l);
	double step = luminance (bg) > 0.5 ? -0.02 : 0.02;

	for (int i = 0; i < 48; i++) {
		l += step;
		if (l <= 0.02 || l >= 0.98)
			break;
		DataColor candidate = from_hsl (h, sat, l);
		if (contrast (candidate, bg) >= target)
			return candidate;
	}

	DataColor goal = luminance (bg) > 0.5 ? DataColor.black : DataColor.white;
	DataColor best = fg;
	for (int i = 1; i <= 20; i++) {
		best = mix (fg, goal, i / 20.0);
		if (contrast (best, bg) >= target)
			return best;
	}
	return best;
}

private DataColor on_color (DataColor c) {
	return luminance (c) > 0.4 ? DataColor.black : DataColor.white;
}

private void to_hsl (DataColor c, out double h, out double s, out double l) {
	double max = double.max (c.red, double.max (c.green, c.blue));
	double min = double.min (c.red, double.min (c.green, c.blue));
	double delta = max - min;

	l = (max + min) / 2.0;
	if (delta < 0.00001) {
		h = 0.0;
		s = 0.0;
		return;
	}
	s = l > 0.5 ? delta / (2.0 - max - min) : delta / (max + min);

	if (max == c.red)
		h = 60.0 * (((c.green - c.blue) / delta) % 6.0);
	else if (max == c.green)
		h = 60.0 * (((c.blue - c.red) / delta) + 2.0);
	else
		h = 60.0 * (((c.red - c.green) / delta) + 4.0);
	if (h < 0.0)
		h += 360.0;
}

private DataColor tint (DataColor source, DataColor bg, double strength,
                        double sat_floor = 1.0, double offset = 0.06) {
	double h, sat, l;
	to_hsl (source, out h, out sat, out l);
	double bh, bs, bl;
	to_hsl (bg, out bh, out bs, out bl);

	double s = sat * (sat_floor + (1.0 - sat_floor) * strength);
	double start = bl > 0.5 ? bl - offset : bl + offset;
	return from_hsl (h, s, start + (l - start) * strength);
}

private void solid_action (DataColor source, out DataColor bg_out, out DataColor fg_out) {
	bool on_black = contrast (source, DataColor.black) >= contrast (source, DataColor.white);
	fg_out = on_black ? DataColor.black : DataColor.white;

	if (contrast (source, fg_out) >= 4.5) {
		bg_out = source;
		return;
	}
	double h, sat, l;
	to_hsl (source, out h, out sat, out l);
	double step = on_black ? 0.02 : -0.02;
	bg_out = source;
	for (int i = 0; i < 48; i++) {
		l += step;
		if (l <= 0.02 || l >= 0.98)
			break;
		bg_out = from_hsl (h, sat, l);
		if (contrast (bg_out, fg_out) >= 4.5)
			return;
	}
}

private DataColor lighten (DataColor c, double factor) {
	double h, sat, l;
	to_hsl (c, out h, out sat, out l);
	return from_hsl (h, sat, clamp01 (l * factor));
}

private DataColor from_hsl (double h, double s, double l) {
	if (s <= 0.0)
		return { l, l, l };
	double c = (1.0 - Math.fabs (2.0 * l - 1.0)) * s;
	double hp = h / 60.0;
	double x = c * (1.0 - Math.fabs ((hp % 2.0) - 1.0));
	double r = 0.0, g = 0.0, b = 0.0;
	if (hp < 1.0)      { r = c; g = x; }
	else if (hp < 2.0) { r = x; g = c; }
	else if (hp < 3.0) { g = c; b = x; }
	else if (hp < 4.0) { g = x; b = c; }
	else if (hp < 5.0) { r = x; b = c; }
	else               { r = c; b = x; }
	double m = l - c / 2.0;
	return { clamp01 (r + m), clamp01 (g + m), clamp01 (b + m) };
}

private string hex (DataColor c) {
	return "#%02x%02x%02x".printf ((uint) Math.round (clamp01 (c.red) * 255.0),
	                               (uint) Math.round (clamp01 (c.green) * 255.0),
	                               (uint) Math.round (clamp01 (c.blue) * 255.0));
}
