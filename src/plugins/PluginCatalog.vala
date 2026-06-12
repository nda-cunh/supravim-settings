/**
 * A single plugin entry from the embedded store catalog.
 */
public class CatalogEntry : Object {
	public string name;
	public string author;
	public string category;
	public string url;          // git repository (empty for suprapack-only entries)
	public string suprapack;    // suprapack package name (empty for git-only entries)
	public string description;
}

/**
 * Loads the curated list of popular Vim plugins shipped as a gresource
 * (data/plugins-catalog.json). Each entry maps a repository URL to a
 * human friendly name, author, category and description.
 */
namespace PluginCatalog {

	public List<CatalogEntry> load () {
		var entries = new List<CatalogEntry> ();
		try {
			var bytes = resources_lookup_data ("/data/plugins-catalog.json",
				ResourceLookupFlags.NONE);
			unowned uint8[] data = bytes.get_data ();

			var doc = YYJson.Doc.read ((string) data, data.length);
			if (doc == null)
				return entries;

			unowned YYJson.Value root = doc.get_root ();
			if (root == null || root.get_type () != YYJson.Type.ARR)
				return entries;

			size_t count = root.arr_size ();
			for (size_t i = 0; i < count; i++) {
				unowned YYJson.Value? obj = root.arr_get (i);
				if (obj == null || obj.get_type () != YYJson.Type.OBJ)
					continue;

				var entry = new CatalogEntry ();
				entry.name        = member (obj, "name", "");
				entry.author      = member (obj, "author", "");
				entry.category    = member (obj, "category", "Misc");
				entry.url         = member (obj, "url", "");
				entry.suprapack   = member (obj, "suprapack", "");
				entry.description = member (obj, "description", "");

				if (entry.url != "" || entry.suprapack != "")
					entries.append (entry);
			}
		}
		catch (Error e) {
			warning ("Failed to load plugin catalog: %s", e.message);
		}
		return entries;
	}

	// Fetch a string member of a JSON object, falling back when absent.
	private string member (YYJson.Value obj, string key, string fallback) {
		unowned YYJson.Value? value = obj.obj_get (key);
		if (value == null)
			return fallback;
		unowned string? str = value.get_str ();
		return str ?? fallback;
	}

	/**
	 * Normalize a git URL so two equivalent forms compare as equal
	 * (protocol, www, trailing slash and ".git" suffix are ignored).
	 */
	public string normalize_url (string url) {
		var u = url.down ().strip ();
		if (u.has_prefix ("https://"))
			u = u.offset (8);
		else if (u.has_prefix ("http://"))
			u = u.offset (7);
		if (u.has_prefix ("www."))
			u = u.offset (4);
		if (u.has_suffix ("/"))
			u = u.slice (0, u.length - 1);
		if (u.has_suffix (".git"))
			u = u.slice (0, u.length - 4);
		return u;
	}

	public bool same_repo (string a, string b) {
		return normalize_url (a) == normalize_url (b);
	}
}
