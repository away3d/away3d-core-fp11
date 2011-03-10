package away3d.materials.passes {
	import flash.display3D.Context3DCompareMode;
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.core.base.IRenderable;

	import bi.debug.log.Logger;

	import fr.nss.duck.World;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;







	/**
	 * @author jerome BIREMBAUT  Twitter: Seraf_NSS
	 */
	
	use namespace arcane;


	public class WireFramePass extends MaterialPassBase
	{
	
		protected static const DEG2RAD_2:Number						= Math.PI / 360.0;
		protected static const ONE_VECTOR:Vector.<Number>			= Vector.<Number>( [ 1,1,1,1 ] );
		protected static const ZERO_VECTOR:Vector.<Number>			= Vector.<Number>( [ 0,0,0,0 ] );
		protected static const FRONT_VECTOR:Vector.<Number>			= Vector.<Number>( [ 0,0,-1,0 ] );
		
	
		private var constants:Vector.<Number> = new Vector.<Number>( 4, true);
		private var world2view : Matrix3D;
		private var projectionMatrix2 : Matrix3D;
		private var _vertexBuffer : VertexBuffer3D;

		/**
		 * Creates a new SingleObjectDepthPass object.
		 * @param textureSize The size of the depth map texture to render to.
		 * @param polyOffset The amount by which the rendered object will be inflated, to prevent depth map rounding errors.
		 */
		public function WireFramePass()
		{

			super();

		}

	


		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
		//	_projectedTargetRegister = "vt2";
			//var code : String = "";

			/*code += AGAL.rcp("vt2.w", "vt2.w");
			code += AGAL.mul("v0.xyz", "vt2.xyz", "vt2.w");
			code += AGAL.mov("v0.w", "vt0.w");*/

			var code : String = 
			/*"m44 vt0, va0, vc10				\n" +	// transform Q0 to eye space
			"m44 vt1, va1, vc10				\n" +	// transform Q1 to eye space
			"add vt0.xyz, vt0.xyz, va2.xxx				\n" +	
			"m44 op, vt0, vc14	\n" +// transform Q0 to clip space
			"mov v0, va3					\n" +*/
			
			"m44 vt3, va0, vc18				\n" +	// transform Q0 to eye space
			"m44 vt4, va1, vc18				\n" +
			"m44 vt0, vt3, vc10				\n" +	// transform Q0 to eye space
			"m44 vt1, vt4, vc10				\n" +	// transform Q1 to eye space

			
			"sub vt2, vt1, vt0 				\n" +	// L = Q1 - Q0
			
			//"add vt0, vt0, vc4	\n" +	// ad offset
			//"add vt1, vt1, vc4	\n" +	// ad offset
			
			// test if behind camera near plane
			// if 0 - Q0.z < Camera.near then the point needs to be clipped
			"sub vt5.x, vc0.z, vt0.z		\n" +	// 0 - Q0.z
			"slt vt5.x, vt5.x, vc3.z		\n" +	// behind = ( 0 - Q0.z < -Camera.near ) ? 1 : 0
			"sub vt5.y, vc1.x, vt5.x		\n" +	// !behind = 1 - behind

			// p = point on the plane (0,0,-near)
			// n = plane normal (0,0,-1)
			// D = Q1 - Q0
			// t = ( dot( n, ( p - Q0 ) ) / ( dot( n, d )
			
			// solve for t where line crosses Camera.near
			"add vt4.x, vt0.z, vc3.z		\n" +	// Q0.z + ( -Camera.near )
			"sub vt4.y, vt0.z, vt1.z		\n" +	// Q0.z - Q1.z
			"div vt4.z, vt4.x, vt4.y		\n" +	// t = ( Q0.z - near ) / ( Q0.z - Q1.z )
			
			"mul vt4.xyz, vt4.zzz, vt2.xyz	\n" +	// t(L)
			"add vt3.xyz, vt0.xyz, vt4.xyz	\n" +	// Qclipped = Q0 + t(L)
			"mov vt3.w, vc1.w				\n" +	// Qclipped.w = 1
			
			// If necessary, replace Q0 with new Qclipped
			"mul vt0, vt0, vt5.yyyy			\n" +	// !behind * Q0
			"mul vt3, vt3, vt5.xxxx			\n" +	// behind * Qclipped
			"add vt0, vt0, vt3				\n" +	// newQ0 = Q0 + Qclipped

			// calculate side vector for line
			"sub vt2, vt1, vt0 				\n" +	// L = Q1 - Q0
			"nrm vt2.xyz, vt2.xyz			\n" +	// normalize( L )
			"nrm vt5.xyz, vt0.xyz			\n" +	// D = normalize( Q1 )
			"mov vt5.w, vc1.w				\n" +	// D.w = 1
			"crs vt3.xyz, vt2, vt5			\n" +	// S = L x D
			"nrm vt3.xyz, vt3.xyz			\n" +	// normalize( S )

			// face the side vector properly for the given point
			"mul vt3.xyz, vt3.xyz, va2.xxx	\n" +	// S *= weight
			"mov vt3.w, vc1.w				\n" +	// S.w = 1
			
			// calculate the amount required to move at the point's distance to correspond to the line's pixel width
			// scale the side vector by that amount
			"dp3 vt4.x, vt0, vc2			\n" +	// distance = dot( view )
			"mul vt4.x, vt4.x, vc3.x		\n" +	// distance *= vpsod
			"mul vt3.xyz, vt3.xyz, vt4.xxx	\n" +	// S.xyz *= pixelScaleFactor
			
			
			
			// add scaled side vector to Q0 and transform to clip space
			"add vt0.xyz, vt0.xyz, vt3.xyz	\n" +	// Q0 + S
			
			
			
			"m44 op, vt0, vc14				\n" +	// transform Q0 to clip space
			
			//"m44 op, vt6, vc18		\n"+
			// interpolate color
			"mov v0, va3					\n" +
			"";
			return code;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			var code : String = "";
			code+="mov oc, v0\n" ;

			return code;
		}

		public function  projectionMatrix(camera : Camera3D):Matrix3D
		{
			/*if ( _dirty )
			{
				_dirty = false;
				*/
				var _aspect:Number=camera.lens.aspectRatio;
				var n:Number = camera.lens.near;
				var f:Number = camera.lens.far;
				
				var y:Number = n * Math.tan( (camera.lens as PerspectiveLens).fieldOfView * DEG2RAD_2 );
				var x:Number = y * _aspect;
				
				
			//}
			
			return new Matrix3D(
					Vector.<Number>(
						[
							n/x,			0,				0,				0,
							0,				n/y,			0,				0,
							0,				0,				(f+n)/(n-f),	-1,
							0,				0,				(2*f*n)/(n-f),	0
						]
					)
				);
		}

		/**
		 * @inheritDoc
		 * todo: keep maps in dictionary per renderable
		 */
		arcane override function render(renderable : IRenderable, context : Context3D, contextIndex : uint, camera : Camera3D) : void
		{
			

			// value to convert distance from camera to model length per pixel width
			constants[ 0 ] = 2 * Math.tan( (camera.lens as PerspectiveLens).fieldOfView * DEG2RAD_2 ) / 700;//700 is height stage
			constants[ 1 ] = 1 / 255;
			constants[ 2 ] = camera.lens.near;
			
			context.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 0, ZERO_VECTOR );
			context.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 1, ONE_VECTOR );
			context.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 2, FRONT_VECTOR );			
			context.setProgramConstantsFromVector( Context3DProgramType.VERTEX, 3, constants );

		
			//OMG part 4day to fing the correct matrix
			
			//world2view.appendRotation(180, Vector3D.X_AXIS);
			//world2view.appendRotation(90, Vector3D.Y_AXIS);


			/*world2view.appendRotation(World.xAxis.value, Vector3D.X_AXIS);
			world2view.appendRotation(World.yAxis.value, Vector3D.Y_AXIS);
			world2view.appendRotation(World.zAxis.value, Vector3D.Z_AXIS);*/
			world2view= camera.transform.clone();
            var comps:Vector.<Vector3D> = world2view.decompose();
        	comps[0].negate();
         	comps[2].x= -comps[2].x;
     		comps[2].y= -comps[2].y;
            world2view.recompose(comps);
            world2view.invert();
  			world2view.prependScale(-1, -1, -1);
			context.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 10, world2view, true );
			projectionMatrix2=projectionMatrix(camera);

			context.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 14,projectionMatrix2, true );
			
			
			var m:Matrix3D=renderable.sourceEntity.sceneTransform.clone();
			m.append(renderable.sourceEntity.transform);
			//m.position=renderable.sourceEntity.transform.position.clone();
			
			
			
			context.setProgramConstantsFromMatrix( Context3DProgramType.VERTEX, 18,m);
			_vertexBuffer=renderable.getVertexBuffer(context, contextIndex);
			context.setVertexBufferAt( 0, _vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3 );
			context.setVertexBufferAt( 1, _vertexBuffer, 3, Context3DVertexBufferFormat.FLOAT_3 );
			context.setVertexBufferAt( 2, _vertexBuffer, 6, Context3DVertexBufferFormat.FLOAT_1 );
			context.setVertexBufferAt( 3, _vertexBuffer, 7, Context3DVertexBufferFormat.FLOAT_4 );
			
				context.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
			context.drawTriangles( renderable.getIndexBuffer(context, contextIndex), 0, renderable.numTriangles );
		
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(context : Context3D, contextIndex : uint, camera : Camera3D) : void
		{
		
			super.activate(context, contextIndex, camera);
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateProgram(context : Context3D, contextIndex : uint, polyOffsetReg : String = null) : void
		{
			super.updateProgram(context, contextIndex/*, "vc6.x"*/);
		}
		arcane override function deactivate(context : Context3D) : void
		{
			context.setVertexBufferAt( 0, null );
			context.setVertexBufferAt( 1, null);
			context.setVertexBufferAt( 2, null );
			context.setVertexBufferAt( 3, null );
		}
	}
}