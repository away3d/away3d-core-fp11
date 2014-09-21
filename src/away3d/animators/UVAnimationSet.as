package away3d.animators
{
	import away3d.animators.IAnimationSet;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.passes.MaterialPassBase;
	import away3d.managers.Stage3DProxy;
	
	import flash.display3D.Context3D;
	
	/**
	 * The animation data set used by uv-based animators, containing uv animation state data.
	 *
	 * @see away3d.animators.UVAnimator
	 * @see away3d.animators.UVAnimationState
	 */
	public class UVAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		private var _agalCode:String;
		
		public function UVAnimationSet()
		{
		
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(shaderObject:ShaderObjectBase):String
		{
			var len:uint = shaderObject.animationTargetRegisters.length;
			_agalCode = "";
			for(var i:uint = 0; i<len; i++) {
				_agalCode += "mov " + shaderObject.animationTargetRegisters[i] + ", " + shaderObject.animatableAttributes[i] + "\n";
			}
			return _agalCode;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function activate(shaderObject:ShaderObjectBase, stage3DProxy:Stage3DProxy):void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		override public function deactivate(shaderObject:ShaderObjectBase, stage3DProxy:Stage3DProxy):void
		{
			var context:Context3D = stage3DProxy.context3D;
			context.setVertexBufferAt(0, null);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALFragmentCode(shaderObject:ShaderObjectBase, shadedTarget:String):String
		{
			return "";
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALUVCode(shaderObject:ShaderObjectBase):String
		{
			var tempUV:String = "vt" + shaderObject.uvSource.substring(2, 3);
			var idConstant:int = shaderObject.numUsedVertexConstants;
			var uvTranslateReg:String = "vc" + (idConstant);
			var uvTransformReg:String = "vc" + (idConstant + 4);

			_agalCode = "mov " + tempUV + ", " + shaderObject.uvSource + "\n";
			_agalCode += "sub " + tempUV + ".xy, " + tempUV + ".xy, " + uvTranslateReg + ".zw \n";
			_agalCode += "m44 " + tempUV + ", " + tempUV + ", " + uvTransformReg + "\n";
			_agalCode += "add " + tempUV + ".xy, " + tempUV + ".xy, " + uvTranslateReg + ".xy \n";
			_agalCode += "add " + tempUV + ".xy, " + tempUV + ".xy, " + uvTranslateReg + ".zw \n";
			_agalCode += "mov " + shaderObject.uvTarget + ", " + tempUV + "\n";
			
			return _agalCode;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function doneAGALCode(shaderObject:ShaderObjectBase):void
		{
		}
	}
}
