using Gtk;

public class Body : Gtk.Box{
	public Body () {
		Object(orientation: Orientation.VERTICAL, spacing:0);
		stack = new Adw.ViewStack (){hexpand=true, vexpand=true, css_classes={"stack"}};
		switchBar = new Adw.ViewSwitcherBar () {stack=stack};
		
		toolsViewTitle = new Adw.ViewSwitcherTitle ();
		toolsViewTitle.set_stack (stack);
		toolsViewTitle.notify.connect (() => {
				print("yop");
			switchBar.set_reveal (toolsViewTitle.get_title_visible ());
		});
		
		headerBar = new Adw.HeaderBar ();
		headerBar.set_title_widget (toolsViewTitle);
		
		scroll = new Gtk.ScrolledWindow(){child = stack};
		append_all();
		add_pages();
	}

	private void append_all() {
		base.append(headerBar);
		base.append(scroll);
		base.append(switchBar);
	}
	
	private void add_pages() {
		unowned Adw.ViewStackPage page;
		page = stack.add(new General());
		page.set_icon_name ("emblem-system-symbolic");
		page.title = "General";

		var label = new Gtk.Label("""<a href="http://google.com" >google</a> <a href="http://duck.com" >duck</a> """){use_markup=true};
		label.activate_link.connect((e)=>{
			print("Ouiii %s\n", e);
			return true;
		});
		page = stack.add(label);
		page.set_icon_name ("emblem-important-symbolic");
		page.title = "Doc";

	}

	Gtk.ScrolledWindow scroll;
	Adw.ViewSwitcherTitle toolsViewTitle;
	Adw.HeaderBar headerBar; 
	Adw.ViewSwitcherBar switchBar;
	Adw.ViewStack stack;
}
