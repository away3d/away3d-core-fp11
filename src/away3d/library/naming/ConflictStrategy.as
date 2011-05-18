package away3d.library.naming
{
	public class ConflictStrategy
	{
		public static const IGNORE : ConflictStrategyBase = new IgnoreConflictStrategy();
		public static const APPEND_NUM_SUFFIX : ConflictStrategyBase = new NumSuffixConflictStrategy();
		public static const THROW_ERROR : ConflictStrategyBase = new ErrorConflictStrategy();
		
	}
}