package away3d.core.pool
{
	import away3d.materials.MaterialBase;
	import away3d.materials.compilation.ShaderObjectBase;
	import away3d.materials.passes.IMaterialPass;
    import away3d.materials.passes.MaterialPassBase;

    public class MaterialPassData implements IMaterialPassData
	{
		private var _pool:MaterialPassDataPool;
		public var material:MaterialBase;
		public var shaderObject:ShaderObjectBase;
		private var _materialPass:MaterialPassBase;
		public var programData:ProgramData;
		public var shadedTarget:String;
		public var vertexCode:String;
		public var postAnimationFragmentCode:String;
		public var fragmentCode:String;
		public var animationVertexCode:String = "";
		public var animationFragmentCode:String = "";
		public var key:String;
		public var invalid:Boolean;
		public var usesAnimation:Boolean;

		public function MaterialPassData(pool:MaterialPassDataPool, material:MaterialBase, materialPass:MaterialPassBase)
		{
			_pool = pool;
			_materialPass = materialPass;
			this.material = material;
		}

		/**
		 *
		 */
		public function dispose():void
		{
			_pool.disposeItem(_materialPass);

			shaderObject.dispose();
			shaderObject = null;

			programData.dispose();
			programData = null;
		}

		/**
		 *
		 */
		public function invalidate():void
		{
			invalid = true;
		}

		public function get materialPass():IMaterialPass
		{
			return _materialPass;
		}

		public function set materialPass(value:IMaterialPass):void
		{
			_materialPass = value as MaterialPassBase;
		}
	}
}
