// SupravimOption, SupravimGroup and SupraParser come from libsupravim
using Supravim;

public class ListSupraOptions {
	private List<SupravimOption?> options;

	public ListSupraOptions () {
		options = new List<SupravimOption?> ();
	}

	public static ListSupraOptions from_vim () throws Error {
		var result = new ListSupraOptions ();
		result.options = SupraParser.get_from_vim ();
		return result;
	}

	public void append (SupravimOption opt) {
		options.append (opt);
	}

	public void sort (CompareFunc<SupravimOption?> cmp) {
		options.sort (cmp);
	}

	public SupravimOption? get_from_name (string name) {
		foreach (var opt in options) {
			if (opt != null && opt.id == name) return opt;
		}
		return null;
	}

	public SupravimOption? get (uint index) {
		return options.nth_data (index);
	}

	public uint size { get { return options.length (); } }

	public Iterator iterator () { return new Iterator (this); }

	public class Iterator {
		private ListSupraOptions list;
		private int idx = -1;
		public Iterator (ListSupraOptions list) { this.list = list; }
		public bool next () { return ++idx < (int) list.size; }
		public SupravimOption? get () { return list.get ((uint) idx); }
	}
}
