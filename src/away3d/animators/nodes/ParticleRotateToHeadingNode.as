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
	 * A particle animation node used to control the rotation of a particle to match its heading vector.
	 */
	public class ParticleRotateToHeadingNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const MATRIX_INDEX:int = 0;
		
		/**
		 * Creates a new <code>ParticleBillboardNode</code>
		 */
		public function ParticleRotateToHeadingNode()
		{
			super("ParticleRotateToHeading", ParticlePropertiesMode.GLOBAL, 0, 3);
			
			_stateClass = ParticleRotateToHeadingState;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;
			var code:String = "";
			var len:int = animationRegisterCache.rotationRegisters.length;
			var i:int;
			if (animationRegisterCache.hasBillboard) {
				var temp1:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(temp1, 1);
				var temp2:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(temp2, 1);
				var temp3:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				
				var rotationMatrixRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, MATRIX_INDEX, rotationMatrixRegister.index);
				animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.getFreeVertexConstant();
				
				animationRegisterCache.removeVertexTempUsage(temp1);
				animationRegisterCache.removeVertexTempUsage(temp2);
				
				//process the velocity
				code += "m33 " + temp1 + ".xyz," + animationRegisterCache.velocityTarget + ".xyz," + rotationMatrixRegister + "\n";
				
				code += "mov " + temp3 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp3 + ".xy," + temp1 + ".xy\n";
				code += "nrm " + temp3 + ".xyz," + temp3 + ".xyz\n";
				
				//temp3.x=cos,temp3.y=sin
				//only process z axis
				code += "mov " + temp2 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp2 + ".x," + temp3 + ".y\n";
				code += "mov " + temp2 + ".y," + temp3 + ".x\n";
				code += "mov " + temp1 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp1 + ".x," + temp3 + ".x\n";
				code += "neg " + temp1 + ".y," + temp3 + ".y\n";
				code += "mov " + temp3 + "," + animationRegisterCache.vertexZeroConst + "\n";
				code += "mov " + temp3 + ".z," + animationRegisterCache.vertexOneConst + "\n";
				code += "m33 " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + temp1 + "\n";
				for (i = 0; i < len; i++)
					code += "m33 " + animationRegisterCache.rotationRegisters[i] + ".xyz," + animationRegisterCache.rotationRegisters[i] + "," + temp1 + "\n";
			} else {
				var nrmVel:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(nrmVel, 1);
				
				var xAxis:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(xAxis, 1);
				
				var R:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(R, 1);
				var R_rev:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				var cos:ShaderRegisterElement = new ShaderRegisterElement(R.regName, R.index, 3);
				var sin:ShaderRegisterElement = new ShaderRegisterElement(R_rev.regName, R_rev.index, 3);
				var cos2:ShaderRegisterElement = new ShaderRegisterElement(nrmVel.regName, nrmVel.index, 3);
				var tempSingle:ShaderRegisterElement = sin;
				
				animationRegisterCache.removeVertexTempUsage(nrmVel);
				animationRegisterCache.removeVertexTempUsage(xAxis);
				animationRegisterCache.removeVertexTempUsage(R);
				
				code += "mov " + xAxis + ".x," + animationRegisterCache.vertexOneConst + "\n";
				code += "mov " + xAxis + ".yz," + animationRegisterCache.vertexZeroConst + "\n";
				
				code += "nrm " + nrmVel + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
				code += "dp3 " + cos2 + "," + nrmVel + ".xyz," + xAxis + ".xyz\n";
				code += "crs " + nrmVel + ".xyz," + xAxis + ".xyz," + nrmVel + ".xyz\n";
				code += "nrm " + nrmVel + ".xyz," + nrmVel + ".xyz\n";
				//use R as temp to judge if nrm is (0,0,0).
				//if nrm is (0,0,0) ,change it to (0,0,1).
				code += "dp3 " + R + ".x," + nrmVel + ".xyz," + nrmVel + ".xyz\n";
				code += "sge " + R + ".x," + animationRegisterCache.vertexZeroConst + "," + R + ".x\n";
				code += "add " + nrmVel + ".z," + R + ".x," + nrmVel + ".z\n";
				
				code += "add " + tempSingle + "," + cos2 + "," + animationRegisterCache.vertexOneConst + "\n";
				code += "div " + tempSingle + "," + tempSingle + "," + animationRegisterCache.vertexTwoConst + "\n";
				code += "sqt " + cos + "," + tempSingle + "\n";
				
				code += "sub " + tempSingle + "," + animationRegisterCache.vertexOneConst + "," + cos2 + "\n";
				code += "div " + tempSingle + "," + tempSingle + "," + animationRegisterCache.vertexTwoConst + "\n";
				code += "sqt " + sin + "," + tempSingle + "\n";
				
				code += "mul " + R + ".xyz," + sin + "," + nrmVel + ".xyz\n";
				
				//use cos as R.w
				
				code += "mul " + R_rev + ".xyz," + sin + "," + nrmVel + ".xyz\n";
				code += "neg " + R_rev + ".xyz," + R_rev + ".xyz\n";
				
				//use cos as R_rev.w
				
				//nrmVel and xAxis are used as temp register
				code += "crs " + nrmVel + ".xyz," + R + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz\n";
				
				//use cos as R.w
				code += "mul " + xAxis + ".xyz," + cos + "," + animationRegisterCache.scaleAndRotateTarget + ".xyz\n";
				code += "add " + nrmVel + ".xyz," + nrmVel + ".xyz," + xAxis + ".xyz\n";
				code += "dp3 " + xAxis + ".w," + R + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz\n";
				code += "neg " + nrmVel + ".w," + xAxis + ".w\n";
				
				code += "crs " + R + ".xyz," + nrmVel + ".xyz," + R_rev + ".xyz\n";
				//code += "mul " + xAxis + ".xyzw," + nrmVel + ".xyzw," +R_rev + ".w\n";
				code += "mul " + xAxis + ".xyzw," + nrmVel + ".xyzw," + cos + "\n";
				code += "add " + R + ".xyz," + R + ".xyz," + xAxis + ".xyz\n";
				code += "mul " + xAxis + ".xyz," + nrmVel + ".w," + R_rev + ".xyz\n";
				
				code += "add " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + R + ".xyz," + xAxis + ".xyz\n";
				
				for (i = 0; i < len; i++) {
					//just repeat the calculate above
					//because of the limited registers, no need to optimise
					code += "mov " + xAxis + ".x," + animationRegisterCache.vertexOneConst + "\n";
					code += "mov " + xAxis + ".yz," + animationRegisterCache.vertexZeroConst + "\n";
					code += "nrm " + nrmVel + ".xyz," + animationRegisterCache.velocityTarget + ".xyz\n";
					code += "dp3 " + cos2 + "," + nrmVel + ".xyz," + xAxis + ".xyz\n";
					code += "crs " + nrmVel + ".xyz," + xAxis + ".xyz," + nrmVel + ".xyz\n";
					code += "nrm " + nrmVel + ".xyz," + nrmVel + ".xyz\n";
					code += "dp3 " + R + ".x," + nrmVel + ".xyz," + nrmVel + ".xyz\n";
					code += "sge " + R + ".x," + animationRegisterCache.vertexZeroConst + "," + R + ".x\n";
					code += "add " + nrmVel + ".z," + R + ".x," + nrmVel + ".z\n";
					code += "add " + tempSingle + "," + cos2 + "," + animationRegisterCache.vertexOneConst + "\n";
					code += "div " + tempSingle + "," + tempSingle + "," + animationRegisterCache.vertexTwoConst + "\n";
					code += "sqt " + cos + "," + tempSingle + "\n";
					code += "sub " + tempSingle + "," + animationRegisterCache.vertexOneConst + "," + cos2 + "\n";
					code += "div " + tempSingle + "," + tempSingle + "," + animationRegisterCache.vertexTwoConst + "\n";
					code += "sqt " + sin + "," + tempSingle + "\n";
					code += "mul " + R + ".xyz," + sin + "," + nrmVel + ".xyz\n";
					code += "mul " + R_rev + ".xyz," + sin + "," + nrmVel + ".xyz\n";
					code += "neg " + R_rev + ".xyz," + R_rev + ".xyz\n";
					code += "crs " + nrmVel + ".xyz," + R + ".xyz," + animationRegisterCache.rotationRegisters[i] + ".xyz\n";
					code += "mul " + xAxis + ".xyz," + cos + "," + animationRegisterCache.rotationRegisters[i] + ".xyz\n";
					code += "add " + nrmVel + ".xyz," + nrmVel + ".xyz," + xAxis + ".xyz\n";
					code += "dp3 " + xAxis + ".w," + R + ".xyz," + animationRegisterCache.rotationRegisters[i] + ".xyz\n";
					code += "neg " + nrmVel + ".w," + xAxis + ".w\n";
					code += "crs " + R + ".xyz," + nrmVel + ".xyz," + R_rev + ".xyz\n";
					code += "mul " + xAxis + ".xyzw," + nrmVel + ".xyzw," + cos + "\n";
					code += "add " + R + ".xyz," + R + ".xyz," + xAxis + ".xyz\n";
					code += "mul " + xAxis + ".xyz," + nrmVel + ".w," + R_rev + ".xyz\n";
					code += "add " + animationRegisterCache.rotationRegisters[i] + ".xyz," + R + ".xyz," + xAxis + ".xyz\n";
				}
				
			}
			return code;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getAnimationState(animator:IAnimator):ParticleRotateToHeadingState
		{
			return animator.getAnimationState(this) as ParticleRotateToHeadingState;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			particleAnimationSet.needVelocity = true;
		}
	}
}
