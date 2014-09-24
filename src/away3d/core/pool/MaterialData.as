package away3d.core.pool
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
	import away3d.materials.MaterialBase;
    import away3d.materials.compilation.ShaderCompilerBase;
    import away3d.materials.passes.IMaterialPass;
	import away3d.materials.passes.MaterialPassBase;

	use namespace arcane;

	public class MaterialData implements IMaterialData
	{
		private var _pool:MaterialDataPool;

		private var _materialPassDataPool:MaterialPassDataPool;

		private var _passes:Vector.<MaterialPassData>;

		public var context:Stage3DProxy;

		public var material:MaterialBase;

		public var renderOrderId:Number;

		public var invalidAnimation:Boolean = true;

		public function MaterialData(pool:MaterialDataPool, context:Stage3DProxy, material:MaterialBase)
		{
			_pool = pool;
			_materialPassDataPool = new MaterialPassDataPool(material);

			this.context = context;
			this.material = material;
		}

		public function getMaterialPass(materialPass:MaterialPassBase, profile:String):MaterialPassData
		{
			var materialPassData:MaterialPassData = this._materialPassDataPool.getItem(materialPass);

			if (!materialPassData.shaderObject) {
				materialPassData.shaderObject = materialPass.createShaderObject(profile);
				materialPassData.invalid = true;
			}

			if (materialPassData.invalid) {
				materialPassData.invalid = false;
				var compiler:ShaderCompilerBase = materialPassData.shaderObject.createCompiler(material, materialPass);
				compiler.compile();

				materialPassData.shadedTarget = compiler.shadedTarget;
				materialPassData.vertexCode = compiler.vertexCode;
				materialPassData.fragmentCode = compiler.fragmentCode;
				materialPassData.postAnimationFragmentCode = compiler.postAnimationFragmentCode;
				materialPassData.key = "";
			}

			return materialPassData;
		}

		public function getMaterialPasses(profile:String):Vector.<MaterialPassData>
		{
			if (_passes == null) {
				var passes:Vector.<IMaterialPass> = material.screenPasses;
				var numPasses:int = passes.length;

				//reset the material passes in MaterialData
				_passes = new Vector.<MaterialPassData>(numPasses);

				//get the shader object for each screen pass and store
				for (var i:int = 0; i < numPasses; i++)
					_passes[i] = getMaterialPass(passes[i], profile);
			}

			return _passes;
		}

		/**
		 *
		 */
		public function dispose():void
		{
			_materialPassDataPool.disposePool();

			_materialPassDataPool = null;

			_pool.disposeItem(material);

			_passes = null;
		}

		/**
		 *
		 */
		public function invalidateMaterial():void
		{
			_passes = null;

			invalidateAnimation();
		}

		/**
		 *
		 */
		public function invalidateAnimation():void
		{
			invalidAnimation = true;
		}
	}
}
