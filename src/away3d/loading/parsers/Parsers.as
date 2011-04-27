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
		 * @see away3d.loading.ResourceManager.addParser()
		*/
		public static const ALL_BUNDLED : Vector.<Class> = Vector.<Class>([
			AC3DParser, AWD1Parser, AWD2Parser, ColladaParser, Max3DSParser,
			MD2Parser, MD5AnimParser, MD5MeshParser, OBJParser, ImageParser
		]);
	}
}