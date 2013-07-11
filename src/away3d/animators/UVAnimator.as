package away3d.animators
{
	import away3d.animators.data.*;
	import away3d.animators.states.*;
	import away3d.animators.transitions.*;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.*;
	import away3d.core.managers.*;
	import away3d.core.math.MathConsts;
	import away3d.materials.*;
	import away3d.materials.passes.*;
	
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix;
	
	use namespace arcane;
	
	/**
	 * Provides an interface for assigning uv-based animation data sets to mesh-based entity objects
	 * and controlling the various available states of animation through an interative playhead that can be
	 * automatically updated or manually triggered.
	 */
	public class UVAnimator extends AnimatorBase implements IAnimator
	{
		private var _uvAnimationSet:UVAnimationSet;
		private var _deltaFrame:UVAnimationFrame = new UVAnimationFrame();
		private var _activeUVState:IUVAnimationState;
		
		private var _uvTransform:Matrix;
		private var _matrix2d:Vector.<Number>;
		private var _translate:Vector.<Number>;
		
		private var _autoRotation:Boolean;
		private var _rotationIncrease:Number = 1;
		private var _autoTranslate:Boolean;
		private var _translateIncrease:Vector.<Number>;
		
		/**
		 * Creates a new <code>UVAnimator</code> object.
		 *
		 * @param uvAnimationSet The animation data set containing the uv animations used by the animator.
		 */
		public function UVAnimator(uvAnimationSet:UVAnimationSet)
		{
			super(uvAnimationSet);
			
			_uvTransform = new Matrix();
			_matrix2d = Vector.<Number>([1, 0, 0, 0, 1, 0, 0, 0]);
			_translate = Vector.<Number>([0, 0, 0.5, 0.5]);
			_uvAnimationSet = uvAnimationSet;
		}
		
		/**
		 * Defines if a rotation is performed automatically each update. The rotationIncrease value is added each iteration.
		 */
		public function set autoRotation(b:Boolean):void
		{
			_autoRotation = b;
		}
		
		public function get autoRotation():Boolean
		{
			return _autoRotation;
		}
		
		/**
		 * if autoRotation = true, the rotation is increased by the rotationIncrease value. Default is 1;
		 */
		public function set rotationIncrease(value:Number):void
		{
			_rotationIncrease = value;
		}
		
		public function get rotationIncrease():Number
		{
			return _rotationIncrease;
		}
		
		/**
		 * Defines if the animation is translated automatically each update. Ideal to scroll maps. Use setTranslateIncrease to define the offsets.
		 */
		public function set autoTranslate(b:Boolean):void
		{
			_autoTranslate = b;
			if (b && !_translateIncrease)
				_translateIncrease = Vector.<Number>([0, 0]);
		}
		
		public function get autoTranslate():Boolean
		{
			return _autoTranslate;
		}
		
		/**
		 * if autoTranslate = true, animation is translated automatically each update with the u and v values.
		 * Note if value are integers, no visible update will be performed. Values are expected to be in 0-1 range.
		 */
		public function setTranslateIncrease(u:Number, v:Number):void
		{
			if (!_translateIncrease)
				_translateIncrease = Vector.<Number>([0, 0]);
			_translateIncrease[0] = u;
			_translateIncrease[1] = v;
		}
		
		public function get translateIncrease():Vector.<Number>
		{
			return _translateIncrease;
		}
		
		/**
		 * @inheritDoc
		 */
		public function setRenderState(stage3DProxy:Stage3DProxy, renderable:IRenderable, vertexConstantOffset:int, vertexStreamOffset:int, camera:Camera3D):void
		{
			var material:TextureMaterial = renderable.material as TextureMaterial;
			var subMesh:SubMesh = renderable as SubMesh;
			
			if (!material || !subMesh)
				return;
			
			if (autoTranslate) {
				_deltaFrame.offsetU += _translateIncrease[0];
				_deltaFrame.offsetV += _translateIncrease[1];
			}
			
			_translate[0] = _deltaFrame.offsetU;
			_translate[1] = _deltaFrame.offsetV;
			
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset, _translate);
			
			_uvTransform.identity();
			
			if (_autoRotation)
				_deltaFrame.rotation += _rotationIncrease;
			
			if (_deltaFrame.rotation != 0)
				_uvTransform.rotate(_deltaFrame.rotation*MathConsts.DEGREES_TO_RADIANS);
			if (_deltaFrame.scaleU != 1 || _deltaFrame.scaleV != 1)
				_uvTransform.scale(_deltaFrame.scaleU, _deltaFrame.scaleV);
			
			_matrix2d[0] = _uvTransform.a;
			_matrix2d[1] = _uvTransform.b;
			_matrix2d[3] = _uvTransform.tx;
			_matrix2d[4] = _uvTransform.c;
			_matrix2d[5] = _uvTransform.d;
			_matrix2d[7] = _uvTransform.ty;
			
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, vertexConstantOffset + 4, _matrix2d);
		
		}
		
		/**
		 * @inheritDoc
		 */
		public function play(name:String, transition:IAnimationTransition = null, offset:Number = NaN):void
		{
			transition = transition;
			offset = offset;
			if (_activeAnimationName == name)
				return;
			
			_activeAnimationName = name;
			
			if (!_animationSet.hasAnimation(name))
				throw new Error("Animation root node " + name + " not found!");
			
			_activeNode = _animationSet.getAnimation(name);
			_activeState = getAnimationState(_activeNode);
			_activeUVState = _activeState as IUVAnimationState;
			
			start();
		}
		
		/**
		 * Applies the calculated time delta to the active animation state node.
		 */
		override protected function updateDeltaTime(dt:Number):void
		{
			_absoluteTime += dt;
			_activeUVState.update(_absoluteTime);
			
			var currentUVFrame:UVAnimationFrame = _activeUVState.currentUVFrame;
			var nextUVFrame:UVAnimationFrame = _activeUVState.nextUVFrame;
			var blendWeight:Number = _activeUVState.blendWeight;
			
			if (currentUVFrame && nextUVFrame) {
				_deltaFrame.offsetU = currentUVFrame.offsetU + blendWeight*(nextUVFrame.offsetU - currentUVFrame.offsetU);
				_deltaFrame.offsetV = currentUVFrame.offsetV + blendWeight*(nextUVFrame.offsetV - currentUVFrame.offsetV);
				_deltaFrame.scaleU = currentUVFrame.scaleU + blendWeight*(nextUVFrame.scaleU - currentUVFrame.scaleU);
				_deltaFrame.scaleV = currentUVFrame.scaleV + blendWeight*(nextUVFrame.scaleV - currentUVFrame.scaleV);
				_deltaFrame.rotation = currentUVFrame.rotation + blendWeight*(nextUVFrame.rotation - currentUVFrame.rotation);
			}
		}
		
		/**
		 * Verifies if the animation will be used on cpu. Needs to be true for all passes for a material to be able to use it on gpu.
		 * Needs to be called if gpu code is potentially required.
		 */
		public function testGPUCompatibility(pass:MaterialPassBase):void
		{
		}
		
		/**
		 * @inheritDoc
		 */
		public function clone():IAnimator
		{
			return new UVAnimator(_uvAnimationSet);
		}
	
	}
}
