package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ColorSegmentPoint;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.ParticleAnimationSet;
	import away3d.animators.states.ParticleSegmentedColorState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	
	import flash.geom.ColorTransform;
	
	use namespace arcane;
	
	public class ParticleSegmentedColorNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const START_MULTIPLIER_INDEX:uint = 0;
		
		/** @private */
		arcane static const START_OFFSET_INDEX:uint = 1;
		
		/** @private */
		arcane static const TIME_DATA_INDEX:uint = 2;
		
		/** @private */
		arcane var _usesMultiplier:Boolean;
		/** @private */
		arcane var _usesOffset:Boolean;
		/** @private */
		arcane var _startColor:ColorTransform;
		/** @private */
		arcane var _endColor:ColorTransform;
		/** @private */
		arcane var _numSegmentPoint:int;
		/** @private */
		arcane var _segmentPoints:Vector.<ColorSegmentPoint>;
		
		public function ParticleSegmentedColorNode(usesMultiplier:Boolean, usesOffset:Boolean, numSegmentPoint:int, startColor:ColorTransform, endColor:ColorTransform, segmentPoints:Vector.<ColorSegmentPoint>)
		{
			_stateClass = ParticleSegmentedColorState;
			
			//because of the stage3d register limitation, it only support the global mode
			super("ParticleSegmentedColor", ParticlePropertiesMode.GLOBAL, 0, ParticleAnimationSet.COLOR_PRIORITY);
			
			if (numSegmentPoint > 4)
				throw(new Error("the numSegmentPoint must be less or equal 4"));
			_usesMultiplier = usesMultiplier;
			_usesOffset = usesOffset;
			_numSegmentPoint = numSegmentPoint;
			_startColor = startColor;
			_endColor = endColor;
			_segmentPoints = segmentPoints;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function processAnimationSetting(particleAnimationSet:ParticleAnimationSet):void
		{
			if (_usesMultiplier)
				particleAnimationSet.hasColorMulNode = true;
			if (_usesOffset)
				particleAnimationSet.hasColorAddNode = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;
			
			var code:String = "";
			if (animationRegisterCache.needFragmentAnimation) {
				var accMultiplierColor:ShaderRegisterElement;
				//var accOffsetColor:ShaderRegisterElement;
				if (_usesMultiplier) {
					accMultiplierColor = animationRegisterCache.getFreeVertexVectorTemp();
					animationRegisterCache.addVertexTempUsages(accMultiplierColor, 1);
				}
				
				var tempColor:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				animationRegisterCache.addVertexTempUsages(tempColor, 1);
				
				var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
				var accTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
				var tempTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
				
				if (_usesMultiplier)
					animationRegisterCache.removeVertexTempUsage(accMultiplierColor);
				
				animationRegisterCache.removeVertexTempUsage(tempColor);
				
				//for saving all the life values (at most 4)
				var lifeTimeRegister:ShaderRegisterElement = animationRegisterCache.getFreeVertexConstant();
				animationRegisterCache.setRegisterIndex(this, TIME_DATA_INDEX, lifeTimeRegister.index);
				
				var i:int;
				
				var startMulValue:ShaderRegisterElement;
				var deltaMulValues:Vector.<ShaderRegisterElement>;
				if (_usesMultiplier) {
					startMulValue = animationRegisterCache.getFreeVertexConstant();
					animationRegisterCache.setRegisterIndex(this, START_MULTIPLIER_INDEX, startMulValue.index);
					deltaMulValues = new Vector.<ShaderRegisterElement>;
					for (i = 0; i < _numSegmentPoint + 1; i++)
						deltaMulValues.push(animationRegisterCache.getFreeVertexConstant());
				}
				
				var startOffsetValue:ShaderRegisterElement;
				var deltaOffsetValues:Vector.<ShaderRegisterElement>;
				if (_usesOffset) {
					startOffsetValue = animationRegisterCache.getFreeVertexConstant();
					animationRegisterCache.setRegisterIndex(this, START_OFFSET_INDEX, startOffsetValue.index);
					deltaOffsetValues = new Vector.<ShaderRegisterElement>;
					for (i = 0; i < _numSegmentPoint + 1; i++)
						deltaOffsetValues.push(animationRegisterCache.getFreeVertexConstant());
				}
				
				if (_usesMultiplier)
					code += "mov " + accMultiplierColor + "," + startMulValue + "\n";
				if (_usesOffset)
					code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + startOffsetValue + "\n";
				
				for (i = 0; i < _numSegmentPoint; i++) {
					switch (i) {
						case 0:
							code += "min " + tempTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
							break;
						case 1:
							code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
							code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
							code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".y\n";
							break;
						case 2:
							code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".y\n";
							code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
							code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".z\n";
							break;
						case 3:
							code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".z\n";
							code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
							code += "min " + tempTime + "," + tempTime + "," + lifeTimeRegister + ".w\n";
							break;
					}
					if (_usesMultiplier) {
						code += "mul " + tempColor + "," + tempTime + "," + deltaMulValues[i] + "\n";
						code += "add " + accMultiplierColor + "," + accMultiplierColor + "," + tempColor + "\n";
					}
					if (_usesOffset) {
						code += "mul " + tempColor + "," + tempTime + "," + deltaOffsetValues[i] + "\n";
						code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + tempColor + "\n";
					}
				}
				
				//for the last segment:
				if (_numSegmentPoint == 0)
					tempTime = animationRegisterCache.vertexLife;
				else {
					switch (_numSegmentPoint) {
						case 1:
							code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + lifeTimeRegister + ".x\n";
							break;
						case 2:
							code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".y\n";
							break;
						case 3:
							code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".z\n";
							break;
						case 4:
							code += "sub " + accTime + "," + accTime + "," + lifeTimeRegister + ".w\n";
							break;
					}
					code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
				}
				if (_usesMultiplier) {
					code += "mul " + tempColor + "," + tempTime + "," + deltaMulValues[_numSegmentPoint] + "\n";
					code += "add " + accMultiplierColor + "," + accMultiplierColor + "," + tempColor + "\n";
					code += "mul " + animationRegisterCache.colorMulTarget + "," + animationRegisterCache.colorMulTarget + "," + accMultiplierColor + "\n";
				}
				if (_usesOffset) {
					code += "mul " + tempColor + "," + tempTime + "," + deltaOffsetValues[_numSegmentPoint] + "\n";
					code += "add " + animationRegisterCache.colorAddTarget + "," + animationRegisterCache.colorAddTarget + "," + tempColor + "\n";
				}
				
			}
			return code;
		}
	
	}

}
