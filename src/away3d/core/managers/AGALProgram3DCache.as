/**
 *
 */
package away3d.core.managers
{
	import away3d.animators.data.AnimationBase;
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

		private var _currentId : int;


		public function AGALProgram3DCache(stage3DProxy : Stage3DProxy, singletonEnforcer : SingletonEnforcer)
		{
			if (!singletonEnforcer) throw new Error("This class is a multiton and cannot be instantiated manually. Use Stage3DManager.getInstance instead.");
			_stage3DProxy = stage3DProxy;

			_program3Ds = [];
			_ids = [];
			_usages = [];
		}

		public static function getInstance(stage3DProxy : Stage3DProxy) : AGALProgram3DCache
		{
			var index : int = stage3DProxy._stage3DIndex;

			_instances ||= new Vector.<AGALProgram3DCache>(8, true);

			if (!_instances[index]) {
				_instances[index] = new AGALProgram3DCache(stage3DProxy, new SingletonEnforcer());
				stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_DISPOSED, onContext3DDisposed);
			}

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
			var program3D : Program3D;

			for (var key : String in _program3Ds) {
				_program3Ds[key].dispose();
				_program3Ds[key] = null;
				_ids[key] = -1;

				program3D.dispose();
			}

			_program3Ds = null;
			_usages = null;
		}

		public function setProgram3D(pass : MaterialPassBase, animation : AnimationBase, polyOffsetReg : String = null) : void
		{
			var stageIndex : int = _stage3DProxy._stage3DIndex;
			var targetRegisters : Array = pass.getAnimationTargetRegisters();
			var animationVertexCode : String = animation.getAGALVertexCode(pass);
			var materialVertexCode : String = pass.getVertexCode();
			var materialFragmentCode : String = pass.getFragmentCode();
			var projectionVertexCode : String = getProjectionCode(targetRegisters[uint(0)], pass.getProjectedTargetRegister(), polyOffsetReg, targetRegisters.length > 1? targetRegisters[1] : null);
			var vertexCode : String = animationVertexCode+projectionVertexCode+materialVertexCode;
			var program : Program3D;
			var key : String = getKey(vertexCode, materialFragmentCode);
			var oldId : int = pass._program3Dids[stageIndex];

			if (!_program3Ds[key]) {
				_usages[_currentId] = 0;
				_ids[key] = _currentId++;
				program = _stage3DProxy._context3D.createProgram();

				var vertexByteCode : ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, vertexCode);
				var fragmentByteCode : ByteArray = new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, materialFragmentCode);
				program.upload(vertexByteCode, fragmentByteCode);

				_program3Ds[key] = program;
			}

			var newId : int = _ids[key];

			if (oldId != newId) {
				if (oldId > 0) _usages[oldId]--;
				if (_usages[oldId] == 0) destroyProgram(key);
				_usages[newId]++;
			}

			pass._program3Dids[stageIndex] = newId;
			pass._program3Ds[stageIndex] = _program3Ds[key];
		}

		private function destroyProgram(key : String) : void
		{
			_program3Ds[key].dispose();
			_program3Ds[key] = null;
			_ids[key] = -1;
		}

		private function getKey(vertexCode : String,  fragmentCode : String) : String
		{
			return vertexCode + "---" + fragmentCode;
		}

		private function getProjectionCode(positionRegister : String, projectionRegister : String, polyOffsetReg : String, normalRegister : String) : String
		{
			var code : String = "";
			var pos : String;

			if (polyOffsetReg && normalRegister) {
				pos = "vt7";
				code += "mul vt7, "+normalRegister+", "+polyOffsetReg+"\n";
				code += "add vt7, vt7, "+positionRegister+"\n";
				code += "mov vt7.w, "+positionRegister+".w\n";
			}
			else {
				pos = positionRegister;
			}

			if (projectionRegister) {
				code += "m44 "+projectionRegister+", " + pos + ", vc0		\n";
				code += "mov op, " + projectionRegister + "\n";
			}
			else {
				code += "m44 op, "+pos+", vc0		\n";	// 4x4 matrix transform from stream 0 to output clipspace
			}
			return code;
		}
	}
}

class SingletonEnforcer {}