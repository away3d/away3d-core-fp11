package away3d.materials.compilation
{
	import away3d.animators.AnimatorBase;
	import away3d.animators.data.AnimationRegisterCache;
	import away3d.arcane;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.pool.RenderableBase;
	import away3d.entities.Camera3D;
	import away3d.managers.Stage3DProxy;
	import away3d.materials.MaterialBase;
    import away3d.materials.passes.IMaterialPass;
    import away3d.materials.passes.MaterialPassBase;
    import away3d.textures.Texture2DBase;

	import flash.display3D.Context3D;

	import flash.display3D.Context3DTriangleFace;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;

	use namespace arcane;

	public class ShaderObjectBase
	{
		private var _defaultCulling:String = Context3DTriangleFace.BACK;

		protected var _inverseSceneMatrix:Vector.<Number> = new Vector.<Number>();

		public var animationRegisterCache:AnimationRegisterCache;

		public var profile:String;

		/**
		 * The amount of used vertex constants in the vertex code. Used by the animation code generation to know from which index on registers are available.
		 */
		public var numUsedVertexConstants:Number;

		/**
		 * The amount of used fragment constants in the fragment code. Used by the animation code generation to know from which index on registers are available.
		 */
		public var numUsedFragmentConstants:Number;

		/**
		 * The amount of used vertex streams in the vertex code. Used by the animation code generation to know from which index on streams are available.
		 */
		public var numUsedStreams:Number;

		/**
		 *
		 */
		public var numUsedTextures:Number;

		/**
		 *
		 */
		public var numUsedVaryings:Number;

		public var animatableAttributes:Vector.<String>;
		public var animationTargetRegisters:Vector.<String>;
		public var uvSource:String;
		public var uvTarget:String;

		public var useAlphaPremultiplied:Boolean;
		public var useBothSides:Boolean;
		public var useMipmapping:Boolean;
		public var useSmoothTextures:Boolean;
		public var repeatTextures:Boolean;
		public var usesUVTransform:Boolean;
		public var alphaThreshold:Number;
		public var texture:Texture2DBase;
		public var color:Number;


		//set ambient values to default
		public var ambientR:uint = 0xFF;
		public var ambientG:uint = 0xFF;
		public var ambientB:uint = 0xFF;

		/**
		 * Indicates whether the pass requires any fragment animation code.
		 */
		public var usesFragmentAnimation:Boolean;

		/**
		 * The amount of dependencies on the projected position.
		 */
		public var projectionDependencies:Number;

		/**
		 * The amount of dependencies on the normal vector.
		 */
		public var normalDependencies:Number;

		/**
		 * The amount of dependencies on the view direction.
		 */
		public var viewDirDependencies:Number;

		/**
		 * The amount of dependencies on the primary UV coordinates.
		 */
		public var uvDependencies:Number;

		/**
		 * The amount of dependencies on the secondary UV coordinates.
		 */
		public var secondaryUVDependencies:Number;

		/**
		 * The amount of dependencies on the local position. This can be 0 while hasGlobalPosDependencies is true when
		 * the global position is used as a temporary value (fe to calculate the view direction)
		 */
		public var localPosDependencies:Number;

		/**
		 * The amount of dependencies on the global position. This can be 0 while hasGlobalPosDependencies is true when
		 * the global position is used as a temporary value (fe to calculate the view direction)
		 */
		public var globalPosDependencies:Number;

		/**
		 * The amount of tangent vector dependencies (fragment shader).
		 */
		public var tangentDependencies:Number;

		/**
		 *
		 */
		public var outputsNormals:Boolean;

		/**
		 * Indicates whether or not normal calculations are expected in tangent space. This is only the case if no world-space
		 * dependencies exist.
		 */
		public var usesTangentSpace:Boolean;

		/**
		 * Indicates whether or not normal calculations are output in tangent space.
		 */
		public var outputsTangentNormals:Boolean;

		/**
		 * Indicates whether there are any dependencies on the world-space position vector.
		 */
		public var usesGlobalPosFragment:Boolean = false;

		public var vertexConstantData:Vector.<Number> = new Vector.<Number>();
		public var fragmentConstantData:Vector.<Number> = new Vector.<Number>();

		/**
		 * The index for the common data register.
		 */
		public var commonsDataIndex:Number;

		/**
		 * The index for the UV vertex attribute stream.
		 */
		public var uvBufferIndex:Number;

		/**
		 * The index for the secondary UV vertex attribute stream.
		 */
		public var secondaryUVBufferIndex:Number;

		/**
		 * The index for the vertex normal attribute stream.
		 */
		public var normalBufferIndex:Number;

		/**
		 * The index for the vertex tangent attribute stream.
		 */
		public var tangentBufferIndex:Number;

		/**
		 * The index of the vertex constant containing the view matrix.
		 */
		public var viewMatrixIndex:Number;

		/**
		 * The index of the vertex constant containing the scene matrix.
		 */
		public var sceneMatrixIndex:Number;

		/**
		 * The index of the vertex constant containing the uniform scene matrix (the inverse transpose).
		 */
		public var sceneNormalMatrixIndex:Number;

		/**
		 * The index of the vertex constant containing the camera position.
		 */
		public var cameraPositionIndex:Number;

		/**
		 * The index for the UV transformation matrix vertex constant.
		 */
		public var uvTransformIndex:Number;

		/**
		 * Creates a new MethodCompilerVO object.
		 */
		public function ShaderObjectBase(profile:String)
		{
			this.profile = profile;
		}

		/**
		 * Factory method to create a concrete compiler object for this object
		 *
		 * @param materialPassVO
		 * @returns {away.materials.ShaderCompilerBase}
		 */
		public function createCompiler(material:MaterialBase, materialPass:IMaterialPass):ShaderCompilerBase
		{
			return new ShaderCompilerBase(material, materialPass, this);
		}

		/**
		 * Clears dependency counts for all registers. Called when recompiling a pass.
		 */
		public function reset():void
		{
			projectionDependencies = 0;
			normalDependencies = 0;
			viewDirDependencies = 0;
			uvDependencies = 0;
			secondaryUVDependencies = 0;
			globalPosDependencies = 0;
			tangentDependencies = 0;
			usesGlobalPosFragment = false;
			usesFragmentAnimation = false;
			usesTangentSpace = false;
			outputsNormals = false;
			outputsTangentNormals = false;
		}

		/**
		 * Adds any external world space dependencies, used to force world space calculations.
		 */
		public function addWorldSpaceDependencies(fragmentLights:Boolean):void
		{
			if (viewDirDependencies > 0)
				++globalPosDependencies;
		}

		public function initRegisterIndices():void
		{
			commonsDataIndex = -1;
			cameraPositionIndex = -1;
			uvBufferIndex = -1;
			uvTransformIndex = -1;
			secondaryUVBufferIndex = -1;
			normalBufferIndex = -1;
			tangentBufferIndex = -1;
			sceneMatrixIndex = -1;
			sceneNormalMatrixIndex = -1;
		}

		/**
		 * Initializes the unchanging constant data for this shader object.
		 */
		public function initConstantData(registerCache:ShaderRegisterCache, animatableAttributes:Vector.<String>, animationTargetRegisters:Vector.<String>, uvSource:String, uvTarget:String):void
		{
			//Updates the amount of used register indices.
			numUsedVertexConstants = registerCache.numUsedVertexConstants;
			numUsedFragmentConstants = registerCache.numUsedFragmentConstants;
			numUsedStreams = registerCache.numUsedStreams;
			numUsedTextures = registerCache.numUsedTextures;
			numUsedVaryings = registerCache.numUsedVaryings;
			numUsedFragmentConstants = registerCache.numUsedFragmentConstants;

			this.animatableAttributes = animatableAttributes;
			this.animationTargetRegisters = animationTargetRegisters;
			this.uvSource = uvSource;
			this.uvTarget = uvTarget;

			vertexConstantData.length = numUsedVertexConstants * 4;
			fragmentConstantData.length = numUsedFragmentConstants * 4;

			//Initializes commonly required constant values.
			fragmentConstantData[commonsDataIndex] = .5;
			fragmentConstantData[commonsDataIndex + 1] = 0;
			fragmentConstantData[commonsDataIndex + 2] = 1 / 255;
			fragmentConstantData[commonsDataIndex + 3] = 1;

			//Initializes the default UV transformation matrix.
			if (uvTransformIndex >= 0) {
				vertexConstantData[uvTransformIndex] = 1;
				vertexConstantData[uvTransformIndex + 1] = 0;
				vertexConstantData[uvTransformIndex + 2] = 0;
				vertexConstantData[uvTransformIndex + 3] = 0;
				vertexConstantData[uvTransformIndex + 4] = 0;
				vertexConstantData[uvTransformIndex + 5] = 1;
				vertexConstantData[uvTransformIndex + 6] = 0;
				vertexConstantData[uvTransformIndex + 7] = 0;
			}

			if (cameraPositionIndex >= 0)
				vertexConstantData[cameraPositionIndex + 3] = 1;
		}


		/**
		 * @inheritDoc
		 */
		arcane function activate(stage3DProxy:Stage3DProxy, camera:Camera3D):void
		{
			stage3DProxy.context3D.setCulling(useBothSides ? Context3DTriangleFace.NONE : _defaultCulling);

			if (!usesTangentSpace && cameraPositionIndex >= 0) {
				var pos:Vector3D = camera.scenePosition;

				vertexConstantData[cameraPositionIndex] = pos.x;
				vertexConstantData[cameraPositionIndex + 1] = pos.y;
				vertexConstantData[cameraPositionIndex + 2] = pos.z;
			}
		}

		/**
		 * @inheritDoc
		 */
		arcane function deactivate(stage:Stage3DProxy):void
		{

		}

		public function setRenderState(renderable:RenderableBase, stage:Stage3DProxy, camera:Camera3D, viewProjection:Matrix3D):void
		{
			if (renderable.materialOwner.animator)
				(renderable.materialOwner.animator as AnimatorBase).setRenderState(this, renderable, stage, camera, this.numUsedVertexConstants, this.numUsedStreams);

			if (uvBufferIndex >= 0)
				stage.activateBuffer(uvBufferIndex, renderable.getVertexData(TriangleSubGeometry.UV_DATA), renderable.getVertexOffset(TriangleSubGeometry.UV_DATA), TriangleSubGeometry.UV_FORMAT);

			if (secondaryUVBufferIndex >= 0)
				stage.activateBuffer(secondaryUVBufferIndex, renderable.getVertexData(TriangleSubGeometry.SECONDARY_UV_DATA), renderable.getVertexOffset(TriangleSubGeometry.SECONDARY_UV_DATA), TriangleSubGeometry.SECONDARY_UV_FORMAT);

			if (normalBufferIndex >= 0)
				stage.activateBuffer(normalBufferIndex, renderable.getVertexData(TriangleSubGeometry.NORMAL_DATA), renderable.getVertexOffset(TriangleSubGeometry.NORMAL_DATA), TriangleSubGeometry.NORMAL_FORMAT);

			if (tangentBufferIndex >= 0)
				stage.activateBuffer(tangentBufferIndex, renderable.getVertexData(TriangleSubGeometry.TANGENT_DATA), renderable.getVertexOffset(TriangleSubGeometry.TANGENT_DATA), TriangleSubGeometry.TANGENT_FORMAT);


			if (usesUVTransform) {
				var uvTransform:Matrix = renderable.materialOwner.uvTransform.matrix;

				if (uvTransform) {
					vertexConstantData[uvTransformIndex] = uvTransform.a;
					vertexConstantData[uvTransformIndex + 1] = uvTransform.b;
					vertexConstantData[uvTransformIndex + 3] = uvTransform.tx;
					vertexConstantData[uvTransformIndex + 4] = uvTransform.c;
					vertexConstantData[uvTransformIndex + 5] = uvTransform.d;
					vertexConstantData[uvTransformIndex + 7] = uvTransform.ty;
				} else {
					vertexConstantData[uvTransformIndex] = 1;
					vertexConstantData[uvTransformIndex + 1] = 0;
					vertexConstantData[uvTransformIndex + 3] = 0;
					vertexConstantData[uvTransformIndex + 4] = 0;
					vertexConstantData[uvTransformIndex + 5] = 1;
					vertexConstantData[uvTransformIndex + 7] = 0;
				}
			}

			if (sceneNormalMatrixIndex >= 0)
				renderable.sourceEntity.inverseSceneTransform.copyRawDataTo(vertexConstantData, sceneNormalMatrixIndex, false);

			if (usesTangentSpace && cameraPositionIndex >= 0) {

				renderable.sourceEntity.inverseSceneTransform.copyRawDataTo(_inverseSceneMatrix);
				var pos:Vector3D = camera.scenePosition;
				var x:Number = pos.x;
				var y:Number = pos.y;
				var z:Number = pos.z;

				vertexConstantData[cameraPositionIndex] = _inverseSceneMatrix[0] * x + _inverseSceneMatrix[4] * y + _inverseSceneMatrix[8] * z + _inverseSceneMatrix[12];
				vertexConstantData[cameraPositionIndex + 1] = _inverseSceneMatrix[1] * x + _inverseSceneMatrix[5] * y + _inverseSceneMatrix[9] * z + _inverseSceneMatrix[13];
				vertexConstantData[cameraPositionIndex + 2] = _inverseSceneMatrix[2] * x + _inverseSceneMatrix[6] * y + _inverseSceneMatrix[10] * z + _inverseSceneMatrix[14];
			}
		}

		public function dispose():void
		{
			//TODO uncount associated program data
		}
	}
}
