package away3d.filters.tasks
{
	import away3d.cameras.*;
	import away3d.core.managers.*;
	import away3d.core.math.*;
	import away3d.materials.utils.*;
	
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	
	public class Filter3DFishEyeTask extends Filter3DTaskBase
	{
		private static var MAX_AUTO_SAMPLES:int = 15;
		private var _size:uint;
		private var _sizeDirty:Boolean = true;
		private var _fov:uint = 180;
		private var _data:Vector.<Number>;
		
		/**
		 * Creates a new Filter3DFishEyeTask.
		 */
		public function Filter3DFishEyeTask(size:uint = 256, fov:Number = 180)
		{
			super();
			_size = size;
			_fov = fov;
			_data = Vector.<Number>([0, 0, 0.5, 1]);
		}
		
		public function get fov():Number
		{
			return _fov;
		}
		
		public function set fov(value:Number):void
		{
			if (value == _fov)
				return;
			_fov = value;
			
			invalidateProgram3D();
		}
		
		public function get size():uint
		{
			return _size;
		}
		
		public function set size(value:uint):void
		{
			if (value == _size)
				return;
			_size = value;
			
			_sizeDirty = true;
		}
		
		override protected function getFragmentCode():String
		{
			var code:String;
			var numSamples:int = 1;
			//phi = sqrt(x^2 + y^2)
			//x = sin(phi)*x/phi
			//y = sin(phi)*y/phi
			//z = cos(phi)
			code = "sub ft0.x, v0.x, fc0.z\n" + //x = (uu-0.5)
				"sub ft0.y, fc0.z, v0.y\n" + //y = (0.5-vv)
				"mul ft0.xy, ft0.xy, fc0.xy\n" + //(xy = xy*fov)
				"mul ft1.xy, ft0.xy, ft0.xy\n" + //xy = xy*xy
				"add ft1.z, ft1.x, ft1.y\n" + //z = x^2 + y^2
				"sqt ft1.z, ft1.z\n" + //phi = sqrt(z)
				"sin ft1.w, ft1.z\n" + //sinPhi = sin(phi)
				"div ft0.xy, ft0.xy, ft1.zz\n" + //xy = xy/phi
				"mul ft0.xy, ft0.xy, ft1.ww\n" + //xy = xy*sinPhi
				"cos ft0.z, ft1.z\n" + //z = cos(phi)
				"mov ft0.w, fc0.w\n" +
				"tex oc, ft0, fs0 <cube,linear,miplinear>\n";
			
			return code;
		}
		
		override public function activate(stage3DProxy:Stage3DProxy, camera3D:Camera3D, depthTexture:Texture):void
		{
			_data[0] = _fov*MathConsts.DEGREES_TO_RADIANS*_scaledTextureWidth/stage3DProxy.height;
			_data[1] = _fov*MathConsts.DEGREES_TO_RADIANS*_scaledTextureHeight/stage3DProxy.height;
			
			stage3DProxy.context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 1);
		}
		
		override protected function updateTextures(stage:Stage3DProxy):void
		{
			if (!_sizeDirty)
				return;
			
			if (_mainInputTexture)
				_mainInputTexture.dispose();
			
			_mainInputTextureContext = stage.context3D;
			_mainInputTexture = _mainInputTextureContext.createCubeTexture(_size, Context3DTextureFormat.BGRA, true);
			
			// fake data, to complete texture for sampling
			var bmd:BitmapData = new BitmapData(_size, _size, false, 0);
			for (var i:int = 0; i < 6; ++i)
				MipmapGenerator.generateMipMaps(bmd, _mainInputTexture, null, false, i);
			bmd.dispose();
			
			_textureDimensionsInvalid = false;
		}
	}
}
