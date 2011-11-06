package away3d.errors
{
	public class DeprecationError extends Error
	{
		private var _since : String;
		private var _source : String;
		private var _info : String;


		public function DeprecationError(source : String, since : String, info : String)
		{
			super(source + " has been marked as deprecated since version " + since + " and has been slated for removal. "+info);
			_since = since;
			_source = source;
			_info = info;
		}

		public function get since() : String
		{
			return _since;
		}

		public function get source() : String
		{
			return _source;
		}

		public function get info() : String
		{
			return _info;
		}
	}
}
