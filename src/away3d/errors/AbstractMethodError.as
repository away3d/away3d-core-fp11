package away3d.errors
{
	
	/**
	 * AbstractMethodError is thrown when an abstract method is called. The method in question should be overridden
	 * by a concrete subclass.
	 */
	public class AbstractMethodError extends Error
	{
		/**
		 * Create a new AbstractMethodError.
		 * @param message An optional message to override the default error message.
		 * @param id The id of the error.
		 */
		public function AbstractMethodError(message:String = null, id:int = 0)
		{
			super(message || "An abstract method was called! Either an instance of an abstract class was created, or an abstract method was not overridden by the subclass.", id);
		}
	}
}
