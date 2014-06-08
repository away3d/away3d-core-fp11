package away3d.core.render {
	import away3d.arcane;
	import away3d.core.managers.Stage3DProxy;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;

	use namespace arcane;

	public class RenderTargetCopy {
		//TODO: support of different stage3ds
		private var program:Program3D;
		private var vertexBuffer:VertexBuffer3D;
		private var indexBuffer:IndexBuffer3D;
		private var _fragmentCode:String;
		private var _vertexCode:String;
		private var _texturesData:Vector.<Number> = Vector.<Number>([0, 1, 2, 3]);
		private var _vertexData:Vector.<Number> = new Vector.<Number>();
		private var _targetsCount:int = 4;
		private var _previousRatioX:Number = -1;
		private var _previousRatioY:Number = -1;

		public function RenderTargetCopy() {
		}

		public function draw(stage3DProxy:Stage3DProxy, targetsCount:uint = 4, ratioX:Number = 1, ratioY:Number = 1):void {
			var context3D:Context3D = stage3DProxy.context3D;
			if (!program || _targetsCount!=targetsCount || _previousRatioX!=ratioX || _previousRatioY!=ratioY) {
				_targetsCount = targetsCount;
				compile();
				_previousRatioX = ratioX;
				_previousRatioY = ratioY;
				var x:Number = ratioX;
				var y:Number = ratioY;

				var u1:Number = (1 - x)*.5;//0
				var u2:Number = (x + 1)*.5;//1
				var v1:Number = (1 - y)*.5;//0
				var v2:Number = (y + 1)*.5;//1

				var vertex:Vector.<Number> = Vector.<Number>(
					[
						//1
						-1, 1, 	u1, v1, 	0,0,0,0,0,0,0,
						0, 1, 	u2, v1, 	0,0,0,0,0,0,0,
						0, 0, 	u2, v2, 	0,0,0,0,0,0,0,
						-1, 0, 	u1, v2, 	0,0,0,0,0,0,0
					]);

				if(_targetsCount > 1) {
					vertex.push(
						0, 1, 0,0, 	u1, v1, 	0,0,0,0,1,
						1, 1, 0,0, 	u2, v1, 	0,0,0,0,1,
						1, 0, 0,0, 	u2, v2, 	0,0,0,0,1,
						0, 0, 0,0, 	u1, v2, 	0,0,0,0,1
					);
				}

				if(_targetsCount > 2) {
					vertex.push(
							-1, 0, 	0,0,0,0,u1, v1, 0,0,	 2,
							0, 0, 	0,0,0,0,u2, v1, 0,0,	 2,
							0, -1, 	0,0,0,0,u2, v2, 0,0,	 2,
							-1, -1, 0,0,0,0,u1, v2, 0,0,	 2
					);
				}

				if(_targetsCount > 3) {
					vertex.push(
							0,0, 	0,0,0,0,0,0,	u1, v1, 3,
							1,0, 	0,0,0,0,0,0,	u2, v1, 3,
							1, -1, 	0,0,0,0,0,0,	u2, v2, 3,
							0, -1, 	0,0,0,0,0,0,	u1, v2, 3
					);
				}

				vertexBuffer = context3D.createVertexBuffer(targetsCount * 4, 11);
				vertexBuffer.uploadFromVector(vertex, 0, targetsCount * 4);
				indexBuffer = context3D.createIndexBuffer(targetsCount * 6);

				var indexData:Vector.<uint> = new Vector.<uint>();

				for (var i:uint = 0; i < targetsCount; i++) {
					indexData.push(0 + i * 4, 1 + i * 4, 2 + i * 4, 0 + i * 4, 2 + i * 4, 3 + i * 4);
				}

				indexBuffer.uploadFromVector(indexData, 0, targetsCount * 6);
				program = context3D.createProgram();
				program.upload((new AGALMiniAssembler()).assemble(Context3DProgramType.VERTEX, _vertexCode), (new AGALMiniAssembler()).assemble(Context3DProgramType.FRAGMENT, _fragmentCode));
			}
			context3D.setProgram(program);
			context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context3D.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);//uv0
			context3D.setVertexBufferAt(2, vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_2);//uv1
			context3D.setVertexBufferAt(3, vertexBuffer, 6, Context3DVertexBufferFormat.FLOAT_2);//uv2
			context3D.setVertexBufferAt(4, vertexBuffer, 8, Context3DVertexBufferFormat.FLOAT_2);//uv3
			context3D.setVertexBufferAt(5, vertexBuffer, 10, Context3DVertexBufferFormat.FLOAT_1);//index

			_vertexData[0] = ratioX;
			_vertexData[1] = ratioY;
			_vertexData[2] = 0;
			_vertexData[3] = 1;
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexData, 1);
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _texturesData, 1);

			context3D.drawTriangles(indexBuffer, 0, 2*targetsCount);
		}

		private function compile():void {

			_vertexCode = "mov op,va0\n" +
					"mov v0,va1\n" +
					"mov v1,va2\n" +
					"mov v2,va3\n" +
					"mov v3,va4\n" +
					"mov v4,va5\n";

			_fragmentCode = "";

			_fragmentCode += "tex ft1, v0, fs0 <2d,nearst,nomip,clamp>\n";
			_fragmentCode += "seq ft2.x, v4.x, fc0.x\n";
			_fragmentCode += "mul ft1, ft1, ft2.x\n";
			_fragmentCode += "mov ft0, ft1\n";

			if(_targetsCount>1) {
				_fragmentCode += "tex ft1, v1, fs1 <2d,nearst,nomip,clamp>\n";
				_fragmentCode += "seq ft2.x, v4.x, fc0.y\n";
				_fragmentCode += "mul ft1, ft1, ft2.x\n";
				_fragmentCode += "add ft0, ft1, ft0\n";
			}

			if(_targetsCount>2) {
				_fragmentCode += "tex ft1, v2, fs2 <2d,nearst,nomip,clamp>\n";
				_fragmentCode += "seq ft2.x, v4.x, fc0.z\n";
				_fragmentCode += "mul ft1, ft1, ft2.x\n";
				_fragmentCode += "add ft0, ft1, ft0\n";
			}

			if(_targetsCount>3) {
				_fragmentCode += "tex ft1, v3, fs3 <2d,nearst,nomip,clamp>\n";
				_fragmentCode += "seq ft2.x, v4.x, fc0.w\n";
				_fragmentCode += "mul ft1, ft1, ft2.x\n";
				_fragmentCode += "add ft0, ft1, ft0\n";
			}

			_fragmentCode += "mov oc, ft0\n";
		}
	}
}