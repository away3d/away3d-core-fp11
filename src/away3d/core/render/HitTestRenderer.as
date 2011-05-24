package away3d.core.render
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.SubMesh;
	import away3d.core.math.Matrix3DUtils;
	import away3d.core.traverse.EntityCollector;
	import away3d.entities.Entity;

	import com.adobe.utils.AGALMiniAssembler;

	import flash.display.BitmapData;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Program3D;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * HitTestRenderer provides a renderer that can identify objects under a given screen position and can optionally
	 * calculate further geometrical information about the object at that point.
	 *
	 * @see away3d.core.managers.Mouse3DManager
	 */
	public class HitTestRenderer extends RendererBase
	{
		private var _objectProgram3D : Program3D;
		private var _triangleProgram3D : Program3D;
		public var _bitmapData : BitmapData;
		private var _viewportData : Vector.<Number>;
		private var _boundScale : Vector.<Number>;
		private var _boundOffset : Vector.<Number>;
		private var _id : Vector.<Number>;

		private var _interactives : Vector.<IRenderable>;
		private var _interactiveId : uint;
		private var _hitColor : uint;
		private var _inverse : Matrix3D;
		private var _projX : Number;
		private var _projY : Number;

		private var _hitRenderable : IRenderable;
		private var _localHitPosition : Vector3D;
		private var _hitUV : Point;


		/**
		 * Creates a new HitTestRenderer object.
		 * @param renderMode The render mode to use.
		 */
		public function HitTestRenderer(renderMode : String = "auto")
		{
			super(0, true, renderMode);
			swapBackBuffer = false;
			backBufferWidth = 1;
			backBufferHeight = 1;

			init();
		}

		/**
		 * Initializes data.
		 */
		private function init() : void
		{
			_id = new Vector.<Number>(4, true);
			_viewportData = new Vector.<Number>(4, true);	// first 2 contain scale, last 2 translation
			_boundScale = new Vector.<Number>(4, true);	// first 2 contain scale, last 2 translation
			_boundOffset = new Vector.<Number>(4, true);	// first 2 contain scale, last 2 translation
			_boundScale[3] = 1;
			_boundOffset[3] = 0;
			_localHitPosition = new Vector3D();
			_interactives = new Vector.<IRenderable>();
			_bitmapData = new BitmapData(1, 1, false, 0);
			_inverse = new Matrix3D();
		}

		/**
		 * Updates the object information at the given position for the given visible objects.
		 * @param ratioX A ratio between 0 and 1 of the horizontal hit-test position relative to the viewport width.
		 * @param ratioY A ratio between 0 and 1 of the vertical hit-test position relative to the viewport height.
		 * @param entityCollector The EntityCollector object containing all potentially visible objects.
		 */
		public function update(ratioX : Number, ratioY : Number, entityCollector : EntityCollector) : void
		{
			if (!_stage3DProxy) return;

			_viewportData[0] = _viewPortWidth;
			_viewportData[1] = _viewPortHeight;
			_viewportData[2] = _projX = 1 - ratioX*2;
			_viewportData[3] = _projY = ratioY*2 - 1;

			render(entityCollector);

			if (!_context) return;
			_context.drawToBitmapData(_bitmapData);
			_hitColor = _bitmapData.getPixel(0, 0);

			if (_hitColor == 0) {
				_hitRenderable = null;
			}
			else {
				_hitRenderable = _interactives[_hitColor-1];

				if (_hitRenderable.mouseDetails)
					getHitDetails(entityCollector.camera);
				else {
					_hitUV = null;
//					_localHitPosition = null;
				}
			}
//			_context.clear(0, 0, 0, 0, 1, 0);
			_context.present();
		}

		/**
		 * The IRenderable object directly under the hit-test position after a call to update.
		 */
		public function get hitRenderable() : IRenderable
		{
			return _hitRenderable;
		}

		/**
		 * The UV coordinate at the hit position.
		 */
		public function get hitUV() : Point
		{
			return _hitUV;
		}

		/**
		 * The coordinate in object space of the hit position.
		 */
		public function get localHitPosition() : Vector3D
		{
			return _localHitPosition;
		}

//		/**
//		 * Unsupported
//		 * @private
//		 */
//		arcane override function set viewPortX(value : Number) : void {}

//		/**
//		 * Unsupported
//		 * @private
//		 */
//		arcane override function set viewPortY(value : Number) : void {}

		/**
		 * @inheritDoc
		 */
		override protected function draw(entityCollector : EntityCollector) : void
		{
			var camera : Camera3D = entityCollector.camera;

			_context.clear(0, 0, 0, 1);

			_interactives.length = _interactiveId = 0;

			if (!_objectProgram3D) initObjectProgram3D();
			_context.setProgram(_objectProgram3D);
			_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _viewportData, 1);
			drawRenderables(entityCollector.opaqueRenderables, camera);
			drawRenderables(entityCollector.blendedRenderables, camera);
		}

		/**
		 * Draw a list of renderables.
		 * @param renderables The renderables to draw.
		 * @param camera The camera for which to render.
		 */
		private function drawRenderables(renderables : Vector.<IRenderable>, camera : Camera3D) : void
		{
			var renderable : IRenderable;
			var len : uint = renderables.length;

			// todo: do a fast ray intersection test first?
			for (var i : uint = 0; i < len; ++i) {
				renderable = renderables[i];
				// it's possible that the renderable was already removed from the scene
				if (!renderable.sourceEntity.scene || !renderable.mouseEnabled) continue;
				_context.setCulling(renderable.material.bothSides? Context3DTriangleFace.NONE : Context3DTriangleFace.BACK);

				_interactives[_interactiveId++] = renderable;
				// color code so that reading from bitmapdata will contain the correct value
				_id[1] = (_interactiveId >> 8)/255;	    // on green channel
				_id[2] = (_interactiveId & 0xff)/255;  	// on blue channel

				_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, renderable.modelViewProjection, true);
				_context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _id, 1);
				_context.setVertexBufferAt(0, renderable.getVertexBuffer(_context, _contextIndex), 0, Context3DVertexBufferFormat.FLOAT_3);
				_context.drawTriangles(renderable.getIndexBuffer(_context, _contextIndex), 0, renderable.numTriangles);
			}
		}

		/**
		 * Creates the Program3D that color-codes objects.
		 */
		private function initObjectProgram3D() : void
		{
			var vertexCode : String;
			var fragmentCode : String;

			_objectProgram3D = _context.createProgram();

			vertexCode = 	"m44 vt0, va0, vc0	\n" +
							"mul vt1.xy, vt0.w, vc4.zw	\n" +
							"add vt0.xy, vt0.xy, vt1.xy	\n" +
							"mul vt0.xy, vt0.xy, vc4.xy	\n" +
							"mov op, vt0	\n";
			fragmentCode =  "mov oc, fc0";		// write identifier

			_objectProgram3D.upload(	new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vertexCode),
										new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT, fragmentCode));
		}

		/**
		 * Creates the Program3D that renders positions.
		 */
		private function initTriangleProgram3D() : void
		{
			var vertexCode : String;
			var fragmentCode : String;

			_triangleProgram3D = _context.createProgram();

			// todo: add animation code
			vertexCode = 	"add vt0, va0, vc5 			\n" +
							"mul vt0, vt0, vc6 			\n" +
							"mov v0, vt0				\n" +
							"m44 vt0, va0, vc0			\n" +
							"mul vt1.xy, vt0.w, vc4.zw	\n" +
							"add vt0.xy, vt0.xy, vt1.xy	\n" +
							"mul vt0.xy, vt0.xy, vc4.xy	\n" +
							"mov op, vt0	\n";
			fragmentCode =  "mov oc, v0";		// write identifier

			_triangleProgram3D.upload(	new AGALMiniAssembler().assemble(Context3DProgramType.VERTEX, vertexCode),
										new AGALMiniAssembler().assemble(Context3DProgramType.FRAGMENT, fragmentCode));
		}

		/**
		 * Gets more detailed information about the hir position, if required.
		 * @param camera The camera used to view the hit object.
		 */
		private function getHitDetails(camera : Camera3D) : void
		{
			getApproximatePosition(camera);
			getPreciseDetails(camera);
		}

		/**
		 * Finds a first-guess approximate position about the hit position.
		 * @param camera The camera used to view the hit object.
		 */
		private function getApproximatePosition(camera : Camera3D) : void
		{
			var entity : Entity = _hitRenderable.sourceEntity;
			var col : uint;
			var scX : Number, scY : Number, scZ : Number;
			var offsX : Number, offsY : Number, offsZ : Number;
			var localViewProjection : Matrix3D = _hitRenderable.modelViewProjection;

			if (!_triangleProgram3D) initTriangleProgram3D();

			_boundScale[0] = scX = 1/(entity.maxX-entity.minX);
			_boundScale[1] = scY = 1/(entity.maxY-entity.minY);
			_boundScale[2] = scZ = 1/(entity.maxZ-entity.minZ);
			_boundOffset[0] = offsX = -entity.minX;
			_boundOffset[1] = offsY = -entity.minY;
			_boundOffset[2] = offsZ = -entity.minZ;

			_context.setProgram(_triangleProgram3D);
			_context.clear(0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH);
			_context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, localViewProjection, true);
			_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, _boundOffset, 1);
			_context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 6, _boundScale, 1);
			_context.setVertexBufferAt(0, _hitRenderable.getVertexBuffer(_context, _contextIndex), 0, Context3DVertexBufferFormat.FLOAT_3);
			_context.drawTriangles(_hitRenderable.getIndexBuffer(_context, _contextIndex), 0, _hitRenderable.numTriangles);
			_context.drawToBitmapData(_bitmapData);

			col = _bitmapData.getPixel(0, 0);

			_localHitPosition.x = ((col >> 16) & 0xff)/(scX*255) - offsX;
			_localHitPosition.y = ((col >> 8) & 0xff)/(scY*255) - offsY;
			_localHitPosition.z = (col & 0xff)/(scZ*255) - offsZ;
		}

		/**
		 * Use the approximate position info to find the face under the mouse position from which we can derive the precise
		 * ray-face intersection point, then use barycentric coordinates to figure out the uv coordinates, etc.
		 * @param camera The camera used to view the hit object.
		 */
		private function getPreciseDetails(camera : Camera3D) : void
		{
			var subGeom : SubGeometry = SubMesh(_hitRenderable).subGeometry;
			var indices : Vector.<uint> = subGeom.indexData;
			var vertices : Vector.<Number> = subGeom.vertexData;
			var len : int = indices.length;
			var x1 : Number, y1 : Number, z1 : Number;
			var x2 : Number, y2 : Number, z2 : Number;
			var x3 : Number, y3 : Number, z3 : Number;
			var i : uint = 0, j : uint = 1, k : uint = 2;
			var t1 : uint, t2 : uint, t3 : uint;
			var v0x : Number, v0y : Number, v0z : Number;
			var v1x : Number, v1y : Number, v1z : Number;
			var v2x : Number, v2y : Number, v2z : Number;
			var dot00 : Number, dot01 : Number, dot02 : Number, dot11 : Number, dot12 : Number;
			var s : Number, t : Number, invDenom : Number;
			var uvs : Vector.<Number> = subGeom.UVData;
			var normals : Vector.<Number> = subGeom.faceNormalsData;
			var x : Number = _localHitPosition.x, y : Number = _localHitPosition.y, z : Number = _localHitPosition.z;
			var u : Number, v : Number;
			var ui1 : uint, ui2 : uint, ui3 : uint;

			_hitUV = new Point();

			while (i < len) {
				t1 = indices[i]*3;
				t2 = indices[j]*3;
				t3 = indices[k]*3;
				x1 = vertices[t1];	y1 = vertices[t1+1];	z1 = vertices[t1+2];
				x2 = vertices[t2];	y2 = vertices[t2+1];	z2 = vertices[t2+2];
				x3 = vertices[t3];	y3 = vertices[t3+1];	z3 = vertices[t3+2];

				// if within bounds
				if (!(	(x < x1 && x < x2 && x < x3) ||
						(y < y1 && y < y2 && y < y3) ||
						(z < z1 && z < z2 && z < z3) ||
						(x > x1 && x > x2 && x > x3) ||
						(y > y1 && y > y2 && y > y3) ||
						(z > z1 && z > z2 && z > z3))) {

					// calculate barycentric coords for approximated position
					v0x = x3 - x1; v0y = y3 - y1; v0z = z3 - z1;
					v1x = x2 - x1; v1y = y2 - y1; v1z = z2 - z1;
					v2x = x - x1; v2y = y - y1; v2z = z - z1;
					dot00 = v0x*v0x + v0y*v0y + v0z*v0z;
					dot01 = v0x*v1x + v0y*v1y + v0z*v1z;
					dot02 = v0x*v2x + v0y*v2y + v0z*v2z;
					dot11 = v1x*v1x + v1y*v1y + v1z*v1z;
					dot12 = v1x*v2x + v1y*v2y + v1z*v2z;
					invDenom = 1/(dot00*dot11 - dot01*dot01);
					s = (dot11*dot02 - dot01*dot12)*invDenom;
					t = (dot00*dot12 - dot01*dot02)*invDenom;

					// if inside the current triangle, fetch details hit information
					if (s >= 0 && t >= 0 && (s + t) <= 1) {

						// this is def the triangle, now calculate precise coords
						getPrecisePosition(camera, _hitRenderable.inverseSceneTransform, normals[i], normals[i+1], normals[i+2], x1, y1, z1);

						v2x = _localHitPosition.x - x1;
						v2y = _localHitPosition.y - y1;
						v2z = _localHitPosition.z - z1;

						dot02 = v0x*v2x + v0y*v2y + v0z*v2z;
						dot12 = v1x*v2x + v1y*v2y + v1z*v2z;
						s = (dot11*dot02 - dot01*dot12)*invDenom;
						t = (dot00*dot12 - dot01*dot02)*invDenom;

						ui1 = indices[i] << 1;
						ui2 = indices[j] << 1;
						ui3 = indices[k] << 1;

						u = uvs[ui1]; v = uvs[ui1+1];
						_hitUV.x = u + t*(uvs[ui2] - u) + s*(uvs[ui3] - u);
						_hitUV.y = v + t*(uvs[ui2+1] - v) + s*(uvs[ui3+1] - v);

						return;
					}
				}

				i += 3;
				j += 3;
				k += 3;
			}
		}

		/**
		 * Finds the precise hit position by unprojecting the screen coordinate back unto the hit face's plane and
		 * calculating the intersection point.
		 * @param camera The camera used to render the object.
		 * @param invSceneTransform The inverse scene transformation of the hit object.
		 * @param nx The x-coordinate of the face's plane normal.
		 * @param ny The y-coordinate of the face plane normal.
		 * @param nz The z-coordinate of the face plane normal.
		 * @param px The x-coordinate of a point on the face's plane (ie a face vertex)
		 * @param py The y-coordinate of a point on the face's plane (ie a face vertex)
		 * @param pz The z-coordinate of a point on the face's plane (ie a face vertex)
		 */
		private function getPrecisePosition(camera : Camera3D, invSceneTransform : Matrix3D, nx : Number, ny : Number, nz : Number, px : Number, py : Number, pz : Number) : void
		{
			// calculate screen ray and find exact intersection position with triangle
			var rx : Number, ry : Number, rz : Number;
			var ox : Number, oy : Number, oz : Number, ow : Number;
			var t : Number;
			var raw : Vector.<Number>;

			_inverse.copyFrom(camera.lens.matrix);
			_inverse.invert();
			raw = Matrix3DUtils.RAW_DATA_CONTAINER;
			_inverse.copyRawDataTo(raw);

			// unproject projection point, gives ray dir in cam space
			ox = raw[0]*_projX + raw[4]*_projY + raw[12];
			oy = raw[1]*_projX + raw[5]*_projY + raw[13];
			oz = raw[2]*_projX + raw[6]*_projY + raw[14];
			ow = raw[3]*_projX + raw[7]*_projY + raw[15];
			ox /= -ow;
			oy /= -ow;
			oz /= ow;

			// transform ray dir and origin (cam pos) to object space
			_inverse.copyFrom(camera.sceneTransform);
			_inverse.append(invSceneTransform);
			_inverse.copyRawDataTo(raw);
			rx = raw[0]*ox + raw[4]*oy + raw[8]*oz;
			ry = raw[1]*ox + raw[5]*oy + raw[9]*oz;
			rz = raw[2]*ox + raw[6]*oy + raw[10]*oz;

			ox = raw[12];
			oy = raw[13];
			oz = raw[14];

			t = ((px - ox)*nx + (py - oy)*ny + (pz - oz)*nz) / (rx*nx + ry*ny + rz*nz);

			_localHitPosition.x = ox + rx*t;
			_localHitPosition.y = oy + ry*t;
			_localHitPosition.z = oz + rz*t;
		}
	}
}