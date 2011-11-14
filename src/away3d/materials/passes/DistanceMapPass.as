// AGAL CODE CREDITS
//	ADOBE SYSTEMS INCORPORATED
//	Copyright 2011 Adobe Systems Incorporated.All Rights Reserved.
//
//	NOTICE: Adobe permits you to use, modify, and distribute this file
//	in accordance with the terms of the license agreement accompanying it.

package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.lightpickers.LightPickerBase;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class DistanceMapPass extends MaterialPassBase
	{
		private var _fragmentData : Vector.<Number>;
		private var _vertexData : Vector.<Number>;

		// to do: accept alpha mask
		public function DistanceMapPass()
		{
			super();
			_fragmentData = Vector.<Number>([	1.0, 255.0, 65025.0, 16581375.0,
												1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0,0.0]);
			_vertexData = new Vector.<Number>(4, true);
			_vertexData[3] = 1;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			return	"m44 vt1, vt0, vc4\n" +
					"sub v0, vt1, vc8\n";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			// squared distance to view
			return 	"dp3 ft2.z, v0.xyz, v0.xyz	\n" +
					"mul ft0, fc0, ft2.z	\n" +
					"frc ft0, ft0			\n" +
					"mul ft1, ft0.yzww, fc1	\n" +
					"sub oc, ft0, ft1		\n";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D, lightPicker : LightPickerBase) : void
		{
			var pos : Vector3D = camera.scenePosition;

			_vertexData[0] = pos.x;
			_vertexData[1] = pos.y;
			_vertexData[2] = pos.z;
			_vertexData[3] = 1;

			stage3DProxy._context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 4, renderable.sceneTransform, true);
			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 8, _vertexData, 1);

			super.render(renderable, stage3DProxy, camera, lightPicker);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			super.activate(stage3DProxy, camera);

			var f : Number = camera.lens.far;
			f = 1/(2*f*f);
			// sqrt(f*f+f*f) is largest possible distance for any frustum, so we need to divide by it. Rarely a tight fit, but with 32 bits precision, it's enough.
			_fragmentData[0] = 1*f;
			_fragmentData[1] = 255.0*f;
			_fragmentData[2] = 65025.0*f;
			_fragmentData[3] = 16581375.0*f;


			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentData, 2);
		}


	}
}