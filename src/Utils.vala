namespace Utils {
	public void command_line (string command) {
		try {
			Process.spawn_command_line_sync (command);
		} catch (Error e) {
			warning (e.message);
		}
	}
}
