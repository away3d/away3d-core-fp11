package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticleParameter;
	import away3d.animators.states.ParticleOrbitState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	/**
	 * ...
	 */
	public class ParticleOrbitNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const ORBIT_INDEX:uint = 0;
		
		/** @private */
		arcane static const EULERS_INDEX:uint = 1;
		
		/** @private */
		arcane var _usesEulers:Boolean;
		
		/** @private */
		arcane var _usesCycle:Boolean;
		
		/** @private */
		arcane var _usesPhase:Boolean;
		
		/** @private */
		arcane var _orbitData:Vector3D;
		
		/** @private */
		arcane var _eulersMatrix:Matrix3D;
		
		private var _radius:Number;
		private var _cycleSpeed:Number;
		private var _cyclePhase:Number;
		private var _eulers:Vector3D;
				
		/**
		 * Used to set the orbit node into local property mode.
		 */
		public static const LOCAL:uint = 0;
				
		/**
		 * Used to set the orbit node into global property mode.
		 */
		public static const GLOBAL:uint = 1;
		
		/**
		 * Reference for orbit node properties on a single particle (when in local property mode).
		 * Expects a <code>Vector3D</code> object representing the radius (x), cycle speed (y) and cycle phase (z) of the motion on the particle.
		 */
		public static const ORBIT_VECTOR3D:String = "OrbitVector3D";
		
		/**
		 * Defines the radius of the orbit, when in global mode. Defaults to 100.
		 */
		public function get radius():Number
		{
			return _radius;
		}
		public function set radius(value:Number):void
		{
			_radius = value;
			
			updateOrbitData();
		}
		
		/**
		 * Defines the cycle speed of the node in revolutions per second, when in global mode. Defaults to 1.
		 */
		public function get cycleSpeed():Number
		{
			return _cycleSpeed;
		}
		public function set cycleSpeed(value:Number):void
		{
			_cycleSpeed = value;
			
			updateOrbitData();
		}
		
		/**
		 * Defines the cycle phase of the node in degrees, when in global mode. Defaults to zero.
		 */
		public function get cyclePhase():Number
		{
			return _cyclePhase;
		}
		public function set cyclePhase(value:Number):void
		{
			_cyclePhase = value;
			
			updateOrbitData();
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
			
			updateOrbitData();
			
		}
		
		/**
		 * Creates a new <code>ParticleCircleNode</code>
		 *
		 * @param               mode            Defines whether the mode of operation defaults to acting on local properties of a particle or global properties of the node.
		 * @param    [optional] eulers          Defines the global euler rotation applied to the orientation of the motion.
		 */
		public function ParticleOrbitNode(mode:uint, usesEulers:Boolean = true, usesCycle:Boolean = false, usesPhase:Boolean = false, radius:Number = 100, cycleSpeed:Number = 1, cyclePhase:Number = 0, eulers:Vector3D = null)
		{
			var len:int = 3;
			if (usesPhase)
				len++;
			super("ParticleOrbitNode" + mode, mode, len);
			
			_stateClass = ParticleOrbitState;
			
			_usesEulers = usesEulers;
			_usesCycle = usesCycle;
			_usesPhase = usesPhase;
			
			_radius = radius;
			_cycleSpeed = cycleSpeed;
			_cyclePhase = cyclePhase;
			_eulers = eulers || new Vector3D();
			
			updateOrbitData();
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache) : String
		{
			
			var orbitRegister:ShaderRegisterElement = (_mode == LOCAL)? animationRegisterCache.getFreeVertexAttribute() : animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, ORBIT_INDEX, orbitRegister.index);
			
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
			
			if (_usesCycle) {
				code += "mul " + degree + "," + animationRegisterCache.vertexTime + "," + orbitRegister + ".y\n";
				
				if (_usesPhase)
					code += "add " + degree + "," + degree + "," + orbitRegister + ".w\n";
			} else {
				code += "mul " + degree + "," + animationRegisterCache.vertexLife + "," + orbitRegister + ".y\n";
			}
			
			code += "cos " + cos +"," + degree + "\n";
			code += "sin " + sin +"," + degree + "\n";
			code += "mul " + distance +".x," + cos +"," + orbitRegister + ".x\n";
			code += "mul " + distance +".y," + sin +"," + orbitRegister + ".x\n";
			code += "mov " + distance + ".wz" + animationRegisterCache.vertexZeroConst + "\n";
			code += "m44 " + distance + "," + distance + "," +eulersMatrixRegister + "\n";
			code += "add " + animationRegisterCache.positionTarget + ".xyz," + distance + ".xyz," + animationRegisterCache.positionTarget + ".xyz\n";
			
			if (animationRegisterCache.needVelocity)
			{
				code += "neg " + distance + ".x," + sin + "\n";
				code += "mov " + distance + ".y," + cos + "\n";
				code += "mov " + distance + ".zw," + animationRegisterCache.vertexZeroConst + "\n";
				code += "m44 " + distance + "," + distance + "," + eulersMatrixRegister + "\n";
				code += "mul " + distance + "," + distance + "," + orbitRegister + ".z\n";
				code += "div " + distance + "," + distance + "," + orbitRegister + ".y\n";
				if (!_usesCycle)
					code += "div " + distance + "," + distance + "," + animationRegisterCache.vertexLife + "\n";
				code += "add " + animationRegisterCache.velocityTarget + ".xyz," + animationRegisterCache.velocityTarget + ".xyz," +distance + ".xyz\n";
			}
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function generatePropertyOfOneParticle(param:ParticleParameter):void
		{
			//Vector3D.x is radius, Vector3D.y is cycle speed, Vector3D.z is phase
			var orbit:Vector3D = param[ORBIT_VECTOR3D];
			if (!orbit)
				throw new Error("there is no " + ORBIT_VECTOR3D + " in param!");
				
			_oneData[0] = orbit.x;
			_oneData[1] = Math.PI * 2 / (!_usesCycle? 1 : orbit.y);
			_oneData[2] = orbit.x * Math.PI * 2;
			if (_usesPhase)
				_oneData[3] = orbit.z * Math.PI / 180;
		}
		
		private function updateOrbitData():void
		{
			if (_usesEulers) {
				_eulersMatrix = new Matrix3D();
				_eulersMatrix.appendRotation(_eulers.x, Vector3D.X_AXIS);
				_eulersMatrix.appendRotation(_eulers.y, Vector3D.Y_AXIS);
				_eulersMatrix.appendRotation(_eulers.z, Vector3D.Z_AXIS);
			}
			
			_orbitData = new Vector3D(_radius, Math.PI * 2 / _cycleSpeed, _radius * Math.PI * 2, _cyclePhase * Math.PI / 180);
		}
	}
}