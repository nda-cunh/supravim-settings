[GtkTemplate (ui = "/ui/plugins/externalrow.ui")]
public class RowPluginExternal : Adw.ActionRow {
	// Private Members
	private string pl_name;
	private string pl_url;
	private string? installed_commit;
	private string? pinned;
	private bool enabled;
	private bool update_available = false;

	[GtkChild]
	public unowned Gtk.Switch status;
	[GtkChild]
	unowned Gtk.Button pin_button;
	[GtkChild]
	unowned Gtk.Button update_button;

	// Signals
	public signal void refresh();

	// Constructor
	public RowPluginExternal (Supravim.Plugin.PluginEntry entry) {
		this.pl_name = entry.name;
		this.pl_url = entry.url;
		this.installed_commit = entry.installed_commit;
		this.pinned = entry.pinned;
		this.enabled = entry.enabled;
		base.title = entry.name;

		this.status.set_active (entry.enabled);

		update_subtitle ();
		update_pin_button ();

		// Clicking the row body opens the configuration popup.
		base.tooltip_text = "Configure this plugin";
		base.activatable = true;
		base.activated.connect (open_config);

		// A pinned plugin is frozen on a commit: no update is offered until it
		// gets unpinned. Otherwise ask git whether the remote actually moved.
		if (pinned == null && pl_url != "")
			check_update.begin ();
	}

	private void open_config () {
		var dialog = new WindowConfigurePlugin (this.get_root () as Gtk.Window,
			pl_name, pl_url, installed_commit, pinned, enabled, update_available);
		dialog.refresh.connect (() => refresh ());
		dialog.present ();
	}

	private bool is_pinned () {
		return pinned != null && pinned != "";
	}

	private void update_subtitle () {
		if (is_pinned ())
			base.subtitle = "📌 Pinned to %s".printf (pinned);
		else if (update_available)
			base.subtitle = "Update available";
		else if (installed_commit != null && installed_commit != "")
			base.subtitle = "Up to date · %s".printf (installed_commit);
		else
			base.subtitle = "External Plugin";
	}

	private void update_pin_button () {
		if (is_pinned ()) {
			pin_button.add_css_class ("have_update");
			pin_button.tooltip_text = "Unpin — follow the latest commit";
		} else {
			pin_button.remove_css_class ("have_update");
			pin_button.tooltip_text = "Pin to the current commit";
		}
	}

	/**
	 * Ask the remote for its HEAD and compare it with the locally installed
	 * commit. The update button only appears when there is a real update.
	 */
	private async void check_update () {
		if (installed_commit == null || installed_commit == "")
			return;
		string output;
		yield Utils.run_async_command (@"git ls-remote $pl_url HEAD", out output);
		if (output == null)
			return;
		var remote = output.strip ();
		var idx = remote.index_of ("\t");
		if (idx < 0)
			idx = remote.index_of (" ");
		if (idx > 0)
			remote = remote.substring (0, idx);
		if (remote == "")
			return;

		update_available = !remote.has_prefix (installed_commit);
		update_button.visible = update_available;
		update_subtitle ();
	}

	// Callbacks
	[GtkCallback]
	public bool toggle_plugin_status (bool state) {
		try {
			if (state)
				Supravim.Plugin.enable (pl_name);
			else
				Supravim.Plugin.disable (pl_name);
		} catch (Error e) {
			warning (e.message);
		}
		return false;
	}

	[GtkCallback]
	public void toggle_pin () {
		try {
			if (is_pinned ()) {
				Supravim.Plugin.unpin (pl_name);
			} else {
				// pin () returns the commit the plugin was frozen on.
				pinned = Supravim.Plugin.pin (pl_name);
			}
		} catch (Error e) {
			var dialog = new DialogPopup (this.get_root () as Gtk.Window,
				"Error Pinning Plugin",
				Utils.remove_color (e.message));
			dialog.add_cancel_button ();
			dialog.present ();
			return;
		}
		// Reload from libsupravim so every row reflects the new state.
		refresh ();
	}

	[GtkCallback]
	public void update_plugin () {
		try {
			Supravim.Plugin.update (pl_name);
		} catch (Error e) {
			var dialog = new DialogPopup (this.get_root () as Gtk.Window,
				"Error Updating Plugin",
				Utils.remove_color (e.message));
			dialog.add_cancel_button ();
			dialog.present ();
			return;
		}
		refresh ();
	}

	[GtkCallback]
	public void show_uninstall_window() {
		var parent = this.get_root() as Gtk.Window;
		var dialog = new WindowRemovePlugin (parent, pl_name);

		dialog.refresh.connect (() => refresh());
		dialog.present();
	}

	/**
	 * Configuration popup for an installed git plugin. Exposes everything the
	 * libsupravim API offers for a single plugin: open the repository, toggle
	 * it, pin/unpin its commit, update it when a newer commit exists and
	 * uninstall it.
	 */
	public class WindowConfigurePlugin : DialogPopup {

		public signal void refresh ();

		public WindowConfigurePlugin (Gtk.Window parent, string name, string url,
				string? installed_commit, string? pinned, bool enabled,
				bool update_available) {
			base (parent, name, url != "" ? url : null);

			bool is_pinned = (pinned != null && pinned != "");

			var group = new Adw.PreferencesGroup ();

			// --- Repository: open the page in the browser. ---
			if (url != "") {
				var repo_row = new Adw.ActionRow () {
					title = "Repository",
					subtitle = url,
					activatable = true
				};
				var open_btn = new Gtk.Button.from_icon_name ("web-browser-symbolic") {
					valign = Gtk.Align.CENTER,
					tooltip_text = "Open in browser"
				};
				open_btn.clicked.connect (() => {
					try {
						AppInfo.launch_default_for_uri (url, null);
					} catch (Error e) {
						warning ("Could not open %s: %s", url, e.message);
					}
				});
				repo_row.add_suffix (open_btn);
				repo_row.activated.connect (() => open_btn.clicked ());
				group.add (repo_row);
			}

			// --- Enabled toggle. ---
			var enable_row = new Adw.ActionRow () { title = "Enabled" };
			var enable_sw = new Gtk.Switch () {
				valign = Gtk.Align.CENTER,
				active = enabled
			};
			enable_sw.state_set.connect ((state) => {
				try {
					if (state)
						Supravim.Plugin.enable (name);
					else
						Supravim.Plugin.disable (name);
				} catch (Error e) {
					warning (e.message);
				}
				return false;
			});
			enable_row.add_suffix (enable_sw);
			enable_row.activatable_widget = enable_sw;
			group.add (enable_row);

			// --- Commit / pin management. ---
			var commit_row = new Adw.ActionRow () {
				title = is_pinned ? "Pinned commit" : "Installed commit",
				subtitle = is_pinned
					? pinned
					: ((installed_commit != null && installed_commit != "")
						? installed_commit : "unknown")
			};
			var pin_btn = new Gtk.Button.with_label (is_pinned ? "Unpin" : "Pin") {
				valign = Gtk.Align.CENTER,
				tooltip_text = is_pinned
					? "Follow the latest commit again"
					: "Freeze this plugin on its current commit"
			};
			if (is_pinned)
				pin_btn.add_css_class ("have_update");
			pin_btn.clicked.connect (() => {
				try {
					if (is_pinned)
						Supravim.Plugin.unpin (name);
					else
						Supravim.Plugin.pin (name);
				} catch (Error e) {
					var d = new DialogPopup (this.get_root () as Gtk.Window,
						"Error Pinning Plugin", Utils.remove_color (e.message));
					d.add_cancel_button ();
					d.present ();
					return;
				}
				this.refresh ();
				this.close ();
			});
			commit_row.add_suffix (pin_btn);
			group.add (commit_row);

			// --- Update (only when a newer commit exists and not pinned). ---
			if (update_available && !is_pinned) {
				var up_row = new Adw.ActionRow () {
					title = "Update available",
					subtitle = "A newer commit exists on the remote"
				};
				var up_btn = new Gtk.Button.with_label ("Update") {
					valign = Gtk.Align.CENTER,
					css_classes = {"suggested-action"}
				};
				up_btn.clicked.connect (() => {
					try {
						Supravim.Plugin.update (name);
					} catch (Error e) {
						var d = new DialogPopup (this.get_root () as Gtk.Window,
							"Error Updating Plugin", Utils.remove_color (e.message));
						d.add_cancel_button ();
						d.present ();
						return;
					}
					this.refresh ();
					this.close ();
				});
				up_row.add_suffix (up_btn);
				group.add (up_row);
			}

			base.box_main.append (group);

			// --- Uninstall / Close buttons. ---
			var btn_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 30) {
				homogeneous = true,
				hexpand = true,
				css_classes = {"dialog_button"}
			};
			var uninstall_button = new Gtk.Button.with_label ("Uninstall") {
				css_classes = {"destructive-action", "button_popup"}
			};
			uninstall_button.clicked.connect (() => {
				try {
					Supravim.Plugin.remove (name);
				} catch (Error e) {
					warning (e.message);
				}
				this.refresh ();
				this.close ();
			});
			var close_button = new Gtk.Button.with_label ("Close") {
				css_classes = {"button_popup"}
			};
			close_button.clicked.connect (() => this.close ());
			btn_box.append (uninstall_button);
			btn_box.append (close_button);
			base.box_main.append (btn_box);
		}
	}

	/**
  	 * Class for the Popup Window to remove a plugin
  	 */
	public class WindowRemovePlugin : DialogPopup {
		public WindowRemovePlugin (Gtk.Window mainWindow, string name) {
			base (mainWindow, "Uninstall Plugin", @"Are you sure you want to uninstall '$name' plugin?");
			base.add_cancel_button ();

			var uninstall_button = new Gtk.Button.with_label(@"Uninstall $name") {
				css_classes = {"destructive-action", "button_popup"},
			};

			uninstall_button.clicked.connect (() => {
				try {
					Supravim.Plugin.remove (name);
				} catch (Error e) {
					warning (e.message);
				}
				refresh ();
				base.close ();
			});

			box_buttons.append(uninstall_button);
			base.present();
		}
		public signal void refresh();
	}
}
