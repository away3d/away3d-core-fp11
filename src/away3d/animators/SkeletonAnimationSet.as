package away3d.animators
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.passes.MaterialPassBase;
	
	import flash.display3D.Context3D;
	
	use namespace arcane;
	
	/**
	 * The animation data set used by skeleton-based animators, containing skeleton animation data.
	 *
	 * @see away3d.animators.SkeletonAnimator
	 */
	public class SkeletonAnimationSet extends AnimationSetBase implements IAnimationSet
	{
		private var _jointsPerVertex:uint;
		
		/**
		 * Returns the amount of skeleton joints that can be linked to a single vertex via skinned weight values. For GPU-base animation, the
		 * maximum allowed value is 4.
		 */
		public function get jointsPerVertex():uint
		{
			return _jointsPerVertex;
		}
		
		/**
		 * Creates a new <code>SkeletonAnimationSet</code> object.
		 *
		 * @param jointsPerVertex Sets the amount of skeleton joints that can be linked to a single vertex via skinned weight values. For GPU-base animation, the maximum allowed value is 4. Defaults to 4.
		 */
		public function SkeletonAnimationSet(jointsPerVertex:uint = 4)
		{
			_jointsPerVertex = jointsPerVertex;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(shaderObject:ShaderObjectBase):String
		{
			var len:uint = shaderObject.animatableAttributes.length;
			
			var indexOffset0:uint = shaderObject.numUsedVertexConstants;
			var indexOffset1:uint = indexOffset0 + 1;
			var indexOffset2:uint = indexOffset0 + 2;
			var indexStream:String = "va" + shaderObject.numUsedStreams;
			var weightStream:String = "va" + (shaderObject.numUsedStreams + 1);
			var indices:Array = [ indexStream + ".x", indexStream + ".y", indexStream + ".z", indexStream + ".w" ];
			var weights:Array = [ weightStream + ".x", weightStream + ".y", weightStream + ".z", weightStream + ".w" ];
			var temp1:String = findTempReg(shaderObject.animationTargetRegisters);
			var temp2:String = findTempReg(shaderObject.animationTargetRegisters, temp1);
			var dot:String = "dp4";
			var code:String = "";
			
			for (var i:uint = 0; i < len; ++i) {
				
				var src:String = shaderObject.animatableAttributes[i];
				
				for (var j:uint = 0; j < _jointsPerVertex; ++j) {
					code += dot + " " + temp1 + ".x, " + src + ", vc[" + indices[j] + "+" + indexOffset0 + "]		\n" +
						dot + " " + temp1 + ".y, " + src + ", vc[" + indices[j] + "+" + indexOffset1 + "]    	\n" +
						dot + " " + temp1 + ".z, " + src + ", vc[" + indices[j] + "+" + indexOffset2 + "]		\n" +
						"mov " + temp1 + ".w, " + src + ".w		\n" +
						"mul " + temp1 + ", " + temp1 + ", " + weights[j] + "\n"; // apply weight
					
					// add or mov to target. Need to write to a temp reg first, because an output can be a target
					if (j == 0)
						code += "mov " + temp2 + ", " + temp1 + "\n";
					else
						code += "add " + temp2 + ", " + temp2 + ", " + temp1 + "\n";
				}
				// switch to dp3 once positions have been transformed, from now on, it should only be vectors instead of points
				dot = "dp3";
				code += "mov " + shaderObject.animationTargetRegisters[i] + ", " + temp2 + "\n";
			}
			
			return code;
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
//			var streamOffset:uint = shaderObject.numUsedStreams;
//			var context:Context3D = stage3DProxy._context3D;
//			context.setVertexBufferAt(streamOffset, null);
//			context.setVertexBufferAt(streamOffset + 1, null);
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
			return "mov " + shaderObject.uvTarget + "," + shaderObject.uvSource + "\n";
		}
		
		/**
		 * @inheritDoc
		 */
		override public function doneAGALCode(shaderObject:ShaderObjectBase):void
		{
		
		}
	}
}
