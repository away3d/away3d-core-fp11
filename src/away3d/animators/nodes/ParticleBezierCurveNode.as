package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.ParticleProperties;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.states.ParticleBezierCurveState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleBezierCurveNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const BEZIER_INDEX:int = 0;
		
		private var _controlPoint:Vector3D;
		private var _endPoint:Vector3D;
		
		/**
		 * Reference for bezier curve node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector</code> object representing the control point position (0, 1, 2) and end point position (3, 4, 6) of the curve on the particle.
		 */
		public static const BEZIER_VECTOR:String = "BezierVector";
		
		/**
		 * Defines the default control point of the node, used when in global mode.
		 */
		public function get controlPoint():Vector3D
		{
			return _controlPoint;
		}
		
		public function set controlPoint(value:Vector3D):void
		{
			_controlPoint = value;
		}
		
		/**
		 * Defines the default end point of the node, used when in global mode.
		 */
		public function get endPoint():Vector3D
		{
			return _endPoint;
		}
		
		public function set endPoint(value:Vector3D):void
		{
			_endPoint = value;
		}
		
		/**
		 * Creates a new <code>ParticleBezierCurveNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation acts on local properties of a particle or global properties of the node.
		 * @param    [optional] controlPoint    Defines the default control point of the node, used when in global mode.
		 * @param    [optional] endPoint        Defines the default end point of the node, used when in global mode.
		 */
		public function ParticleBezierCurveNode(mode:uint, controlPoint:Vector3D = null, endPoint:Vector3D = null)
		{
			super("ParticleBezierCurveNode" + mode, mode, 6);
			
			_stateClass = ParticleBezierCurveState;
			
			_controlPoint = controlPoint.clone() || new Vector3D();
			_endPoint = endPoint.clone() || new Vector3D();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			var controlValue:ShaderRegisterElement = (_mode == ParticleProperties.LOCAL)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, BEZIER_INDEX, controlValue.index);
			
			var endValue:ShaderRegisterElement = (_mode == ParticleProperties.LOCAL)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var rev_time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var time_2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var time_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			animationRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			animationRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "sub " + rev_time + "," + animationRegisterCache.vertexOneConst + "," + animationRegisterCache.vertexLife + "\n";
			code += "mul " + time_2 + "," + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexLife + "\n";
			
			code += "mul " + time_temp + "," + animationRegisterCache.vertexLife +"," + rev_time + "\n";
			code += "mul " + time_temp + "," + time_temp +"," + animationRegisterCache.vertexTwoConst + "\n";
			code += "mul " + distance + "," + time_temp +"," + controlValue + "\n";
			code += "add " + animationRegisterCache.positionTarget +".xyz," + distance + "," + animationRegisterCache.positionTarget + ".xyz\n";
			code += "mul " + distance + "," + time_2 +"," + endValue + "\n";
			code += "add " + animationRegisterCache.positionTarget +".xyz," + distance + "," + animationRegisterCache.positionTarget + ".xyz\n";
			
			if (animationRegisterCache.needVelocity)
			{
				code += "mul " + time_2 + "," + animationRegisterCache.vertexLife + "," + animationRegisterCache.vertexTwoConst + "\n";
				code += "sub " + time_temp + "," + animationRegisterCache.vertexOneConst + "," + time_2 + "\n";
				code += "mul " + time_temp + "," + animationRegisterCache.vertexTwoConst + "," + time_temp + "\n";
				code += "mul " + distance + "," + controlValue + "," + time_temp + "\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + "," + animationRegisterCache.velocityTarget + ".xyz\n";
				code += "mul " + distance + "," + endValue + "," + time_2 + "\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + distance + "," + animationRegisterCache.velocityTarget + ".xyz\n";
			}
			
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleProperties):void
		{
			//[controlPoint:Vector3D,endPoint:Vector3D].
			var bezierPoints:Vector.<Vector3D> = param[BEZIER_VECTOR];
			if (!bezierPoints)
				throw new Error("there is no " + BEZIER_VECTOR + " in param!");
			
			_oneData[0] = bezierPoints[0].x;
			_oneData[1] = bezierPoints[0].y;
			_oneData[2] = bezierPoints[0].z;
			_oneData[3] = bezierPoints[1].x;
			_oneData[4] = bezierPoints[1].y;
			_oneData[5] = bezierPoints[1].z;
		}
	}

}