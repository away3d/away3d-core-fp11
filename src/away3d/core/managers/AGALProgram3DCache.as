package away3d.core.managers
{
	import away3d.arcane;
	import away3d.debug.Debug;
	import away3d.events.Stage3DEvent;
	import away3d.materials.passes.MaterialPassBase;
	import flash.utils.Dictionary;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3DProgramType;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;

	use namespace arcane;

	public class AGALProgram3DCache
	{
		private static var _instances : Vector.<AGALProgram3DCache>;

		private var _stage3DProxy : Stage3DProxy;

		private var _program3Ds : Dictionary;
		private var _ids : Dictionary;

		private var _currentId : int;


		public function AGALProgram3DCache(stage3DProxy : Stage3DProxy, AGALProgram3DCacheSingletonEnforcer : AGALProgram3DCacheSingletonEnforcer)
		{
			if (!AGALProgram3DCacheSingletonEnforcer) throw new Error("This class is a multiton and cannot be instantiated manually. Use Stage3DManager.getInstance instead.");
			_stage3DProxy = stage3DProxy;

			_program3Ds = new Dictionary(true);
			_ids = new Dictionary();
		}

		public static function getInstance(stage3DProxy : Stage3DProxy) : AGALProgram3DCache
		{
			var index : int = stage3DProxy._stage3DIndex;

			_instances ||= new Vector.<AGALProgram3DCache>(8, true);

			if (!_instances[index]) {
				_instances[index] = new AGALProgram3DCache(stage3DProxy, new AGALProgram3DCacheSingletonEnforcer());
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed, false, 0, true);
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, onContext3DDisposed, false, 0, true);
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
		}

		public function dispose() : void
		{
			for (var key : Object in _program3Ds) {
				(key as Program3D).dispose();
			}
		}

		public function setProgram3D(pass : MaterialPassBase, vertexCode : String, fragmentCode : String) : void
		{
			var stageIndex : int = _stage3DProxy._stage3DIndex;
			var program : Program3D;
			var key : String = getKey(vertexCode, fragmentCode);
			
			
			for (var cachedProgram3D:Object in _program3Ds)
			{
				if (_program3Ds[cachedProgram3D] == key)
				{
					program = cachedProgram3D as Program3D;
					break;
				}
			}
			
			if (!program) 
			{
				program = _stage3DProxy._context3D.createProgram();
 
 				var vertexByteCode : ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, vertexCode);
 				var fragmentByteCode : ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, fragmentCode);
				
				program.upload(vertexByteCode, fragmentByteCode);
				_program3Ds[program] = key;
				_ids[key] = _currentId;
				++_currentId;
			}
			
			pass._program3Dids[stageIndex] = _ids[key];
			pass._program3Ds[stageIndex] = program;
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