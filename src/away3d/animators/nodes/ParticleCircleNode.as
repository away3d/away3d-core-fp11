package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.states.ParticleCircleState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleCircleNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const CIRCLE_INDEX:uint = 0;
		
		/** @private */
		arcane static const EULERS_INDEX:uint = 1;
		
		private var _eulers:Vector3D;
		private var _eulersMatrix:Matrix3D;
				
		/**
		 * Used to set the circle node into local property mode.
		 */
		public static const LOCAL:uint = 0;
		
		/**
		 * Reference for circle node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the radius (x) and cycle speed (y) of the motion on the particle.
		 */
		public static const CIRCLE_VECTOR3D:String = "CircleVector3D";
		
		/** @private */
		arcane function get eulersMatrix():Matrix3D
		{
			return _eulersMatrix;
		}
		
		/**
		 * Defines the global euler rotation applied to the orientation of the motion.
		 */
		public function get eulers():Vector3D
		{
			return _eulers;
		}
		
		public function set eulers(value:Vector3D):void
		{
			_eulers = value;
			_eulersMatrix.identity();
			_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
			_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
			_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
			//_eulersMatrix.transpose();
		}
		
		/**
		 * Creates a new <code>ParticleCircleNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 * @param    [optional] eulers          Defines the global euler rotation applied to the orientation of the motion.
		 */
		public function ParticleCircleNode(mode:uint, eulers:Vector3D = null)
		{
			//TODO: If do not need velocity, datalength can be reduced to 2
			super("ParticleCircleNode" + mode, mode, 3);
			
			_stateClass = ParticleCircleState;
			
			_eulers = eulers.clone() || new Vector3D();
			
			_eulersMatrix = new Matrix3D();
			_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
			_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
			_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			
			var circleAttribute:ShaderRegisterElement = animationRegisterCache.getFreeVertexAttribute();
			animationRegisterCache.setRegisterIndex(this, CIRCLE_INDEX, circleAttribute.index);
			
			var eulersMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, EULERS_INDEX, eulersMatrixRegister.index);
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.getFreeVertexConstant();
			
			var temp1:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(temp1,1);
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp1.regName, temp1.index);
			
			
			var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var cos:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "x");
			var sin:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "y");
			var degree:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "z");
			animationRegisterCache.removeVertexTempUsage(temp1);
			
			var code:String = "";
			code += "mul " + degree + "," + animationRegisterCache.vertexTime + "," + circleAttribute + ".y\n";
			code += "cos " + cos +"," + degree + "\n";
			code += "sin " + sin +"," + degree + "\n";
			code += "mul " + distance +".x," + cos +"," + circleAttribute + ".x\n";
			code += "mul " + distance +".y," + sin +"," + circleAttribute + ".x\n";
			code += "mov " + distance + ".wz" + animationRegisterCache.vertexZeroConst + "\n";
			code += "m44 " + distance + "," + distance + "," +eulersMatrixRegister + "\n";
			code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
			
			if (animationRegisterCache.needVelocity)
			{
				code += "neg " + distance + ".x," + sin + "\n";
				code += "mov " + distance + ".y," + cos + "\n";
				code += "mov " + distance + ".zw," + animationRegisterCache.vertexZeroConst + "\n";
				code += "m44 " + distance + "," + distance + "," + eulersMatrixRegister + "\n";
				code += "mul " + distance + "," + distance + "," + circleAttribute + ".z\n";
				code += "div " + distance + "," + distance + "," + circleAttribute + ".y\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + animationRegisterCache.velocityTarget + ".xyz," +distance + ".xyz\n";
			}
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			//Vector3D.x is radius, Vector3D.y is cycle speed, Vector3D.z is circumference
			var temp:Vector3D = param[CIRCLE_VECTOR3D];
			if (!temp)
				throw new Error("there is no " + CIRCLE_VECTOR3D + " in param!");
				
			_oneData[0] = temp.x;
			_oneData[1] = Math.PI * 2 / temp.y;
			_oneData[2] = temp.x * Math.PI * 2;
		}
	}
}