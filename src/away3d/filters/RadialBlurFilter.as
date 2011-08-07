package away3d.filters{
	import away3d.filters.Filter3DBase;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.managers.Stage3DProxy;
	import away3d.debug.Debug;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;

	use namespace arcane;

	public class RadialBlurFilter extends Filter3DBase
	{
		private static const LAYERS : int = 15;
		private var _program3d : Program3D;

		private var _data : Vector.<Number>;
		
		private var _intensity:Number = 8.0;
		private var _glowGamma:Number = 1.6;
		private var _blurStart:Number = 1.0;
		private var _blurWidth:Number = -0.3;
		private var _cx:Number = 0.5;
		private var _cy:Number = 0.5;  

		public function RadialBlurFilter(intensity:Number = 8.0, glowGamma:Number = 1.6, blurStart:Number = 1.0, blurWidth:Number = -0.3, cx:Number = 0.5, cy:Number = 0.5)
		{
			super(false);
			_intensity = intensity;
			_glowGamma = glowGamma;
			_blurStart = blurStart;
			_blurWidth = blurWidth;
			_cx = cx;
			_cy = cy;
			_data = Vector.<Number>([0, 0, 0, 0, 0, 0, 0, 0,0,1,LAYERS,LAYERS-1]);
			resetUniforms();
		}

		public function resetUniforms():void
		{
			_data[0] = _intensity;
			_data[1] = _glowGamma;
			_data[2] = _blurStart;
			_data[3] = _blurWidth;
			_data[4] = _cx;
			_data[5] = _cy;
		}

		private function invalidateProgram() : void
		{
			if (_program3d) {
				_program3d.dispose();
				_program3d = null;
			}
		}

		override public function render(stage3DProxy : Stage3DProxy, target : Texture, camera : Camera3D, depthRender : Texture = null) : void
		{
			var context : Context3D =  stage3DProxy._context3D;

			super.render(stage3DProxy, target, camera);

			if (!_program3d) initProgram(context);

			if (target)
				context.setRenderToTexture(target, false, 0, 0);
			else
				context.setRenderToBackBuffer();

			stage3DProxy.setProgram(_program3d);
			context.clear(0.0, 0.0, 0.0, 1.0);
			context.setVertexBufferAt(0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context.setVertexBufferAt(1, _vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			stage3DProxy.setTextureAt(0, _inputTexture);
			context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _data, 3);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _data, 3);
			context.drawTriangles(_indexBuffer, 0, 2);
			stage3DProxy.setTextureAt(0, null);
			stage3DProxy.setSimpleVertexBuffer(0, null);
			stage3DProxy.setSimpleVertexBuffer(1, null);
		}

		private function initProgram(context : Context3D) : void
		{
			_program3d = context.createProgram();
			_program3d.upload(	new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.VERTEX, getVertexCode()),
								new AGALMiniAssembler(Debug.active).assemble(Context3DProgramType.FRAGMENT, getFragmentCode())
							);
		}


		protected function getVertexCode() : String
		{
			return 	"mov op, va0\n"+
					"mov vt0, vc2.xxxy\n"+
					"sub vt0.xy, va1.xy, vc1.xy \n"+
					"mov v0, vt0";
		}

		protected function getFragmentCode() : String
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
			code += "pow ft1.xyz, ft1.xyz, fc.yyy\n";
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

	}
}
