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
		private var program:Program3D;
		private var vertexBuffer:VertexBuffer3D;
		private var indexBuffer:IndexBuffer3D;
		private var _fragmentCode:String;
		private var _vertexCode:String;
		private var _texturesData:Vector.<Number> = Vector.<Number>([0, 1, 2, 3]);

		public function RenderTargetCopy() {
		}

		public function draw(stage3DProxy:Stage3DProxy, targetsCount:uint = 4):void {
			var context3D:Context3D = stage3DProxy.context3D;
			if (!program) {
				compile();
				var vertex:Vector.<Number> = Vector.<Number>(
						[
							//1
							-1, 1, 0, 0, 0,
							0, 1, 1, 0, 0,
							0, 0, 1, 1, 0,
							-1, 0, 0, 1, 0,
							//2
							0, 1, 0, 0, 1,
							1, 1, 1, 0, 1,
							1, 0, 1, 1, 1,
							0, 0, 0, 1, 1,
							//3
							0, 0, 0, 0, 2,
							1, 0, 1, 0, 2,
							1, -1, 1, 1, 2,
							0, -1, 0, 1, 2,
							//4
							-1, 0, 0, 0, 3,
							0, 0, 1, 0, 3,
							0, -1, 1, 1, 3,
							-1, -1, 0, 1, 3
						]);
				vertexBuffer = context3D.createVertexBuffer(targetsCount * 4, 5);
				vertexBuffer.uploadFromVector(vertex, 0, targetsCount * 4);
				indexBuffer = context3D.createIndexBuffer(targetsCount * 6);
				var indexData:Vector.<uint> = new Vector.<uint>();
				for (var i:uint = 0; i < targetsCount; i++) {
					indexData.push(0 + i * 4, 1 + i * 4, 2 + i * 4, 0 + i * 4, 2 + i * 4, 3 + i * 4);
				}
				indexBuffer.uploadFromVector(indexData, 0, targetsCount * 6);
				program = context3D.createProgram();
				program.upload((new AGALMiniAssembler()).assemble(Context3DProgramType.VERTEX, _vertexCode, 2), (new AGALMiniAssembler()).assemble(Context3DProgramType.FRAGMENT, _fragmentCode, 2));
			}
			context3D.setProgram(program);
			context3D.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			context3D.setVertexBufferAt(1, vertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
			context3D.setVertexBufferAt(2, vertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_1);
			context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _texturesData, 1);

			context3D.drawTriangles(indexBuffer, 0, 2*targetsCount);
		}

		private function compile():void {

			_vertexCode = "mov op,va0\n" +
					"mov v0,va1\n" +
					"mov v1,va2\n";

			_fragmentCode = "";
			_fragmentCode += "mov ft0, fc0\n";
			_fragmentCode += "ife v1.y, fc0.x\n";
			_fragmentCode += "tex ft0, v0, fs0 <2d,nearst,nomip,clamp>\n";
			_fragmentCode += "eif\n";
			_fragmentCode += "ife v1.x, fc0.y\n";
			_fragmentCode += "tex ft0, v0, fs1 <2d,nearst,nomip,clamp>\n";
			_fragmentCode += "eif\n";
			_fragmentCode += "ife v1.x, fc0.z\n";
			_fragmentCode += "tex ft0, v0, fs2 <2d,nearst,nomip,clamp>\n";
			_fragmentCode += "eif\n";
			_fragmentCode += "ife v1.x, fc0.w\n";
			_fragmentCode += "tex ft0, v0, fs3 <2d,nearst,nomip,clamp>\n";
			_fragmentCode += "eif\n";
			_fragmentCode += "mov oc, ft0\n";
		}
	}

}