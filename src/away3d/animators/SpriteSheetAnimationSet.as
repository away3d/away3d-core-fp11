package away3d.animators
{
    import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;

    /**
	 * The animation data set containing the Spritesheet animation state data.
	 *
	 * @see away3d.animators.SpriteSheetAnimator
	 * @see away3d.animators.SpriteSheetAnimationState
	 */
	public class SpriteSheetAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		private var _agalCode:String;
		
		function SpriteSheetAnimationSet()
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
//			var context:Context3D = stage3DProxy.context3D;
//			context.setVertexBufferAt(0, null);
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
			var constantRegID:String = "vc" + idConstant;

			_agalCode = "mov " + tempUV + ", " + shaderObject.uvSource + "\n";
			_agalCode += "mul " + tempUV + ".xy, " + tempUV + ".xy, " + constantRegID + ".zw \n";
			_agalCode += "add " + tempUV + ".xy, " + tempUV + ".xy, " + constantRegID + ".xy \n";
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

