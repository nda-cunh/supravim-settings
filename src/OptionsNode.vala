public abstract class ONode { }

public class OptionsONode : ONode {
	private SupravimOption option;

	public OptionsONode (SupravimOption option) {
		this.option = option;
	}

	// Getters
	public unowned string type_value {
		get {
			return option.type;
		}
	}
	public unowned string name {
		get {
			return option.id;
		}
	}
	public unowned string lore {
		get {
			return option.lore;
		}
	}
	public unowned string value {
		get {
			return option.value;
		}
	}
	public unowned string default_value {
		get {
			return option.default_value;
		}
	}
}

public class GroupONode : ONode {
	private string parent_name = "";
	public string name_of_group {get; private set; }
	public string lore_of_group {get; private set; }

	public GenericArray<ONode> children = new GenericArray<ONode>();

	public GroupONode (string name, string parent_name = "") {
		this.parent_name = parent_name;
		this.name_of_group = name;

		if (parent_name in SupraParser.group_lores) {
			this.lore_of_group = SupraParser.group_lores[parent_name].lore;
		} else {
			this.lore_of_group = "???";
		}
	}

	private void add (string name_options, SupravimOption option) {
		uint8 buffer[256];
		uint index;
		int idx = name_options.index_of_char('/');
		if (idx == -1) {
			children.add (new OptionsONode(option));
			return;
		}

		unowned string ptr = name_options.offset(idx + 1);
		Memory.copy (buffer, name_options.data, idx);
		buffer[idx] = 0;

		bool found = children.find_custom<string> ((string)buffer, (node, needle) => {
			if (node is GroupONode) {
				return node.name_of_group == needle;
			}
			return false;
		}, out index);

		if (found) {
			var? group_node = children.data[index] as GroupONode;
			group_node?.add(ptr, option);
		} else {
			string prefix;
			 if (parent_name == "") {
				prefix = name_options[0:idx];
			} else {
				prefix = parent_name + "/" + name_options[0:idx];
			}
			var new_group = new GroupONode(name_options[0:idx], prefix);
			children.add(new_group);
			new_group.add(ptr, option);
		}

	}

	public void add_element (SupravimOption option) {
		add(option.id, option);
	}

	
	/**
	  * Foreach support 
	  */
	public uint size {
		get {
			return children.length;
		}
	}

	public unowned ONode get (uint index) {
		return children.data[index];
	}

	// NOTE Printing the tree for debug purposes
	// public void print_me (int depth = 0) {
		// print (string.nfill (depth + 0, ' ') + "\033[96;1mGroup: %s\033[0m\n", name_of_group);
		// foreach (var child in children) {
			// if (child is GroupONode) {
				// (child as GroupONode)?.print_me(depth + 2);
			// } else if (child is OptionsONode) {
				// print (string.nfill (depth + 2, ' ') + "\033[92mOption: %s\033[0m\n", (child as OptionsONode)?.option.id);
			// }
		// }
	// }
} 
