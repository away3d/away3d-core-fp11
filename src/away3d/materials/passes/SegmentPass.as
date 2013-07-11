package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.entities.SegmentSet;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Matrix3D;
	
	use namespace arcane;

	/**
	 * SegmentPass is a material pass that draws wireframe segments.
	 */
	public class SegmentPass extends MaterialPassBase
	{
		protected static const ONE_VECTOR:Vector.<Number> = Vector.<Number>([ 1, 1, 1, 1 ]);
		protected static const FRONT_VECTOR:Vector.<Number> = Vector.<Number>([ 0, 0, -1, 0 ]);
		
		private var _constants:Vector.<Number> = new Vector.<Number>(4, true);
		private var _calcMatrix:Matrix3D;
		private var _thickness:Number;
		
		/**
		 * Creates a new SegmentPass object.
		 *
		 * @param thickness the thickness of the segments to be drawn.
		 */
		public function SegmentPass(thickness:Number)
		{
			_calcMatrix = new Matrix3D();
			
			_thickness = thickness;
			_constants[1] = 1/255;
			
			super();
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode():String
		{
			return "m44 vt0, va0, vc8			\n" + // transform Q0 to eye space
				"m44 vt1, va1, vc8			\n" + // transform Q1 to eye space
				"sub vt2, vt1, vt0 			\n" + // L = Q1 - Q0
				
				// test if behind camera near plane
				// if 0 - Q0.z < Camera.near then the point needs to be clipped
				//"neg vt5.x, vt0.z				\n" + // 0 - Q0.z
				"slt vt5.x, vt0.z, vc7.z			\n" + // behind = ( 0 - Q0.z < -Camera.near ) ? 1 : 0
				"sub vt5.y, vc5.x, vt5.x			\n" + // !behind = 1 - behind
				
				// p = point on the plane (0,0,-near)
				// n = plane normal (0,0,-1)
				// D = Q1 - Q0
				// t = ( dot( n, ( p - Q0 ) ) / ( dot( n, d )
				
				// solve for t where line crosses Camera.near
				"add vt4.x, vt0.z, vc7.z			\n" + // Q0.z + ( -Camera.near )
				"sub vt4.y, vt0.z, vt1.z			\n" + // Q0.z - Q1.z
				
				// fix divide by zero for horizontal lines	
				"seq vt4.z, vt4.y vc6.x			\n" + // offset = (Q0.z - Q1.z)==0 ? 1 : 0
				"add vt4.y, vt4.y, vt4.z			\n" + // ( Q0.z - Q1.z ) + offset
				
				"div vt4.z, vt4.x, vt4.y			\n" + // t = ( Q0.z - near ) / ( Q0.z - Q1.z )
				
				"mul vt4.xyz, vt4.zzz, vt2.xyz	\n" + // t(L)
				"add vt3.xyz, vt0.xyz, vt4.xyz	\n" + // Qclipped = Q0 + t(L)
				"mov vt3.w, vc5.x			\n" + // Qclipped.w = 1
				
				// If necessary, replace Q0 with new Qclipped
				"mul vt0, vt0, vt5.yyyy			\n" + // !behind * Q0
				"mul vt3, vt3, vt5.xxxx			\n" + // behind * Qclipped
				"add vt0, vt0, vt3				\n" + // newQ0 = Q0 + Qclipped
				
				// calculate side vector for line
				"sub vt2, vt1, vt0 			\n" + // L = Q1 - Q0
				"nrm vt2.xyz, vt2.xyz			\n" + // normalize( L )
				"nrm vt5.xyz, vt0.xyz			\n" + // D = normalize( Q1 )
				"mov vt5.w, vc5.x				\n" + // D.w = 1
				"crs vt3.xyz, vt2, vt5			\n" + // S = L x D
				"nrm vt3.xyz, vt3.xyz			\n" + // normalize( S )
				
				// face the side vector properly for the given point
				"mul vt3.xyz, vt3.xyz, va2.xxx	\n" + // S *= weight
				"mov vt3.w, vc5.x			\n" + // S.w = 1
				
				// calculate the amount required to move at the point's distance to correspond to the line's pixel width
				// scale the side vector by that amount
				"dp3 vt4.x, vt0, vc6			\n" + // distance = dot( view )
				"mul vt4.x, vt4.x, vc7.x			\n" + // distance *= vpsod
				"mul vt3.xyz, vt3.xyz, vt4.xxx	\n" + // S.xyz *= pixelScaleFactor
				
				// add scaled side vector to Q0 and transform to clip space
				"add vt0.xyz, vt0.xyz, vt3.xyz	\n" + // Q0 + S
				
				"m44 op, vt0, vc0			\n" + // transform Q0 to clip space
				
				// interpolate color
				"mov v0, va3				\n";
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode(animationCode:String):String
		{
			return "mov oc, v0\n";
		}
		
		/**
		 * @inheritDoc
		 * todo: keep maps in dictionary per renderable
		 */
		arcane override function render(renderable:IRenderable, stage3DProxy:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			var context:Context3D = stage3DProxy._context3D;
			_calcMatrix.copyFrom(renderable.sourceEntity.sceneTransform);
			_calcMatrix.append(camera.inverseSceneTransform);
			
			var subSetCount:uint = SegmentSet(renderable).subSetCount;
			
			if (SegmentSet(renderable).hasData) {
				for (var i:uint = 0; i < subSetCount; ++i) {
					renderable.activateVertexBuffer(i, stage3DProxy);
					context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 8, _calcMatrix, true);
					context.drawTriangles(renderable.getIndexBuffer(stage3DProxy), 0, renderable.numTriangles);
				}
			}
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			var context:Context3D = stage3DProxy._context3D;
			super.activate(stage3DProxy, camera);
			
			if (stage3DProxy.scissorRect)
				_constants[0] = _thickness/Math.min(stage3DProxy.scissorRect.width, stage3DProxy.scissorRect.height);
			else
				_constants[0] = _thickness/Math.min(stage3DProxy.width, stage3DProxy.height);
			
			// value to convert distance from camera to model length per pixel width
			_constants[2] = camera.lens.near;
			
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, ONE_VECTOR);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 6, FRONT_VECTOR);
			context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 7, _constants);
			
			// projection matrix
			context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, camera.lens.matrix, true);
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(stage3DProxy:Stage3DProxy):void
		{
			var context:Context3D = stage3DProxy._context3D;
			context.setVertexBufferAt(0, null);
			context.setVertexBufferAt(1, null);
			context.setVertexBufferAt(2, null);
			context.setVertexBufferAt(3, null);
		}
	}
}
