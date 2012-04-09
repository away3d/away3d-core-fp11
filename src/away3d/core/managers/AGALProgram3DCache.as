package away3d.core.managers
{
	import away3d.arcane;
	import away3d.debug.Debug;
	import away3d.events.Stage3DEvent;
	import away3d.materials.passes.MaterialPassBase;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;

	use namespace arcane;

	public class AGALProgram3DCache
	{
		private static var _instances : Vector.<AGALProgram3DCache>;

		private var _stage3DProxy : Stage3DProxy;

		private var _program3Ds : Array;
		private var _ids : Array;
		private var _usages : Array;
		private var _keys : Array;

		private static var _currentId : int;


		public function AGALProgram3DCache(stage3DProxy : Stage3DProxy, AGALProgram3DCacheSingletonEnforcer : AGALProgram3DCacheSingletonEnforcer)
		{
			if (!AGALProgram3DCacheSingletonEnforcer) throw new Error("This class is a multiton and cannot be instantiated manually. Use Stage3DManager.getInstance instead.");
			_stage3DProxy = stage3DProxy;

			_program3Ds = [];
			_ids = [];
			_usages = [];
			_keys = [];
		}

		public static function getInstance(stage3DProxy : Stage3DProxy) : AGALProgram3DCache
		{
			var index : int = stage3DProxy._stage3DIndex;

			_instances ||= new Vector.<AGALProgram3DCache>(8, true);

			if (!_instances[index]) {
				_instances[index] = new AGALProgram3DCache(stage3DProxy, new AGALProgram3DCacheSingletonEnforcer());
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed, false, 0, true);
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DDisposed,false,0,true);
			}

			return _instances[index];
		}

		public static function getInstanceFromIndex(index : int) : AGALProgram3DCache
		{
			if (!_instances[index]) throw new Error("Instance not created yet!");
			return _instances[index];
		}

		private static function onContext3DDisposed(event : Stage3DEvent) : void
		{
			var stage3DProxy : Stage3DProxy = Stage3DProxy(event.target);
			var index : int = stage3DProxy._stage3DIndex;
			_instances[index].dispose();
			_instances[index] = null;
			stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
			stage3DProxy.removeEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DDisposed);
		}

		public function dispose() : void
		{
			for (var key : String in _program3Ds)
				destroyProgram(key);

			_keys = null;
			_program3Ds = null;
			_usages = null;
		}

		public function setProgram3D(pass : MaterialPassBase, vertexCode : String, fragmentCode : String) : void
		{
			var stageIndex : int = _stage3DProxy._stage3DIndex;
			var program : Program3D;
			var key : String = getKey(vertexCode, fragmentCode);

			if (_program3Ds[key] == null) {
				_keys[_currentId] = key;
				_usages[_currentId] = 0;
				_ids[key] = _currentId;
				++_currentId;
				program = _stage3DProxy._context3D.createProgram();

				var vertexByteCode : ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, vertexCode);
				var fragmentByteCode : ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, fragmentCode);

				program.upload(vertexByteCode, fragmentByteCode);

				_program3Ds[key] = program;
			}

			var oldId : int = pass._program3Dids[stageIndex];
			var newId : int = _ids[key];

			if (oldId != newId) {
				if (oldId >= 0) freeProgram3D(oldId);
				_usages[newId]++;
			}

			pass._program3Dids[stageIndex] = newId;
			pass._program3Ds[stageIndex] = _program3Ds[key];
		}

		public function freeProgram3D(programId : int) : void
		{
			_usages[programId]--;
			if (_usages[programId] == 0) destroyProgram(_keys[programId]);
		}

		private function destroyProgram(key : String) : void
		{
			_program3Ds[key].dispose();
			_program3Ds[key] = null;
			delete _program3Ds[key];
			_ids[key] = -1;
		}

		private function getKey(vertexCode : String, fragmentCode : String) : String
		{
			return vertexCode + "---" + fragmentCode;
		}
	}
}

class AGALProgram3DCacheSingletonEnforcer
{
}