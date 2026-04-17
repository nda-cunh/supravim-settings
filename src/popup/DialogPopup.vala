using Adw;
using Gtk;

[GtkTemplate (ui = "/ui/DialogPopup.ui")]
public class DialogPopup : Adw.Window {
	public DialogPopup (Gtk.Window mainWindow, string? title = null, string? subtitle = null) {
		base.set_transient_for(mainWindow);
		if (subtitle != null)
			set_subtitle_label (subtitle);
		if (title != null)
			set_title_label (title);
	}

	public void set_title_label (string title) {
		label_title.set_text (title);
		label_title.visible = true;
	}

	public void set_subtitle_label (string subtitle) {
		label_subtitle.set_text (subtitle);
		label_subtitle.visible = true;
	}

	public void add_cancel_button() {
		var cancel_button = new Gtk.Button.with_label("Cancel") {
			css_classes = {"button_popup"},
		};
		cancel_button.clicked.connect (() => base.close());
		box_buttons.append(cancel_button);
	}

	[GtkCallback]
	public void close_popup () {
		base.close();
	}

	[GtkChild]
	public unowned Gtk.Button closing_btn; 
	[GtkChild]
	public unowned Gtk.ProgressBar progress_bar;
	[GtkChild]
	public unowned Box box_main;
	[GtkChild]
	public unowned Box box_buttons;
	[GtkChild]
	public unowned Label label_title; 
	[GtkChild]
	public unowned Label label_subtitle; 
	[GtkChild]
	public unowned Label label_footer; 

}
