package away3d.animators.nodes
{
	import away3d.*;
	import away3d.animators.*;
	import away3d.animators.data.*;
	import away3d.animators.states.*;
	import away3d.materials.compilation.*;
	import away3d.materials.passes.*;
	
	use namespace arcane;
	
	/**
	 * A particle animation node used to create a follow behaviour on a particle system.
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
			
			super("ParticleFollow", ParticlePropertiesMode.LOCAL_DYNAMIC, (_usesPosition && _usesRotation)? 6 : 3, ParticleAnimationSet.POST_PRIORITY);
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
				
				var len:int = animationRegisterCache.rotationRegisters.length;
				var i:int;
				
				//x axis
				code += "mov " + temp1 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp1 + ".x," + animationRegisterCache.vertexOneConst + "\n";
				code += "mov " + temp3 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "sin " + temp3 + ".y," + rotationAttribute + ".x\n";
				code += "cos " + temp3 + ".z," + rotationAttribute + ".x\n";
				code += "mov " + temp2 + ".x," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp2 + ".y," + temp3 + ".z\n";
				code += "neg " + temp2 + ".z," + temp3 + ".y\n";
				
				if (animationRegisterCache.hasBillboard)
				{
					code += "m33 " + temp1 + ".xyz," + animationRegisterCache.positionTarget + "," + temp1 + "\n";
					code += "sub " + temp1 + "," + temp1 + "," + animationRegisterCache.positionTarget + "\n";
					code += "add " + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "," + animationRegisterCache.scaleAndRotateTarget + "\n";
				}
				else
				{
					code += "m33 " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "\n";
					for (i = 0; i < len; i++)
					{
						code += "m33 " + animationRegisterCache.rotationRegisters[i] + ".xyz," + animationRegisterCache.rotationRegisters[i] + "," + temp1 + "\n";
					}
				}
				
				//y axis
				code += "mov " + temp1 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "cos " + temp1 + ".x," + rotationAttribute + ".y\n";
				code += "sin " + temp1 + ".z," + rotationAttribute + ".y\n";
				code += "mov " + temp2 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp2 + ".y," + animationRegisterCache.vertexOneConst + "\n";
				code += "mov " + temp3 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "neg " + temp3 + ".x," + temp1 + ".z\n";
				code += "mov " + temp3 + ".z," + temp1 + ".x\n";
				
				if (animationRegisterCache.hasBillboard)
				{
					code += "m33 " + temp1 + ".xyz," + animationRegisterCache.positionTarget + "," + temp1 + "\n";
					code += "sub " + temp1 + "," + temp1 + "," + animationRegisterCache.positionTarget + "\n";
					code += "add " + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "," + animationRegisterCache.scaleAndRotateTarget + "\n";
				}
				else
				{
					code += "m33 " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "\n";
					for (i = 0; i < len; i++)
					{
						code += "m33 " + animationRegisterCache.rotationRegisters[i] + ".xyz," + animationRegisterCache.rotationRegisters[i] + "," + temp1 + "\n";
					}
				}
				
				//z axis
				code += "mov " + temp2 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "sin " + temp2 + ".x," + rotationAttribute + ".z\n";
				code += "cos " + temp2 + ".y," + rotationAttribute + ".z\n";
				code += "mov " + temp1 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp1 + ".x," + temp2 + ".y\n";
				code += "neg " + temp1 + ".y," + temp2 + ".x\n";
				code += "mov " + temp3 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp3 + ".z," + animationRegisterCache.vertexOneConst + "\n";
				
				if (animationRegisterCache.hasBillboard)
				{
					code += "m33 " + temp1 + ".xyz," + animationRegisterCache.positionTarget + "," + temp1 + "\n";
					code += "sub " + temp1 + "," + temp1 + "," + animationRegisterCache.positionTarget + "\n";
					code += "add " + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "," + animationRegisterCache.scaleAndRotateTarget + "\n";
				}
				else
				{
					code += "m33 " + animationRegisterCache.scaleAndRotateTarget + "," + animationRegisterCache.scaleAndRotateTarget + "," + temp1 + "\n";
					for (i = 0; i < len; i++)
					{
						code += "m33 " + animationRegisterCache.rotationRegisters[i] + ".xyz," + animationRegisterCache.rotationRegisters[i] + "," + temp1 + "\n";
					}
				}
				
			}
			
			if (_usesPosition) {
				var positionAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
				animationRegisterCache.setRegisterIndex(this, FOLLOW_POSITION_INDEX, positionAttribute.index);
				code += "add " + animationRegisterCache.scaleAndRotateTarget + "," + positionAttribute + "," + animationRegisterCache.scaleAndRotateTarget + "\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticleFollowState
		{
			return animator.getAnimationState(this) as ParticleFollowState;
		}
	}

}
