package a3dparticle.animators
{
	import a3dparticle.animators.actions.ActionBase;
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.animators.actions.TimeAction;
	import a3dparticle.core.SimpleParticlePass;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.animators.IAnimationSet;
	import away3d.animators.nodes.AnimationNodeBase;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.utils.Dictionary;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class ParticleAnimation implements IAnimationSet
	{
		public static const POST_PRIORITY:int = 9;
		
		private static const VERTEX_CONST:Vector.<Number> = Vector.<Number>([0, 1, 2, 0]);
		private static const FRAGMENT_CONST:Vector.<Number> = Vector.<Number>([0, 1, 1 / 255, 0]);
		
		private var _hasGen:Boolean;
		
		private var _AGALVertexCode:String;
		private var _AGALFragmentCode:String;
		
		private var registersManagers:Dictionary = new Dictionary(true);
		
		public var animationRegistersManager:AnimationRegistersManager;
		
		private var _particleActions:Vector.<ActionBase> = new Vector.<ActionBase>();
		
		private var _perActions:Vector.<PerParticleAction> = new Vector.<PerParticleAction>();
		
		//dependent and global action
		private var timeAction:TimeAction;
		
		//set if it need to share velocity in other actions
		public var needVelocity:Boolean;
		
		public var needVelocityInFragment:Boolean;
		
		public var needCameraPosition:Boolean;
		
		public var needUV:Boolean;
		public var hasUVAction:Boolean;
		
		
		
		
		//rendering camera
		public var camera:Camera3D;
		
		public function ParticleAnimation()
		{
			super();
			
			timeAction = new TimeAction();
			timeAction.animation = this;
			addAction(timeAction);
			
		}
		
		public function get hasGen():Boolean
		{
			return _hasGen;
		}
		
		public function startGen():void
		{

		}
		
		public function finishGen():void
		{
			_hasGen = true;
		}
		
		public function set startTimeFun(fun:Function):void
		{
			timeAction.startTimeFun = fun;
		}
		
		public function set hasDuringTime(value:Boolean):void
		{
			timeAction.hasDuringTime = value;
		}
		
		public function set hasSleepTime(value:Boolean):void
		{
			timeAction.hasSleepTime = value;
		}
		
		public function set duringTimeFun(fun:Function):void
		{
			timeAction.duringTimeFun = fun;
		}
		
		public function set sleepTimeFun(fun:Function):void
		{
			timeAction.loop = true;
			timeAction.sleepTimeFun = fun;
		}
		
		public function set loop(value:Boolean):void
		{
			timeAction.loop = value;
		}
		
		public function addAction(action:ActionBase):void
		{
			var i:int;
			
			if (action is PerParticleAction)
				_perActions.push(action);
			
			for (i = _particleActions.length - 1; i >= 0; i--)
			{
				if (_particleActions[i].priority <= action.priority)
				{
					break;
				}
			}
			_particleActions.splice(i + 1, 0, action);
			action.animation = this;
		}
		
		public function genOne(param:ParticleParam):void
		{
			var len:int = _perActions.length;
			for (var i:int = 0; i < len; i++)
			{
				_perActions[i].genOne(param);
			}
		}
		
		public function distributeOne(index:uint, verticeIndex:uint, subContainer:SubContainer):void
		{
			var len:int = _perActions.length;
			for (var i:int = 0; i < len; i++)
			{
				_perActions[i].distributeOne(index, verticeIndex, subContainer);
			}
		}
		
		public function activate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			animationRegistersManager = registersManagers[pass];
			
			//set some const
			var context : Context3D = stage3DProxy._context3D;
			
			//set vertexZeroConst,vertexOneConst,vertexTwoConst
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, animationRegistersManager.vertexZeroConst.index, VERTEX_CONST, 1);
			//set fragmentZeroConst,fragmentOneConst
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, animationRegistersManager.fragmentZeroConst.index, FRAGMENT_CONST, 1);
		}
		
		public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var action:ActionBase;
			for each(action in _particleActions)
			{
				action.setRenderState(stage3DProxy,renderable);
			}
		}
		
		
		private function reset(pass:MaterialPassBase, sourceRegisters : Array, targetRegisters : Array):void
		{
			animationRegistersManager = registersManagers[pass] ||= new AnimationRegistersManager();
			var shaderRegisterCache:ShaderRegisterCache = animationRegistersManager.shaderRegisterCache;
			shaderRegisterCache.vertexConstantOffset = pass.numUsedVertexConstants;
			shaderRegisterCache.vertexAttributesOffset = pass.numUsedStreams;
			shaderRegisterCache.varyingsOffset = pass.numUsedVaryings;
			shaderRegisterCache.fragmentConstantOffset = pass.numUsedFragmentConstants;
			shaderRegisterCache.reset();
			animationRegistersManager.needCameraPosition = needCameraPosition;
			animationRegistersManager.needUV = needUV;
			animationRegistersManager.needVelocity = needVelocity;
			animationRegistersManager.needFragmentAnimation = pass.needFragmentAnimation;
			animationRegistersManager.reset();
		}

		
		public function getAGALVertexCode(pass : MaterialPassBase, sourceRegisters : Array, targetRegisters : Array) : String
		{
			reset(pass, sourceRegisters, targetRegisters);
			_AGALVertexCode = "";
			if (needVelocity)
			{
				_AGALVertexCode += "mov " + animationRegistersManager.velocityTarget.toString() + "," + animationRegistersManager.vertexZeroConst.toString() + "\n";
			}
			
			_AGALVertexCode += "mov " + animationRegistersManager.varyTime.toString() + ".zw," + animationRegistersManager.vertexZeroConst.toString() + "\n";
			_AGALVertexCode += "mov " + animationRegistersManager.offsetTarget.toString() + "," + animationRegistersManager.vertexZeroConst.toString() + "\n";
			_AGALVertexCode += "mov " + animationRegistersManager.scaleAndRotateTarget.toString() + "," + animationRegistersManager.positionAttribute.toString() + "\n";
			var action:ActionBase;
			for each(action in _particleActions)
			{
				if (action.priority < POST_PRIORITY)
				{
					_AGALVertexCode += action.getAGALVertexCode(pass);
				}
			}
			if (needVelocity && needVelocityInFragment)
			{
				_AGALVertexCode += "dp3 " + animationRegistersManager.velocityTarget.toString() + ".x," + animationRegistersManager.velocityTarget.toString() + "," + animationRegistersManager.velocityTarget.toString() + "\n";
				_AGALVertexCode += "sqt " + animationRegistersManager.fragmentVelocity.toString() + "," + animationRegistersManager.velocityTarget.toString() + ".x\n";
			}
			_AGALVertexCode += "add " + animationRegistersManager.scaleAndRotateTarget.toString() +"," + animationRegistersManager.scaleAndRotateTarget.toString() + "," + animationRegistersManager.offsetTarget.toString() + "\n";
			//in post_priority stage,the offsetTarget temp register if free for use,we use is as uv temp register
			
			if (needUV)
			{
				if (hasUVAction)
				{
					//if has uv action,mov uv attribute to the uvTarget temp register
					_AGALVertexCode += "mov " + animationRegistersManager.uvTarget.toString() + "," + animationRegistersManager.uvAttribute.toString() + "\n";
				}
				else
				{
					//if has not uv action,mov uv attribute to uvVar vary register directly
					_AGALVertexCode += "mov " + animationRegistersManager.uvVar.toString() + "," + animationRegistersManager.uvAttribute.toString() + "\n";
				}
			}
			
			for each(action in _particleActions)
			{
				if (action.priority >= POST_PRIORITY)
				{
					_AGALVertexCode += action.getAGALVertexCode(pass);
				}
			}
			
			if (needUV && hasUVAction)
			{
				_AGALVertexCode += "mov " + animationRegistersManager.uvVar.toString() + "," + animationRegistersManager.uvTarget.toString() + "\n";
			}
			
			_AGALVertexCode += "mov " + animationRegistersManager.scaleAndRotateTarget.regName + animationRegistersManager.scaleAndRotateTarget.index.toString() + ".w," + animationRegistersManager.vertexOneConst.toString() + "\n";
			//if time=0,set the final position to zero.
			var temp:ShaderRegisterElement = animationRegistersManager.shaderRegisterCache.getFreeVertexSingleTemp();
			_AGALVertexCode += "neg " + temp.toString() + "," + animationRegistersManager.vertexTime.toString() + "\n";
			_AGALVertexCode += "slt " + temp.toString() + "," + temp.toString() + "," + animationRegistersManager.vertexZeroConst.toString() + "\n";
			_AGALVertexCode += "mul " + animationRegistersManager.scaleAndRotateTarget.regName + animationRegistersManager.scaleAndRotateTarget.index.toString() + "," + animationRegistersManager.scaleAndRotateTarget.regName + animationRegistersManager.scaleAndRotateTarget.index.toString() + "," + temp.toString() + "\n";
			return _AGALVertexCode;
		}
		
		public function getAGALFragmentCode(pass : MaterialPassBase, shadedTarget : String) : String
		{
			animationRegistersManager.needFragmentAnimation = true;
			_AGALFragmentCode = "";
			var action:ActionBase;
			for each(action in _particleActions)
			{
				_AGALFragmentCode += action.getAGALFragmentCode(pass);
			}
			return _AGALFragmentCode;
		}
		

		public function deactivate(stage3DProxy : Stage3DProxy, pass : MaterialPassBase) : void
		{
			
		}
		
		
		public function get usesCPU() : Boolean
		{
			return false;
		}
		public function resetGPUCompatibility() : void
		{
			
		}
		public function cancelGPUCompatibility() : void
		{
			
		}
		public function hasAnimation(name:String):Boolean
		{
			return false;
		}
		
		public function getAnimation(name:String):AnimationNodeBase
		{
			return null;
		}
		
	}

}