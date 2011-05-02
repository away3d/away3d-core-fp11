package away3d.loading.parsers
{
	public class Parsers
	{
		/**
		 * A list of all parsers that come bundled with Away3D. Use it to quickly
		 * enable support for all bundled parsers to the ResourceManager file format
		 * auto-detect feature, using ResourceManager.addParsers():
		 * 
		 * <code>ResourceManager.addParsers(Parsers.ALL_BUNDLED);</code>
		 * 
		 * Beware however that this requires all parser classes to be included in the
		 * SWF file, which will add 50-100 kb to the file. When only a limited set of
		 * file formats are used, SWF file size can be saved by adding the parsers
		 * individually using ResourceManager.addParser().
		 * 
		 * A third way is to specify a parser for each loaded file, thereby bypassing
		 * the auto-detection mechanisms altogether, while at the same time allowing
		 * any properties that are unique to that parser to be set for that load.
		 * 
		 * @see away3d.loading.library.AssetLibrary.addParser()
		*/
		public static const ALL_BUNDLED : Vector.<Class> = Vector.<Class>([
			AC3DParser, AWDParser, Max3DSParser,
			MD2Parser, MD5AnimParser, MD5MeshParser, OBJParser
		]);
	}
}