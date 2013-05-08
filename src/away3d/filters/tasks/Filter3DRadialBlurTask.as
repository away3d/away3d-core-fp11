package away3d.filters.tasks
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.Context3D;

	import flash.display3D.Context3DProgramType;

	import flash.display3D.textures.Texture;

	use namespace arcane;

	public class Filter3DRadialBlurTask extends Filter3DTaskBase
	{
		private static const LAYERS : int = 15;

		private var _data : Vector.<Number>;

		private var _intensity:Number = 1.0;
		private var _glowGamma:Number = 1.0;
		private var _blurStart:Number = 1.0;
		private var _blurWidth:Number = -0.3;
		private var _cx:Number = 0.5;
		private var _cy:Number = 0.5;

		public function Filter3DRadialBlurTask(intensity:Number = 1.0, glowGamma:Number = 1.0, blurStart:Number = 1.0, blurWidth:Number = -0.3, cx:Number = 0.5, cy:Number = 0.5)
		{
			super();
			_intensity = intensity;
			_glowGamma = glowGamma;
			_blurStart = blurStart;
			_blurWidth = blurWidth;
			_cx = cx;
			_cy = cy;
			_data = Vector.<Number>([0, 0, 0, 0, 0, 0, 0, 0,0,1,LAYERS,LAYERS-1]);
			resetUniforms();
		}

		private function resetUniforms():void
		{
			_data[0] = _intensity;
			_data[1] = _glowGamma;
			_data[2] = _blurStart;
			_data[3] = _blurWidth;
			_data[4] = _cx;
			_data[5] = _cy;
		}


		override protected function getVertexCode() : String
		{
			return 	"mov op, va0\n"+
					"mov vt0, vc2.xxxy\n"+
					"sub vt0.xy, va1.xy, vc1.xy \n"+
					"mov v0, vt0";
		}

		override protected function getFragmentCode() : String
		{
			var code : String;


			code =
			 //half4 blurred = 0,0,0,0; = ft1
			 			"mov ft1, fc2.xxxx \n"+
			// float2 ctrPt = float2(CX,CY); -> ft2
						"mov ft2.xy, fc1.xy \n"+
			// ft3.x -> counter = 0;
						"mov ft3.x, fc2.x \n";

			// Y-Axis
			for (var i:int = 0; i <= LAYERS; i++) {
				// float scale = BlurStart + BlurWidth*(i/(float) (nsamples-1)); -> ft4
				// ft4.x = (i/(float) (nsamples-1))
				code += "div ft4.x, ft3.x, fc2.w\n";
				// ft4.x *= Blurwidth;
				code += "mul ft4.x, ft4.x, fc0.w \n";
				// ft4.x += BlurStart;
				code += "add ft4.x, ft4.x, fc0.z \n";
				// blurred += tex2D(tex, IN.UV.xy*scale + ctrPt );
				code += "mov ft5.xy ,v0.xy\n";
				code += "mul ft5.xy, ft5.xy, ft4.xx \n";
				code += "add ft5.xy, ft5.xy, fc1.xy \n";
				code += "tex ft5, ft5.xy, fs0<2d, clamp, linear>\n";
				code += "add ft1, ft1, ft5 \n";
				// inc counter by one
				code += "add ft3.x, ft3.x, fc2.y \n";
			}
			/*     blurred /= nsamples;
				   blurred.rgb = pow(blurred.rgb,GlowGamma);
				   blurred.rgb *= Intensity;
				   blurred.rgb = saturate(blurred.rgb);
			*/
			code += "div ft1, ft1, fc2.z\n";
			code += "pow ft1.xyz, ft1.xyz, fc0.y\n";
			code += "mul ft1.xyz, ft1.xyz, fc0.x\n";
			code += "sat ft1.xyz, ft1.xyz \n";
	 		// var origTex = tex2D(tex, IN.UV.xy + ctrPt );
 			code += "add ft0.xy, v0.xy, fc1.xy \n";
 			code += "tex ft6, ft0.xy, fs0<2d,clamp, linear>\n";
			// var newC = origTex.rgb + blurred.rgb;
			code += "add ft1.xyz, ft1.xyz, ft6.xyz \n";
			// return newC
 			code += "mov oc, ft1\n";


			//trace(code);
			return code;
		}

		public function get intensity() : Number
		{
			return _intensity;
		}

		public function set intensity(intensity : Number) : void
		{
			_intensity = intensity;
			resetUniforms();
		}

		public function get glowGamma() : Number
		{
			return _glowGamma;
		}

		public function set glowGamma(glowGamma : Number) : void
		{
			_glowGamma = glowGamma;
			resetUniforms();
		}

		public function get blurStart() : Number
		{
			return _blurStart;
		}

		public function set blurStart(blurStart : Number) : void
		{
			_blurStart = blurStart;
			resetUniforms();
		}

		public function get blurWidth() : Number
		{
			return _blurWidth;
		}

		public function set blurWidth(blurWidth : Number) : void
		{
			_blurWidth = blurWidth;
			resetUniforms();
		}

		public function get cx() : Number
		{
			return _cx;
		}

		public function set cx(cx : Number) : void
		{
			_cx = cx;
			resetUniforms();
		}

		public function get cy() : Number
		{
			return _cy;
		}

		public function set cy(cy : Number) : void
		{
			_cy = cy;
			resetUniforms();
		}

		override public function activate(stage3DProxy : Stage3DProxy, camera3D : Camera3D, depthTexture : Texture) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _data, 3);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 3);
		}
	}
}
