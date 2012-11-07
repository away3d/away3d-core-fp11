package away3d.animators.nodes
{
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.states.ParticleFollowState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleFollowNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const FOLLOW_POSITION_INDEX:uint = 0;
		
		/** @private */
		arcane static const FOLLOW_ROTATION_INDEX:uint = 1;
		
		/** @private */
		arcane var _usesPosition:Boolean;
		
		/** @private */
		arcane var _usesRotation:Boolean;
						
		/**
		 * Creates a new <code>ParticleFollowNode</code>
		 *
		 * @param    [optional] usesPosition     Defines wehether the individual particle reacts to the position of the target.
		 * @param    [optional] usesRotation     Defines wehether the individual particle reacts to the rotation of the target.
		 */
		public function ParticleFollowNode(usesPosition:Boolean = true, usesRotation:Boolean = true)
		{
			_stateClass = ParticleFollowState;
			
			_usesPosition = usesPosition;
			_usesRotation = usesRotation;
			
			super("ParticleFollowNode", ParticlePropertiesMode.LOCAL_DYNAMIC, (_usesPosition && _usesRotation)? 6 : 3, ParticleAnimationSet.POST_PRIORITY);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			var code:String = "";
			if (_usesRotation) {
				var rotationAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
				animationRegisterCache.setRegisterIndex(this, FOLLOW_ROTATION_INDEX, rotationAttribute.index);
				
				var temp1:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(temp1, 1);
				var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(temp2, 1);
				var temp3:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				
				animationRegisterCache.removeVertexTempUsage(temp1);
				animationRegisterCache.removeVertexTempUsage(temp2);
				
				code += "mov " + temp1 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "cos " + temp1 + ".x," + rotationAttribute + ".x\n";
				code += "sin " + temp1 + ".y," + rotationAttribute + ".x\n";
				code += "mov " + temp2 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "neg " + temp2 + ".x," + temp1 + ".y\n";
				code += "mov " + temp2 + ".y," + temp1 + ".x\n";
				code += "mov " + temp3 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp3 + ".z," + animationRegisterCache.vertexOneConst + "\n";
				code += "m33 " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "\n";
				
				code += "mov " + temp1 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp1 + ".x," + animationRegisterCache.vertexOneConst + "\n";
				code += "mov " + temp2 + ".x," + animationRegisterCache.vertexZeroConst + "\n";
				code += "cos " + temp2 + ".y," + rotationAttribute + ".y\n";
				code += "sin " + temp2 + ".z," + rotationAttribute + ".y\n";
				code += "mov " + temp3 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "neg " + temp3 + ".y," + temp2 + ".z\n";
				code += "mov " + temp3 + ".z," + temp2 + ".y\n";
				code += "m33 " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "\n";
				
				code += "cos " + temp1 + ".x," + rotationAttribute + ".z\n";
				code += "sin " + temp1 + ".y," + rotationAttribute + ".z\n";
				code += "mov " + temp1 + ".z," + animationRegisterCache.vertexZeroConst + "\n";
				code += "neg " + temp2 + ".x," + temp1 + ".y\n";
				code += "mov " + temp2 + ".y," + temp1 + ".x\n";
				code += "mov " + temp2 + ".z," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp3 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp3 + ".z," + animationRegisterCache.vertexOneConst + "\n";
				code += "m33 " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "\n";
			}
			
			if (_usesPosition) {
				var positionAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
				animationRegisterCache.setRegisterIndex(this, FOLLOW_POSITION_INDEX, positionAttribute.index);
				code += "add " + animationRegisterCache.scaleAndRotateTarget + "," + positionAttribute + "," + animationRegisterCache.scaleAndRotateTarget + "\n";
			}
			
			return code;
		}
	}

}
