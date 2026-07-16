namespace Utils {

	public void ach_metric (string name, int64 count = 1) {
		string dir = Path.build_filename (Environment.get_user_config_dir (), "supravim");
		if (!FileUtils.test (dir, FileTest.IS_DIR))
			return;
		try {
			var stream = File.new_for_path (Path.build_filename (dir, "achievements.inbox"))
				.append_to (FileCreateFlags.NONE);
			stream.write ("M %s %lld\n".printf (name, count).data);
			stream.close ();
		} catch (Error e) {
			warning (e.message);
		}
	}

	public void ach_plugin_install (string reference) {
		ach_metric ("plugin_install");
		MainWindow.toast_ach ("collectionneur");
		if (reference.down ().contains ("tpope")) {
			ach_metric ("tpope_install");
			MainWindow.toast_ach ("je_te_connais");
		}
	}

	public int command_line (string command, out string output = null, out string errput = null) {
		int wait_status = -1;
		try {
			Process.spawn_command_line_sync (command, out output, out errput, out wait_status);
		} catch (Error e) {
			errput = e.message;
			warning (errput);
		}
		return wait_status;
	}

	public async int run_async_command (string command, out string output = null, out string errput = null) {
		int wait_status = -1;
		string? output_local = null;
		string? errput_local = null;

		var thread = new Thread<int> (null, () => {
			int status = -1;
			try {
				Process.spawn_command_line_sync(command, out output_local, out errput_local, out status);
			}
			catch (Error e) {
				warning (e.message);
			}
			Idle.add (run_async_command.callback);
			return status;
		});
		yield;
		output = output_local;
		errput = errput_local;
		wait_status = thread.join ();
		return wait_status;
	}

	public string remove_color(string input) {
		// ANSI color code regex pattern
		try {
			var regex = /\x1B\[[0-9;]*[mK]/;
			var result = regex.replace(input, -1, 0, "");
			return result;
		}
		catch (Error e) {
			warning(e.message);
			return input;
		}
	}
}
