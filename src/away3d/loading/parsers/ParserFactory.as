package away3d.loading.parsers
{
	import flash.utils.ByteArray;

	public class ParserFactory
	{
		private var _suffixTestFunction : Function;
		private var _dataTestFunction : Function;
		private var _createFunction : Function;
		
		public function ParserFactory(suffixTestFunction : Function, dataTestFunction : Function, createFunction : Function)
		{
			_suffixTestFunction = suffixTestFunction;
			_dataTestFunction = dataTestFunction;
			_createFunction = createFunction;
		}
		
		
		public function parserCreate() : ParserBase
		{
			return _createFunction();
		}
		
		public function parserSupportsSuffix(suffix : String) : Boolean
		{
			return _suffixTestFunction(suffix);
		}
		
		public function parserSupportsData(data : ByteArray) : Boolean
		{
			return _dataTestFunction(data);
		}
	}
}