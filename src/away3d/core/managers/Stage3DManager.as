package away3d.core.managers
{
	import away3d.arcane;

	import flash.display.Stage;
	import flash.utils.Dictionary;

	use namespace arcane;

	/**
	 * The Stage3DManager class provides a multiton object that handles management for Stage3D objects. Stage3D objects
	 * should not be requested directly, but are exposed by a Stage3DProxy.
	 *
	 * @see away3d.core.managers.Stage3DProxy
	 */
	public class Stage3DManager
	{
		private static var _instances : Dictionary;

		private var _stageProxies : Vector.<Stage3DProxy>;
		private var _stage : Stage;

		/**
		 * Creates a new Stage3DManager class.
		 * @param stage The Stage object that contains the Stage3D objects to be managed.
		 * @private
		 */
		public function Stage3DManager(stage : Stage, singletonEnforcer : SingletonEnforcer)
		{
			if (!singletonEnforcer) throw new Error("This class is a multiton and cannot be instantiated manually. Use Stage3DManager.getInstance instead.");
			_stage = stage;
			_stageProxies = new Vector.<Stage3DProxy>(_stage.stage3Ds.length, true);
		}

		/**
		 * Gets a Stage3DManager instance for the given Stage object.
		 * @param stage The Stage object that contains the Stage3D objects to be managed.
		 * @return The Stage3DManager instance for the given Stage object.
		 */
		public static function getInstance(stage : Stage) : Stage3DManager
		{
			return (_instances ||= new Dictionary())[stage] ||= new Stage3DManager(stage, new SingletonEnforcer());
		}

		/**
		 * Requests the Stage3DProxy for the given index.
		 * @param index The index of the requested Stage3D.
		 * @return The Stage3DProxy for the given index.
		 */
		public function getStage3DProxy(index : uint) : Stage3DProxy
		{
			return _stageProxies[index] ||= new Stage3DProxy(index, _stage.stage3Ds[index], this);
		}

		/**
		 * Removes a Stage3DProxy from the manager.
		 * @param stage3DProxy
		 * @private
		 */
		arcane function removeStage3DProxy(stage3DProxy : Stage3DProxy) : void
		{
			_stageProxies[stage3DProxy.stage3DIndex] = null;
		}

		public function getFreeStage3DProxy() : Stage3DProxy
		{
			var i : uint;
			var len : uint = _stageProxies.length;

			while (i < len) {
				if (!_stageProxies[i]) return getStage3DProxy(i);
				++i;
			}

			throw new Error("Too many Stage3D instances used!");
			return null;
		}
	}
}

class SingletonEnforcer {}