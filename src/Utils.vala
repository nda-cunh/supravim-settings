namespace Utils {
	public void command_line (string command) {
		try {
			string output, error;
			Process.spawn_command_line_sync (command, out output, out error);
		} catch (Error e) {
			warning (e.message);
		}
	}
}
