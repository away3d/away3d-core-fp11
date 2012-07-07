package a3dparticle.animators.actions.color 
{
	import a3dparticle.animators.actions.AllParticleAction;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.utils.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.ColorTransform;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class FlickerGlobal extends AllParticleAction
	{
		private var _minColor:ColorTransform;
		private var _maxColor:ColorTransform;

		private var _hasPhaseAngle:Boolean;
		
		private var _hasMult:Boolean;
		private var _hasOffset:Boolean;
		
		private var startMultiplierConst:ShaderRegisterElement;
		private var deltaMultiplierConst:ShaderRegisterElement;
		private var startOffsetConst:ShaderRegisterElement;
		private var deltaOffsetConst:ShaderRegisterElement;
		private var cycleConst:ShaderRegisterElement;
		
		private var startMultiplier:Vector.<Number>;
		private var deltaMultiplier:Vector.<Number>;
		private var startOffset:Vector.<Number>;
		private var deltaOffset:Vector.<Number>;
		
		private var cycleData:Vector.<Number>;
		
		public function FlickerGlobal(minColor:ColorTransform,maxColor:ColorTransform,cycle:Number,phaseAngle:Number=0) 
		{
			_minColor = minColor;
			_maxColor = maxColor;
			
			if (_minColor.alphaMultiplier != 1 || _minColor.blueMultiplier != 1 || _minColor.greenMultiplier != 1 || _minColor.redMultiplier != 1 ||
				_maxColor.alphaMultiplier != 1 || _maxColor.blueMultiplier != 1 || _maxColor.greenMultiplier != 1 || _maxColor.redMultiplier != 1)
				_hasMult = true;
			if (_minColor.alphaOffset != 0 || _minColor.blueOffset != 0 || _minColor.greenOffset != 0 || _minColor.redOffset != 0 ||
				_maxColor.alphaOffset != 0 || _maxColor.blueOffset != 0 || _maxColor.greenOffset != 0 || _maxColor.redOffset != 0)
				_hasOffset = true;
				
			startMultiplier = Vector.<Number>([(_minColor.redMultiplier + _maxColor.redMultiplier) / 2 , (_minColor.greenMultiplier + _maxColor.greenMultiplier) / 2 , (_minColor.blueMultiplier + _maxColor.blueMultiplier) / 2 , (_minColor.alphaMultiplier + _maxColor.alphaMultiplier) / 2 ]);
			deltaMultiplier = Vector.<Number>([(_maxColor.redMultiplier - _minColor.redMultiplier) / 2 , (_maxColor.greenMultiplier - _minColor.greenMultiplier) / 2 , (_maxColor.blueMultiplier - _minColor.blueMultiplier) / 2 , (_maxColor.alphaMultiplier - _minColor.alphaMultiplier) / 2]);
			startOffset = Vector.<Number>([(_minColor.redOffset + _maxColor.redOffset) / (256 * 2), (_minColor.greenOffset + _maxColor.greenOffset) / (256 * 2), (_minColor.blueOffset + _maxColor.blueOffset) / (256 * 2), (_minColor.alphaOffset + _maxColor.alphaOffset) / (256 * 2)]);
			deltaOffset = Vector.<Number>([(_maxColor.redOffset - _minColor.redOffset) / (256 * 2), (_maxColor.greenOffset - _minColor.greenOffset) / (256 * 2), (_maxColor.blueOffset - _minColor.blueOffset) / (256 * 2), (_maxColor.alphaOffset - _minColor.alphaOffset) / (256 * 2)]);
			
			if (phaseAngle != 0) _hasPhaseAngle = true;
			cycleData = Vector.<Number>([Math.PI * 2 / cycle, phaseAngle * Math.PI / 180, 0, 0]);
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			if (_hasMult)
			{
				startMultiplierConst = shaderRegisterCache.getFreeFragmentConstant();
				deltaMultiplierConst = shaderRegisterCache.getFreeFragmentConstant();
			}
			if (_hasOffset)
			{
				startOffsetConst = shaderRegisterCache.getFreeFragmentConstant();
				deltaOffsetConst = shaderRegisterCache.getFreeFragmentConstant();
			}
			cycleConst = shaderRegisterCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeFragmentVectorTemp();
			shaderRegisterCache.addFragmentTempUsages(temp,1);
			var sin:ShaderRegisterElement = shaderRegisterCache.getFreeFragmentSingleTemp();
			shaderRegisterCache.removeFragmentTempUsage(temp);
			
			var code:String = "";
			
			code += "mul " + sin.toString() + "," + _animation.fragmentTime.toString() + "," + cycleConst.toString() + ".x\n";
			if (_hasPhaseAngle)
			{
				code += "add " + sin.toString() + "," + sin.toString() + "," + cycleConst.toString() + ".y\n";
			}
			code += "sin " + sin.toString() + "," + sin.toString() + "\n";
			
			if (_hasMult)
			{
				code += "mul " + temp.toString() + "," + deltaMultiplierConst.toString() + "," +  sin.toString()+ "\n";
				code += "add " + temp.toString() + "," + temp.toString() + "," + startMultiplierConst.toString() + "\n";
				code += "mul " + _animation.colorTarget.toString() +"," + temp.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			if (_hasOffset)
			{
				code += "mul " + temp.toString() + "," + deltaOffsetConst.toString() +"," + sin.toString() + "\n";
				code += "add " + temp.toString() + "," + temp.toString() +"," + startOffsetConst.toString() + "\n";
				code += "add " + _animation.colorTarget.toString() +"," +temp.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			return code;
		}
		
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			
			var context : Context3D = stage3DProxy._context3D;
			if (_hasMult)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, startMultiplierConst.index, startMultiplier);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, deltaMultiplierConst.index, deltaMultiplier);
			}
			if (_hasOffset)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, startOffsetConst.index, startOffset);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, deltaOffsetConst.index, deltaOffset);
			}
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, cycleConst.index, cycleData);
		}
		
	}

}