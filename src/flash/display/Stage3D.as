package flash.display
{
	import flash.display3D.Context3D;
	import flash.events.EventDispatcher;

	/**
	 * STRICTLY TEMPORARY STAGE3D MOCK CLASS. Remove when latest playerglobal.swc is available
	 */
	public class Stage3D extends EventDispatcher
	{

		public function get context3D () : Context3D { return null;  };

		public function requestContext3D (context3DRenderMode:String = "auto") : void { };

		public function Stage3D () {};

		public var x:Number;
		public var y:Number;
	}
}
