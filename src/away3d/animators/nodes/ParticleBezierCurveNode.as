package away3d.animators.nodes
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.states.ParticleBezierCurveState;
	import away3d.arcane;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;

	import flash.geom.Vector3D;

	use namespace arcane;
	
	/**
	 * A particle animation node used to control the position of a particle over time along a bezier curve.
	 */
	public class ParticleBezierCurveNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const BEZIER_CONTROL_INDEX:int = 0;
		
		/** @private */
		arcane static const BEZIER_END_INDEX:int = 1;
		
		/** @private */
		arcane var _controlPoint:Vector3D;
		/** @private */
		arcane var _endPoint:Vector3D;
		
		/**
		 * Reference for bezier curve node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the control point position (0, 1, 2) of the curve.
		 */
		public static const BEZIER_CONTROL_VECTOR3D:String = "BezierControlVector3D";
		
		/**
		 * Reference for bezier curve node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the end point position (0, 1, 2) of the curve.
		 */
		public static const BEZIER_END_VECTOR3D:String = "BezierEndVector3D";
		
		/**
		 * Creates a new <code>ParticleBezierCurveNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] controlPoint    Defines the default control point of the node, used when in global mode.
		 * @param    [optional] endPoint        Defines the default end point of the node, used when in global mode.
		 */
		public function ParticleBezierCurveNode(mode:uint, controlPoint:Vector3D = null, endPoint:Vector3D = null)
		{
			super("ParticleBezierCurve", mode, 6);
			
			_stateClass = ParticleBezierCurveState;
			
			_controlPoint = controlPoint || new Vector3D();
			_endPoint = endPoint || new Vector3D();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(shaderObject:ShaderObjectBase, animationRegisterCache:AnimationRegisterCache):String
		{
			var controlValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, BEZIER_CONTROL_INDEX, controlValue.index);
			
			var endValue:ShaderRegisterElement = (_mode == ParticlePropertiesMode.GLOBAL)? animationRegisterCache.getFreeVertexConstant() : animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, BEZIER_END_INDEX, endValue.index);
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var rev_time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
			var time_2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
			var time_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 2);
			animationRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index);
			animationRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "sub " + rev_time + "," + animationRegisterCache.vertexOneConst + "," + animationRegisterCache.vertexLife + "\n";
			code += "mul " + time_2 + "," + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexLife + "\n";
			
			code += "mul " + time_temp + "," + animationRegisterCache.vertexLife + "," + rev_time + "\n";
			code += "mul " + time_temp + "," + time_temp + "," + animationRegisterCache.vertexTwoConst + "\n";
			code += "mul " + distance + ".xyz," + time_temp + "," + controlValue + "\n";
			code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
			code += "mul " + distance + ".xyz," + time_2 + "," + endValue + "\n";
			code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
			
			if (animationRegisterCache.needVelocity) {
				code += "mul " + time_2 + "," + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexTwoConst + "\n";
				code += "sub " + time_temp + "," + animationRegisterCache.vertexOneConst + "," + time_2 + "\n";
				code += "mul " + time_temp + "," + animationRegisterCache.vertexTwoConst + "," + time_temp + "\n";
				code += "mul " + distance + ".xyz," + controlValue + "," + time_temp + "\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
				code += "mul " + distance + ".xyz," + endValue + "," + time_2 + "\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:AnimatorBase):ParticleBezierCurveState
		{
			return animator.getAnimationState(this) as ParticleBezierCurveState;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			var bezierControl:Vector3D = param[BEZIER_CONTROL_VECTOR3D];
			if (!bezierControl)
				throw new Error("there is no " + BEZIER_CONTROL_VECTOR3D + " in param!");
			
			var bezierEnd:Vector3D = param[BEZIER_END_VECTOR3D];
			if (!bezierEnd)
				throw new Error("there is no " + BEZIER_END_VECTOR3D + " in param!");
			
			_oneData[0] = bezierControl.x;
			_oneData[1] = bezierControl.y;
			_oneData[2] = bezierControl.z;
			_oneData[3] = bezierEnd.x;
			_oneData[4] = bezierEnd.y;
			_oneData[5] = bezierEnd.z;
		}
	}

}
