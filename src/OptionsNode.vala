/**
 * A simple tree structure to hold options with hierarchical names
 * Ex
 */
public class OptionsNode {
	// Attributes
	private static StringChunk				chunk = new StringChunk(256);
	private unowned OptionsNode?			parent;
	public GenericArray<OptionsNode>		children = new GenericArray<OptionsNode>();

	public unowned string real_name { get; private set; default = null; }
	public unowned string name { get; private set; }
	public unowned string? lore { get; private set; default = null; }
	public unowned string? value { get; private set; default = null; }

	private static int count = 0;

	/**
	 * Constructor
	 */
	public OptionsNode (string name = "", OptionsNode ?parent = null, string? lore = null, string? @value = null) {
		++count;
		if (lore != null)
			this.lore = chunk.insert(lore);
		if (value != null)
			this.value = chunk.insert(@value);
		this.name = chunk.insert(name);
		this.parent = parent;
		real_name = chunk.insert(name);
	}

	~OptionsNode () {
		if (--count == 0)
			chunk = null;
	}

	/**
	 * ForEach support
	 */
	public uint size {
		get {
			return children.length;
		}
	}

	public unowned OptionsNode get (uint index) {
		return children.data[index];
	}

	/**
	 * Append an option to the tree
	 */
	public void append (string new_child_name, string lore, string value) {
		OptionsNode	new_child = new OptionsNode(new_child_name, this, lore, value);
		int		pos = int.MAX;

		if (new_child_name.contains ("_")) {
			unowned uint8 []data_child = new_child.name.data;
			foreach (unowned var child in children) {
				if (!child.name.contains ("_") && child.children.length == 0)
					continue;
				var tmp_pos = get_prefix_length (data_child, child.name.data);
				if (tmp_pos > 0 && tmp_pos < pos)
					pos = tmp_pos;
			}
		}
		if (pos != int.MAX) {
			OptionsNode	sub_node;
			uint	sub_node_idx;

			// Set sub_node based on name
			if (this.children.find_with_equal_func (new OptionsNode(new_child_name[:pos]), 
						(a, b) => a.name == b.name, out sub_node_idx))
				sub_node = this.children[sub_node_idx];
			else
				sub_node = this.create_subnode(new_child_name[:pos]);
			new_child.name = chunk.insert(new_child.name.offset(pos + 1));
			sub_node.append_node(new_child);
			return ;
		} else
			children.add(new_child);
	}

	private static int	get_prefix_length(uint8[] s1, uint8[] s2) {
		int len1 = s1.length;
		int len2 = s2.length;
		int	i = 0;

		while (i < len1 && i < len2 && s1[i] == s2[i])
			++i;
		while (i > 0 && s1[i] != '_')
			--i;
		return i;
	}

	private OptionsNode	create_subnode (string node_name) {
		int		name_len = node_name.length;
		OptionsNode	sub_node = new OptionsNode(node_name, this);

		foreach (unowned var child in children) {
			if (!child.name.has_prefix (node_name))
				continue;
			child.name = child.name.offset(name_len + 1);
			sub_node.append_node (child);
			this.children.remove (child);
		}
		if (!children.find(sub_node))
			this.append_node (sub_node);
		return sub_node;
	}

	private void append_node (OptionsNode node) {
		node.parent = this;
		children.add(node);
	}

	// public void display_tree(int depth = 0) {
		// stdout.printf("%-*s%s [%s][%s]\n", (depth * 2), " ", this.name, this.real_name, this.lore);
		// foreach (unowned var child in this.children)
			// child.display_tree (depth + 1);
	// }
}
