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

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;

	use namespace arcane;

	public class DepthMapPass extends MaterialPassBase
	{
		private var _enc : Vector.<Number>;

		// to do: accept alpha mask
		public function DepthMapPass()
		{
			super();
			_enc = Vector.<Number>([	1.0, 255.0, 65025.0, 16581375.0,
										1.0 / 255.0, 1.0 / 255.0, 1.0 / 255.0,0.0]);
			_projectedTargetRegister = "vt1";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			return "mov v0, vt1";
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			return 	"div ft2, v0, v0.w		\n" +
					"mul ft0, fc0, ft2.z	\n" +
					"frc ft0, ft0			\n" +
					"mul ft1, ft0.yzww, fc1	\n" +
					"sub oc, ft0, ft1		\n";
		}

		/**
		 * @inheritDoc
		 * todo: keep maps in dictionary per renderable
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			super.render(renderable, stage3DProxy, camera);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			super.activate(stage3DProxy, camera);

			stage3DProxy._context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _enc, 2);
		}

		/**
		 * @inheritDoc
		 */
//		arcane override function deactivate(stage3DProxy : Stage3DProxy, nextUsedStreams : int) : void
//		{
//			super.deactivate(stage3DProxy, nextUsedStreams);
//		}
	}
}