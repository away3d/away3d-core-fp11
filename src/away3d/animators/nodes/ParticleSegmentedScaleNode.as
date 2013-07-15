package away3d.animators.nodes
{
	import away3d.arcane;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.animators.data.ParticlePropertiesMode;
	import away3d.animators.states.ParticleSegmentedScaleState;
	import away3d.materials.compilation.ShaderRegisterElement;
	import away3d.materials.passes.MaterialPassBase;
	import flash.geom.Vector3D;
	
	use namespace arcane;
	
	public class ParticleSegmentedScaleNode extends ParticleNodeBase
	{
		/** @private */
		arcane static const START_INDEX:uint = 0;
		
		/** @private */
		arcane var _startScale:Vector3D;
		/** @private */
		arcane var _endScale:Vector3D;
		/** @private */
		arcane var _numSegmentPoint:int;
		/** @private */
		arcane var _segmentScales:Vector.<Vector3D>;
		
		/**
		 *
		 * @param	numSegmentPoint
		 * @param	startScale
		 * @param	endScale
		 * @param	segmentScales Vector.<Vector3D>. the x,y,z present the scaleX,scaleY,scaleX, and w present the life
		 */
		public function ParticleSegmentedScaleNode(numSegmentPoint:int, startScale:Vector3D, endScale:Vector3D, segmentScales:Vector.<Vector3D>)
		{
			_stateClass = ParticleSegmentedScaleState;
			
			//because of the stage3d register limitation, it only support the global mode
			super("ParticleSegmentedScale", ParticlePropertiesMode.GLOBAL, 0, 3);
			
			_numSegmentPoint = numSegmentPoint;
			_startScale = startScale;
			_endScale = endScale;
			_segmentScales = segmentScales;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function getAGALVertexCode(pass:MaterialPassBase, animationRegisterCache:AnimationRegisterCache):String
		{
			pass = pass;
			
			var code:String = "";
			
			var accScale:ShaderRegisterElement;
			accScale = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(accScale, 1);
			
			var tempScale:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			animationRegisterCache.addVertexTempUsages(tempScale, 1);
			
			var temp:ShaderRegisterElement = animationRegisterCache.getFreeVertexVectorTemp();
			var accTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 0);
			var tempTime:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, 1);
			
			animationRegisterCache.removeVertexTempUsage(accScale);
			animationRegisterCache.removeVertexTempUsage(tempScale);
			
			
			var i:int;
			
			var startValue:ShaderRegisterElement;
			var deltaValues:Vector.<ShaderRegisterElement>;
			
			
			startValue = animationRegisterCache.getFreeVertexConstant();
			animationRegisterCache.setRegisterIndex(this, START_INDEX, startValue.index);
			deltaValues = new Vector.<ShaderRegisterElement>;
			for (i = 0; i < _numSegmentPoint + 1; i++)
			{
				deltaValues.push(animationRegisterCache.getFreeVertexConstant());
			}
			
			
			code += "mov " + accScale + "," + startValue + "\n";
			
			for (i = 0; i < _numSegmentPoint; i++)
			{
				switch (i)
				{
					case 0:
						code += "min " + tempTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[i] + ".w\n";
						break;
					case 1:
						code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[i - 1] + ".w\n";
						code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
						code += "min " + tempTime + "," + tempTime + "," + deltaValues[i] + ".w\n";
						break;
					default:
						code += "sub " + accTime + "," + accTime + "," + deltaValues[i - 1] + ".w\n";
						code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
						code += "min " + tempTime + "," + tempTime + "," + deltaValues[i] + ".w\n";
						break;
				}
				code += "mul " + tempScale + "," + tempTime + "," + deltaValues[i] + "\n";
				code += "add " + accScale + "," + accScale + "," + tempScale + "\n";
			}
			
			//for the last segment:
			if (_numSegmentPoint == 0)
				tempTime = animationRegisterCache.vertexLife;
			else
			{
				switch (_numSegmentPoint)
				{
					case 1:
						code += "sub " + accTime + "," + animationRegisterCache.vertexLife + "," + deltaValues[_numSegmentPoint - 1] + ".w\n";
						break;
					default:
						code += "sub " + accTime + "," + accTime + "," + deltaValues[_numSegmentPoint - 1] + ".w\n";
						break;
				}
				code += "max " + tempTime + "," + accTime + "," + animationRegisterCache.vertexZeroConst + "\n";
			}
			
			code += "mul " + tempScale + "," + tempTime + "," + deltaValues[_numSegmentPoint] + "\n";
			code += "add " + accScale + "," + accScale + "," + tempScale + "\n";
			code += "mul " + animationRegisterCache.scaleAndRotateTarget + ".xyz," + animationRegisterCache.scaleAndRotateTarget + ".xyz," + accScale + ".xyz\n";
			
			return code;
		}
	
	}

}
