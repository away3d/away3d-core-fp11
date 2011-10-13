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
	public class FlickerLocal extends AllParticleAction
	{
		private var _startColor:ColorTransform;
		private var _endColor:ColorTransform;
		private var _cycle:Number;
		
		private var _hasMult:Boolean;
		private var _hasOffset:Boolean;
		
		private var startMultiplierConst:ShaderRegisterElement;
		private var deltaMultiplierConst:ShaderRegisterElement;
		private var startOffestConst:ShaderRegisterElement;
		private var deltaOffestConst:ShaderRegisterElement;
		private var cycleConst:ShaderRegisterElement;
		
		private var startMultiplier:Vector.<Number>;
		private var deltaMultiplier:Vector.<Number>;
		private var startOffest:Vector.<Number>;
		private var deltaOffest:Vector.<Number>;
		
		public function FlickerLocal(startColor:ColorTransform,endColor:ColorTransform,cycle:Number) 
		{
			_startColor = startColor;
			_endColor = endColor;
			_cycle = cycle;
			if (_startColor.alphaMultiplier != 1 || _startColor.blueMultiplier != 1 || _startColor.greenMultiplier != 1 || _startColor.redMultiplier != 1 ||
				_endColor.alphaMultiplier != 1 || _endColor.blueMultiplier != 1 || _endColor.greenMultiplier != 1 || _endColor.redMultiplier != 1)
				_hasMult = true;
			if (_startColor.alphaOffset != 0 || _startColor.blueOffset != 0 || _startColor.greenOffset != 0 || _startColor.redOffset != 0 ||
				_endColor.alphaOffset != 0 || _endColor.blueOffset != 0 || _endColor.greenOffset != 0 || _endColor.redOffset != 0)
				_hasOffset = true;
				
			startMultiplier = Vector.<Number>([_startColor.redMultiplier , _startColor.greenMultiplier , _startColor.blueMultiplier , _startColor.alphaMultiplier ]);
			deltaMultiplier = Vector.<Number>([(_endColor.redMultiplier - _startColor.redMultiplier) , (_endColor.greenMultiplier - _startColor.greenMultiplier) , (_endColor.blueMultiplier - _startColor.blueMultiplier) , (_endColor.alphaMultiplier - _startColor.alphaMultiplier)]);
			startOffest = Vector.<Number>([_startColor.redOffset / 256, _startColor.greenOffset / 256, _startColor.blueOffset / 256, _startColor.alphaOffset / 256]);
			deltaOffest = Vector.<Number>([(_endColor.greenOffset - _startColor.redOffset) / 256, (_endColor.greenOffset - _startColor.greenOffset) / 256, (_endColor.blueOffset - _startColor.blueOffset ) / 256, (_endColor.alphaOffset - _startColor.alphaOffset) / 256]);
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
				startOffestConst = shaderRegisterCache.getFreeFragmentConstant();
				deltaOffestConst = shaderRegisterCache.getFreeFragmentConstant();
			}
			cycleConst = shaderRegisterCache.getFreeFragmentConstant();
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeFragmentVectorTemp();
			shaderRegisterCache.addFragmentTempUsages(temp,1);
			var frc:ShaderRegisterElement = shaderRegisterCache.getFreeFragmentVectorTemp();
			shaderRegisterCache.removeFragmentTempUsage(temp);
			
			var code:String = "";
			
			code += "div " + frc.toString() + "," + _animation.fragmentTime.toString() + "," + cycleConst.toString() + ".w\n";
			code += "frc " + frc.toString() + "," + frc.toString() + "\n";
			code += "mul " + frc.toString() + "," + frc.toString() + "," + _animation.fragmentPiConst.toString() + "\n";
			code += "sin " + frc.toString() + "," + frc.toString() + "\n";
			
			if (_hasMult)
			{
				code += "mul " + temp.toString() + "," + deltaMultiplierConst.toString() + "," +  frc.toString()+ "\n";
				code += "add " + temp.toString() + "," + temp.toString() + "," + startMultiplierConst.toString() + "\n";
				code += "mul " + _animation.colorTarget.toString() +"," + temp.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			if (_hasOffset)
			{
				code += "mul " + temp.toString() + "," + deltaOffestConst.toString() +"," + frc.toString() + "\n";
				code += "add " + temp.toString() + "," + temp.toString() +"," + startOffestConst.toString() + "\n";
				code += "add " + _animation.colorTarget.toString() +"," +temp.toString() + "," + _animation.colorTarget.toString() + "\n";
			}
			return code;
		}
		
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, pass : MaterialPassBase, renderable : IRenderable) : void
		{
			
			var context : Context3D = stage3DProxy._context3D;
			if (_hasMult)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, startMultiplierConst.index, startMultiplier);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, deltaMultiplierConst.index, deltaMultiplier);
			}
			if (_hasOffset)
			{
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, startOffestConst.index, startOffest);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, deltaOffestConst.index, deltaOffest);
			}
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, cycleConst.index, Vector.<Number>([ _cycle, _cycle, _cycle, _cycle ]));
		}
		
	}

}