package away3d.materials.passes
{
	import away3d.arcane;
	import away3d.cameras.Camera3D;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.managers.Texture3DProxy;
	import away3d.lights.LightBase;
	import away3d.materials.MaterialBase;
	import away3d.materials.methods.BasicAmbientMethod;
	import away3d.materials.methods.BasicDiffuseMethod;
	import away3d.materials.methods.BasicSpecularMethod;
	import away3d.materials.methods.ColorTransformMethod;
	import away3d.materials.methods.ShadingMethodBase;
	import away3d.materials.utils.ShaderRegisterCache;
	import away3d.materials.utils.ShaderRegisterElement;

	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Vector3D;

	use namespace arcane;

	/**
	 * DefaultScreenPass is a shader pass that uses shader methods to compile a complete program.
	 *
	 * @see away3d.materials.methods.ShadingMethodBase
	 */
	public class DefaultScreenPass extends MaterialPassBase
	{
		private var _normalMapTexture : Texture3DProxy;
		private var _cameraPositionData : Vector.<Number> = Vector.<Number>([0, 0, 0, 1]);
		private var _lightColorData : Vector.<Number>;
		private var _uvTransformData : Vector.<Number>;

		private var _colorTransformMethod : ColorTransformMethod;
		private var _ambientMethod : BasicAmbientMethod;
		private var _shadowMethod : ShadingMethodBase;
		private var _diffuseMethod : BasicDiffuseMethod;
		private var _specularMethod : BasicSpecularMethod;
		private var _methods : Vector.<ShadingMethodBase>;
		private var _registerCache : ShaderRegisterCache;
		private var _vertexCode : String;
		private var _fragmentCode : String;
		private var _projectionDependencies : uint;
		private var _normalDependencies : uint;
		private var _viewDirDependencies : uint;
		private var _uvDependencies : uint;
		private var _globalPosDependencies : uint;
		private var _generateTangents : Boolean;

		// registers
		protected var _uvBufferIndex : int;
		protected var _normalBufferIndex : int;
		protected var _tangentBufferIndex : int;
		protected var _sceneMatrixIndex : int;
		protected var _sceneNormalMatrixIndex : int;
		protected var _lightsColorIndex : int;
		protected var _normalMapIndex : int;
		protected var _cameraPositionIndex : int;
		protected var _uvTransformIndex : int;

		private var _projectionFragmentReg : ShaderRegisterElement;
		private var _normalFragmentReg : ShaderRegisterElement;
		private var _viewDirFragmentReg : ShaderRegisterElement;
		private var _lightDirFragmentRegs : Vector.<ShaderRegisterElement>;
		private var _lightInputIndices : Vector.<uint>;

		private var _normalVarying : ShaderRegisterElement;
		private var _tangentVarying : ShaderRegisterElement;
		private var _bitangentVarying : ShaderRegisterElement;
		private var _uvVaryingReg : ShaderRegisterElement;
		private var _viewDirVaryingReg : ShaderRegisterElement;

		private var _shadedTargetReg : ShaderRegisterElement;
		private var _globalPositionReg : ShaderRegisterElement;
		private var _localPositionRegister : ShaderRegisterElement;
		private var _positionMatrixRegs : Vector.<ShaderRegisterElement>;
		private var _normalInput : ShaderRegisterElement;
		private var _tangentInput : ShaderRegisterElement;
		private var _animatedNormalReg : ShaderRegisterElement;
		private var _animatedTangentReg : ShaderRegisterElement;
		private var _commonsReg : ShaderRegisterElement;
		private var _commonsRegIndex : int;

		private var _commonsData : Vector.<Number> = Vector.<Number>([.5, 0, 0, 1]);

		arcane var _passes : Vector.<MaterialPassBase>;
		arcane var _passesDirty : Boolean;
		private var _animateUVs : Boolean;


		/**
		 * Creates a new DefaultScreenPass objects.
		 */
		public function DefaultScreenPass(material : MaterialBase)
		{
			super();
			_material = material;
			_registerCache = new ShaderRegisterCache();
			_registerCache.vertexConstantOffset = 4;
			_registerCache.vertexAttributesOffset = 1;

			_methods = new Vector.<ShadingMethodBase>();
			_ambientMethod = new BasicAmbientMethod();
			_diffuseMethod = new BasicDiffuseMethod();
			_specularMethod = new BasicSpecularMethod();
			_diffuseMethod.parentPass = _specularMethod.parentPass = this;
		}

		public function get animateUVs() : Boolean
		{
			return _animateUVs;
		}

		public function set animateUVs(value : Boolean) : void
		{
			_animateUVs = value;
			if ((value && !_animateUVs) || (!value && _animateUVs)) invalidateShaderProgram();
			_uvTransformData = value? Vector.<Number>([1, 0, 0, 0, 0, 1, 0, 0]) : null;
		}

		/**
		 * @inheritDoc
		 */
        override public function set mipmap(value : Boolean) : void
		{
			if (_mipmap == value) return;
			super.mipmap = value;
		}

		/**
		 * The ColorTransform object to transform the colour of the material with.
		 */
		public function get colorTransform() : ColorTransform
		{
			return _colorTransformMethod? _colorTransformMethod.colorTransform : null;
		}

		public function set colorTransform(value : ColorTransform) : void
		{
			if (value) {
				colorTransformMethod ||= new ColorTransformMethod();
				_colorTransformMethod.colorTransform = value;
				_colorTransformMethod.parentPass = this;
			}
			else if (!value) {
				_colorTransformMethod.parentPass = null;
				colorTransformMethod = _colorTransformMethod = null;
			}
		}

		/**
		 * @inheritDoc
		 */
		override public function dispose(deep : Boolean) : void
		{
			super.dispose(deep);

			if (_normalMapTexture) _normalMapTexture.dispose(deep);
			_diffuseMethod.dispose(deep);
			if (_shadowMethod) _shadowMethod.dispose(deep);
			_ambientMethod.dispose(deep);
			if (_specularMethod) _specularMethod.dispose(deep);
			if (_colorTransformMethod) _colorTransformMethod.dispose(deep);
			for (var i : int = 0; i < _methods.length; ++i)
				_methods[i].dispose(deep);
		}

		/**
		 * Adds a method to change the material after all lighting is performed.
		 * @param method The method to be added.
		 */
		public function addMethod(method : ShadingMethodBase) : void
		{
			_methods.push(method);
			method.parentPass = this;
			invalidateShaderProgram();
		}

		/**
		 * Inserts a method to change the material after all lighting is performed at the given index.
		 * @param method The method to be added.
		 * @param index The index of the method's occurrence
		 */
		public function addMethodAt(method : ShadingMethodBase, index : int) : void
		{
			_methods.splice(index, 0, method);
			method.parentPass = this;
			invalidateShaderProgram();
		}

		/**
		 * Removes a method from the pass.
		 * @param method The method to be removed.
		 */
		public function removeMethod(method : ShadingMethodBase) : void
		{
			var index : int = _methods.indexOf(method);
			_methods[index].parentPass = null;
			_methods.splice(index, 1);
			invalidateShaderProgram();
		}

		/**
		 * The tangent space normal map to influence the direction of the surface for each texel.
		 */
		public function get normalMap() : Texture3DProxy
		{
			return _normalMapTexture;
		}

		public function set normalMap(value : Texture3DProxy) : void
		{
			if (_normalMapTexture == value) return;
			if (!_normalMapTexture || !value) invalidateShaderProgram();
			_normalMapTexture = value;
			generateTangents = Boolean(value);
		}

		/**
		 * @inheritDoc
		 */
		override public function set lights(value : Vector.<LightBase>) : void
		{
			super.lights = value;
			_lightColorData = new Vector.<Number>(_numLights*8, true);
			invalidateShaderProgram();
		}


		public function get ambientMethod() : BasicAmbientMethod
		{
			return _ambientMethod;
		}

		public function set ambientMethod(value : BasicAmbientMethod) : void
		{
			_ambientMethod.parentPass = null;
			value.copyFrom(_ambientMethod);
			value.parentPass = this;
			_ambientMethod = value;
			invalidateShaderProgram();
		}

		public function get shadowMethod() : ShadingMethodBase
		{
			return _shadowMethod;
		}

		public function set shadowMethod(value : ShadingMethodBase) : void
		{
			if (_shadowMethod) _shadowMethod.parentPass = null;
			if (value) value.parentPass = this;
			_shadowMethod = value;
			invalidateShaderProgram();
		}

		/**
		 * The method to perform diffuse shading.
		 */
		public function get diffuseMethod() : BasicDiffuseMethod
		{
			return _diffuseMethod;
		}

		public function set diffuseMethod(value : BasicDiffuseMethod) : void
		{
			_diffuseMethod.parentPass = null;
			value.copyFrom(_diffuseMethod);
			_diffuseMethod = value;
			_diffuseMethod.parentPass = this;
			invalidateShaderProgram();
		}

		/**
		 * The method to perform specular shading.
		 */
		public function get specularMethod() : BasicSpecularMethod
		{
			return _specularMethod;
		}

		public function set specularMethod(value : BasicSpecularMethod) : void
		{
			if (_specularMethod) {
				_specularMethod.parentPass = null;
				if (value) value.copyFrom(_specularMethod);
			}

			if (value) value.parentPass = this;

			_specularMethod = value;

			invalidateShaderProgram();
		}

		/**
		 * A method for reserved actions such as ColorTransformations.
		 * @private
		 */
		arcane function get colorTransformMethod() : ColorTransformMethod
		{
			return _colorTransformMethod;
		}

		arcane function set colorTransformMethod(value : ColorTransformMethod) : void
		{
			if (_colorTransformMethod == value) return;

			if (_colorTransformMethod) _colorTransformMethod.parentPass = null;

			if (!_colorTransformMethod || !value) invalidateShaderProgram();

			_colorTransformMethod = value;
			if (value) value.parentPass = this;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getVertexCode() : String
		{
			return _vertexCode;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function getFragmentCode() : String
		{
			return _fragmentCode;
		}

		/**
		 * @inheritDoc
		 */
		arcane override function activate(stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			var len : uint = _methods.length;

			super.activate(stage3DProxy, camera);

			if (_commonsRegIndex >= 0) context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _commonsRegIndex, _commonsData, 1);

			_ambientMethod.activate(stage3DProxy);
			if (_shadowMethod) _shadowMethod.activate(stage3DProxy);
			_diffuseMethod.activate(stage3DProxy);
			if (_specularMethod) _specularMethod.activate(stage3DProxy);
			if (_colorTransformMethod) _colorTransformMethod.activate(stage3DProxy);
			for (var i : int = 0; i < len; ++i)
				_methods[i].activate(stage3DProxy);

			if (_normalMapIndex >= 0) stage3DProxy.setTextureAt(_normalMapIndex, _normalMapTexture.getTextureForStage3D(stage3DProxy));

			if (_cameraPositionIndex >= 0) {
				var pos : Vector3D = camera.scenePosition;
				_cameraPositionData[0] = pos.x;
				_cameraPositionData[1] = pos.y;
				_cameraPositionData[2] = pos.z;
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _cameraPositionIndex, _cameraPositionData, 1);
			}
		}

		/**
		 * @inheritDoc
		 */
		arcane override function deactivate(stage3DProxy : Stage3DProxy) : void
		{
			super.deactivate(stage3DProxy);
			var len : uint = _methods.length;

			_ambientMethod.deactivate(stage3DProxy);
			if (_shadowMethod) _shadowMethod.deactivate(stage3DProxy);
			_diffuseMethod.deactivate(stage3DProxy);
			if (_specularMethod) _specularMethod.deactivate(stage3DProxy);
			if (_colorTransformMethod) _colorTransformMethod.deactivate(stage3DProxy);

			for (var i : uint = 0; i < len; ++i)
				if (_methods[i]) _methods[i].deactivate(stage3DProxy);

//			if (_normalMapIndex >= 0) stage3DProxy.setTextureAt(_normalMapIndex, null);
		}

		/**
		 * @inheritDoc
		 */
		arcane override function render(renderable : IRenderable, stage3DProxy : Stage3DProxy, camera : Camera3D) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			if (_uvBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_uvBufferIndex, renderable.getUVBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_2);
			if (_normalBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_normalBufferIndex, renderable.getVertexNormalBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
			if (_tangentBufferIndex >= 0) stage3DProxy.setSimpleVertexBuffer(_tangentBufferIndex, renderable.getVertexTangentBuffer(stage3DProxy), Context3DVertexBufferFormat.FLOAT_3);
			if (_sceneMatrixIndex >= 0) context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _sceneMatrixIndex, renderable.sceneTransform, true);
			if (_sceneNormalMatrixIndex >= 0) context.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, _sceneNormalMatrixIndex, renderable.inverseSceneTransform);

			var uvTransform : Matrix;
			if (_animateUVs) {
				uvTransform = renderable.uvTransform;
				if (uvTransform) {
					_uvTransformData[0] = uvTransform.a; _uvTransformData[1] = uvTransform.b; _uvTransformData[3] = uvTransform.tx;
					_uvTransformData[4] = uvTransform.c; _uvTransformData[5] = uvTransform.d; _uvTransformData[7] = uvTransform.ty;
				}
				else {
					trace ("Warning: animateUVs is set to true with an IRenderable without a uvTransform. Identity matrix assumed.");
					_uvTransformData[0] = 1; _uvTransformData[1] = 0; _uvTransformData[3] = 0;
					_uvTransformData[4] = 0; _uvTransformData[5] = 1; _uvTransformData[7] = 0;
				}
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, _uvTransformIndex, _uvTransformData, 2);
			}

			if (_numLights > 0) {
				var len : uint = lights.length;

				if (len > _numLights)
					len = _numLights;

				updateLights(context);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, _lightsColorIndex, _lightColorData, _numLights*2);
			}

			_ambientMethod.setRenderState(renderable, stage3DProxy, camera, lights);
			if (_shadowMethod) _shadowMethod.setRenderState(renderable, stage3DProxy, camera, lights);
			_diffuseMethod.setRenderState(renderable, stage3DProxy, camera, lights);
			if (_specularMethod) _specularMethod.setRenderState(renderable, stage3DProxy, camera, lights);
			if (_colorTransformMethod) _colorTransformMethod.setRenderState(renderable, stage3DProxy, camera, lights);

			len = _methods.length;
			for (var i : uint = 0; i < len; ++i)
				_methods[i].setRenderState(renderable, stage3DProxy, camera, lights);

			super.render(renderable, stage3DProxy, camera);
		}

		/**
		 * Indicates whether or not vertex tangents should be calculated.
		 * @private
		 */
		arcane function get generateTangents() : Boolean
		{
			return _generateTangents;
		}

		arcane function set generateTangents(value : Boolean) : void
		{
			if (value == _generateTangents) return;
			invalidateShaderProgram();
			_generateTangents = value;
		}

		/**
		 * Marks the shader program as invalid, so it will be recompiled before the next render.
		 */
		arcane override function invalidateShaderProgram() : void
		{
			super.invalidateShaderProgram();
			_passesDirty = true;

			_passes = new Vector.<MaterialPassBase>();
			addPasses(_ambientMethod.passes);
			if (_shadowMethod) addPasses(_shadowMethod.passes);
			addPasses(_diffuseMethod.passes);
			if (_specularMethod) addPasses(_specularMethod.passes);
			if (_colorTransformMethod) addPasses(_colorTransformMethod.passes);
			for (var i : uint = 0; i < _methods.length; ++i) {
				addPasses(_methods[i].passes);
			}
			_material.invalidateDepthShaderProgram();
		}

		/**
		 * @inheritDoc
		 */
		override protected function updateProgram(stage3DProxy : Stage3DProxy, polyOffsetReg : String = null) : void
		{
			reset();

			super.updateProgram(stage3DProxy, polyOffsetReg);
		}

		/**
		 * A helper method that generates standard code for sampling from a texture using the normal uv coordinates.
		 * @param targetReg The register in which to store the sampled colour.
		 * @param inputReg The texture stream register.
		 * @return The fragment code that performs the sampling.
		 */
		protected function getTexSampleCode(targetReg : ShaderRegisterElement, inputReg : ShaderRegisterElement) : String
		{
			var wrap : String = _repeat? "wrap" : "clamp";
			var filter : String;

            if (_smooth) filter = _mipmap ? "linear,miplinear" : "linear";
			else filter = _mipmap ? "nearest,mipnearest" : "nearest";

            return "tex "+targetReg.toString()+", "+_uvVaryingReg.toString()+", "+inputReg.toString()+" <2d,"+filter+","+wrap+">\n";
		}

		/**
		 * Resets the compilation state.
		 */
		private function reset() : void
		{
			_lightDirFragmentRegs = new Vector.<ShaderRegisterElement>(_numLights, true);
			_lightInputIndices = new Vector.<uint>(_numLights, true);

			setMethodProps(_diffuseMethod);
			if (_shadowMethod) setMethodProps(_shadowMethod);
			setMethodProps(_ambientMethod);
			if (_specularMethod) setMethodProps(_specularMethod);
			if (_colorTransformMethod) setMethodProps(_colorTransformMethod);
			for (var i : int = 0; i < _methods.length; ++i)
				setMethodProps(_methods[i]);

			_commonsReg = null;
			_numUsedVertexConstants = 0;
			_numUsedStreams = 1;
			_registerCache.reset();
			_animatableAttributes = ["va0"];
			_targetRegisters = ["vt0"];
			_vertexCode = "";
			_fragmentCode = "";
			_projectedTargetRegister = null;

			_localPositionRegister = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_localPositionRegister, 1);

			compile();

			_numUsedVertexConstants = _registerCache.numUsedVertexConstants;
			_numUsedStreams = _registerCache.numUsedStreams;
			_numUsedTextures = _registerCache.numUsedTextures;
		}

		private function setMethodProps(method : ShadingMethodBase) : void
		{
			method.smooth = _smooth;
			method.repeat = _repeat;
			method.mipmap = _mipmap;
			method.numLights = _numLights;
			method.reset();
		}

		/**
		 * Compiles the actual shader code.
		 */
		private function compile() : void
		{
			calcDependencies();

			if (_projectionDependencies > 0) compileProjCode();
			if (_uvDependencies > 0) compileUVCode();
			if (_normalDependencies > 0) compileNormalCode();
			if (_globalPosDependencies > 0) compileGlobalPositionCode();
			if (_viewDirDependencies > 0) compileViewDirCode();

			setMethodRegs(_diffuseMethod);
			if (_shadowMethod) setMethodRegs(_shadowMethod);
			setMethodRegs(_ambientMethod);
			if (_specularMethod) setMethodRegs(_specularMethod);
			if (_colorTransformMethod) setMethodRegs(_colorTransformMethod);

			for (var i : uint = 0; i < _methods.length; ++i)
				setMethodRegs(_methods[i]);

			if (_numLights > 0) compileLightDirCode();

			_shadedTargetReg = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_shadedTargetReg, 1);

			compileLightingCode();
			compileMethods();

			_fragmentCode += "mov "+_registerCache.fragmentOutputRegister.toString() +", "+ _shadedTargetReg.toString() + "\n";

			_registerCache.removeFragmentTempUsage(_shadedTargetReg);
		}

		private function compileProjCode() : void
		{
			_projectionFragmentReg = _registerCache.getFreeVarying();
			_projectedTargetRegister = _registerCache.getFreeVertexVectorTemp().toString();

			_vertexCode += "mov " + _projectionFragmentReg.toString() +", " + _projectedTargetRegister + "\n";
		}

		private function setMethodRegs(method : ShadingMethodBase) : void
		{
			method.globalPosVertexReg = _globalPositionReg;
			method.normalFragmentReg = _normalFragmentReg;
			method.projectionReg = _projectionFragmentReg;
			method.UVFragmentReg = _uvVaryingReg;
			method.viewDirFragmentReg = _viewDirFragmentReg;
			method.viewDirVaryingReg = _viewDirVaryingReg;
		}

		/**
		 * Adds passes to the list.
		 */
		private function addPasses(passes : Vector.<MaterialPassBase>) : void
		{
			if (!passes) return;

			var len : uint = passes.length;

			for (var i : uint = 0; i < len; ++i) {
				passes[i].material = material;
				_passes.push(passes[i]);
			}
		}

		/**
		 * Calculates register dependencies for commonly used data.
		 */
		private function calcDependencies() : void
		{
			var len : uint;

			_normalDependencies = 0;
			_viewDirDependencies = 0;
			_uvDependencies = 0;
			_globalPosDependencies = 0;

			_uvTransformIndex = -1;
			_normalMapIndex = -1;
			_cameraPositionIndex = -1;
			_commonsRegIndex = -1;
			_uvBufferIndex = -1;
			_normalBufferIndex = -1;
			_tangentBufferIndex = -1;
			_lightsColorIndex = -1;
			_sceneMatrixIndex = -1;
			_sceneNormalMatrixIndex = -1;

			len = _methods.length;

			countMethodDependencies(_diffuseMethod);
			if (_shadowMethod) countMethodDependencies(_shadowMethod);
			countMethodDependencies(_ambientMethod);
			if (_specularMethod) countMethodDependencies(_specularMethod);
			if (_colorTransformMethod) countMethodDependencies(_colorTransformMethod);

			for (var i : uint = 0; i < len; ++i)
				countMethodDependencies(_methods[i]);

			if (_viewDirDependencies > 0) ++_globalPosDependencies;
			for (i = 0; i < _numLights; ++i) {
				if (_lights[i].positionBased)
					++_globalPosDependencies;
			}
			if (_generateTangents && _normalMapTexture) ++_uvDependencies;
		}

		private function countMethodDependencies(method : ShadingMethodBase) : void
		{
			if (method.needsProjection) ++_projectionDependencies;
			if (method.needsGlobalPos) ++_globalPosDependencies;
			if (method.needsNormals) ++_normalDependencies;
			if (method.needsView) ++_viewDirDependencies;
			if (method.needsUV) ++_uvDependencies;
		}


		private function compileGlobalPositionCode() : void
		{
			_globalPositionReg = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_globalPositionReg, _globalPosDependencies);

			_positionMatrixRegs = new Vector.<ShaderRegisterElement>();
			_positionMatrixRegs[0] = _registerCache.getFreeVertexConstant();
			_positionMatrixRegs[1] = _registerCache.getFreeVertexConstant();
			_positionMatrixRegs[2] = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneMatrixIndex = _positionMatrixRegs[0].index;

			_vertexCode += 	"m34 " + _globalPositionReg + ".xyz, " + _localPositionRegister.toString() +", "+ _positionMatrixRegs[0].toString() + "\n" +
							"mov "+_globalPositionReg+".w, "+ _localPositionRegister+".w     \n";
//			_registerCache.removeVertexTempUsage(_localPositionRegister);
		}

		private function compileUVCode() : void
		{
			var uvAttributeReg : ShaderRegisterElement = _registerCache.getFreeVertexAttribute();

			_uvVaryingReg = _registerCache.getFreeVarying();
			_uvBufferIndex = uvAttributeReg.index;
			++_numUsedStreams;

			if (_animateUVs) {
				// a, b, 0, tx
				// c, d, 0, ty
				var uvTransform1 : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
				var uvTransform2 : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
				_uvTransformIndex = uvTransform1.index;

				_vertexCode += 	"dp4 " + _uvVaryingReg+".x, " + uvAttributeReg + ", " + uvTransform1 + "\n" +
                            	"dp4 " + _uvVaryingReg+".y, " + uvAttributeReg + ", " + uvTransform2 + "\n" +
                            	"mov " + _uvVaryingReg+".zw, " + uvAttributeReg+".zw \n";
			}
			else {
				_vertexCode += "mov " + _uvVaryingReg + ", " + uvAttributeReg + "\n";
			}
		}

		private function compileNormalCode() : void
		{
			var normalMatrix : Vector.<ShaderRegisterElement> = new Vector.<ShaderRegisterElement>(3, true);

            _normalFragmentReg = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_normalFragmentReg, _normalDependencies);

			// vertex normals
			++_numUsedStreams;

			_normalInput = _registerCache.getFreeVertexAttribute();
			_normalBufferIndex = _normalInput.index;

			_normalVarying = _registerCache.getFreeVarying();

			_animatedNormalReg = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_animatedNormalReg, 1);
			_animatableAttributes.push(_normalInput.toString());
			_targetRegisters.push(_animatedNormalReg.toString());

			normalMatrix[0] = _registerCache.getFreeVertexConstant();
			normalMatrix[1] = _registerCache.getFreeVertexConstant();
			normalMatrix[2] = _registerCache.getFreeVertexConstant();
			_registerCache.getFreeVertexConstant();
			_sceneNormalMatrixIndex = normalMatrix[0].index;

			if (_generateTangents) {
				// tangent stream required
				++_numUsedStreams;
				compileTangentVertexCode(normalMatrix);
				compileTangentNormalMapFragmentCode();
			}
			else {
				_vertexCode += 	"m33 " + _normalVarying+".xyz, " + _animatedNormalReg+".xyz, " + normalMatrix[0] + "\n" +
								"mov " + _normalVarying+".w, " + _animatedNormalReg+".w	\n";

                _fragmentCode +=    "nrm " + _normalFragmentReg+".xyz, " + _normalVarying+".xyz	\n" +
									"mov " + _normalFragmentReg+".w, " + _normalVarying+".w		\n";
			}

			_registerCache.removeVertexTempUsage(_animatedNormalReg);
		}

		private function compileTangentVertexCode(matrix : Vector.<ShaderRegisterElement>) : void
		{
			var normalTemp : ShaderRegisterElement;
			var tanTemp : ShaderRegisterElement;
			var bitanTemp1 : ShaderRegisterElement;
			var bitanTemp2 : ShaderRegisterElement;

			_tangentVarying = _registerCache.getFreeVarying();
			_bitangentVarying = _registerCache.getFreeVarying();

			_tangentInput = _registerCache.getFreeVertexAttribute();
			_tangentBufferIndex = _tangentInput.index;

			_animatedTangentReg = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(_animatedTangentReg, 1);
			_animatableAttributes.push(_tangentInput.toString());
			_targetRegisters.push(_animatedTangentReg.toString());

			normalTemp = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(normalTemp, 1);

			_vertexCode += 	"m33 " + normalTemp + ".xyz, " + _animatedNormalReg + ".xyz, " + matrix[0].toString() + "\n" +
							"nrm " + normalTemp + ".xyz, " + normalTemp + ".xyz	\n";

			tanTemp = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(tanTemp, 1);

			_vertexCode += 	"m33 " + tanTemp + ".xyz, " + _animatedTangentReg + ".xyz, " + matrix[0].toString() + "\n" +
							"nrm " + tanTemp + ".xyz, " + tanTemp + ".xyz	\n";

			bitanTemp1 = _registerCache.getFreeVertexVectorTemp();
			_registerCache.addVertexTempUsages(bitanTemp1, 1);
			bitanTemp2 = _registerCache.getFreeVertexVectorTemp();

			_vertexCode += 	"mul " + bitanTemp1 + ".xyz, " + normalTemp + ".yzx, " + tanTemp + ".zxy	\n" +
							"mul " + bitanTemp2 + ".xyz, " + normalTemp + ".zxy, " + tanTemp + ".yzx	\n" +
							"sub " + bitanTemp2 + ".xyz, " + bitanTemp1 + ".xyz, " + bitanTemp2 + ".xyz	\n" +

							"mov " + _tangentVarying   +".x, " + tanTemp		+ ".x	\n" +
							"mov " + _tangentVarying   +".y, " + bitanTemp2		+ ".x	\n" +
							"mov " + _tangentVarying   +".z, " + normalTemp  	+ ".x	\n" +
							"mov " + _tangentVarying   +".w, " + _normalInput	+ ".w	\n" +
							"mov " + _bitangentVarying +".x, " + tanTemp		+ ".y	\n" +
							"mov " + _bitangentVarying +".y, " + bitanTemp2		+ ".y	\n" +
							"mov " + _bitangentVarying +".z, " + normalTemp		+ ".y	\n" +
							"mov " + _bitangentVarying +".w, " + _normalInput	+ ".w	\n" +
							"mov " + _normalVarying    +".x, " + tanTemp 		+ ".z	\n" +
							"mov " + _normalVarying    +".y, " + bitanTemp2		+ ".z	\n" +
							"mov " + _normalVarying    +".z, " + normalTemp		+ ".z	\n" +
							"mov " + _normalVarying    +".w, " + _normalInput	+ ".w	\n";

			_registerCache.removeVertexTempUsage(normalTemp);
			_registerCache.removeVertexTempUsage(tanTemp);
			_registerCache.removeVertexTempUsage(bitanTemp1);
			_registerCache.removeVertexTempUsage(_animatedTangentReg);
		}

		private function compileTangentNormalMapFragmentCode() : void
		{
			var t : ShaderRegisterElement;
			var b : ShaderRegisterElement;
			var n : ShaderRegisterElement;
			var normalMap : ShaderRegisterElement;

			createCommons();

			t = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(t, 1);
			b = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(b, 1);
			n = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(n, 1);

			_fragmentCode += 	"nrm " + t + ".xyz, " + _tangentVarying   + ".xyz	\n" +
								"mov " + t + ".w, "   + _tangentVarying   + ".w		\n" +
								"nrm " + t + ".xyz, " + _tangentVarying   + ".xyz	\n" +
								"nrm " + b + ".xyz, " + _bitangentVarying + ".xyz	\n" +
								"nrm " + n + ".xyz, " + _normalVarying    + ".xyz	\n";

			normalMap = _registerCache.getFreeTextureReg();
			_normalMapIndex = normalMap.index;

			var temp : ShaderRegisterElement = _registerCache.getFreeFragmentVectorTemp();
			_fragmentCode += 	getTexSampleCode(temp, normalMap) +
								"sub " + temp				+ ".xyz, " + temp 			+ ".xyz, " + _commonsReg+".xxx	\n" +
								"nrm " + temp 				+ ".xyz, " + temp 			+ ".xyz							\n" +
								"m33 " + _normalFragmentReg	+ ".xyz, " + temp 			+ ".xyz, " + t.toString() + "	\n" +
								"mov " + _normalFragmentReg	+ ".w,   " + _normalVarying + ".w							\n";

//			_fragmentCode += AGAL.mov("oc", _normalFragmentReg+"");

			_registerCache.removeFragmentTempUsage(b);
			_registerCache.removeFragmentTempUsage(t);
			_registerCache.removeFragmentTempUsage(n);
		}

		private function createCommons() : void
		{
			_commonsReg ||= _registerCache.getFreeFragmentConstant();
			_commonsRegIndex = _commonsReg.index;
		}

		private function compileLightDirCode() : void
		{
			var light : LightBase;

			for (var i : int = 0; i < _numLights; ++i) {
				light = _lights[i];

				_vertexCode += light.getVertexCode(_registerCache, _globalPositionReg, this);
				_fragmentCode += light.getFragmentCode(_registerCache, this);

				_lightDirFragmentRegs[i] = light.fragmentDirectionRegister;
				_lightInputIndices[i] = light.shaderConstantIndex;

				if (light.positionBased) _registerCache.removeVertexTempUsage(_globalPositionReg);
			}
		}

		private function compileViewDirCode() : void
		{
			var cameraPositionReg : ShaderRegisterElement = _registerCache.getFreeVertexConstant();
			_viewDirVaryingReg = _registerCache.getFreeVarying();
			_viewDirFragmentReg = _registerCache.getFreeFragmentVectorTemp();
			_registerCache.addFragmentTempUsages(_viewDirFragmentReg, _viewDirDependencies);

			_cameraPositionIndex = cameraPositionReg.index;

			_vertexCode += "sub " + _viewDirVaryingReg.toString() +", " + cameraPositionReg.toString() + ", " + _globalPositionReg + "\n";
			_fragmentCode += 	"nrm " + _viewDirFragmentReg+".xyz, " + _viewDirVaryingReg + ".xyz		\n" +
								"mov " + _viewDirFragmentReg+".w,   " + _viewDirVaryingReg + ".w 		\n";

			_registerCache.removeVertexTempUsage(_globalPositionReg);
		}

		private function compileLightingCode() : void
		{
			var diffuseColorReg : ShaderRegisterElement;
			var specularColorReg : ShaderRegisterElement;
			var shadowReg : ShaderRegisterElement;
			var lightDirReg : ShaderRegisterElement;
			var light : LightBase;

			_vertexCode += _diffuseMethod.getVertexCode(_registerCache);
			_fragmentCode += _diffuseMethod.getFragmentAGALPreLightingCode(_registerCache);

			if (_specularMethod) {
				_vertexCode += _specularMethod.getVertexCode(_registerCache);
				_fragmentCode += _specularMethod.getFragmentAGALPreLightingCode(_registerCache);
			}

			for (var i : uint = 0; i < _numLights; ++i) {
				light = _lights[i];
				diffuseColorReg = _registerCache.getFreeFragmentConstant();
				specularColorReg = _registerCache.getFreeFragmentConstant();

				if (light.positionBased) {
					lightDirReg = _registerCache.getFreeFragmentVectorTemp();
					_registerCache.addFragmentTempUsages(lightDirReg, 1);
					_fragmentCode += 	"nrm " + lightDirReg + ".xyz, " + _lightDirFragmentRegs[i] + ".xyz	\n" +
										light.getAttenuationCode(_registerCache, lightDirReg, this);
				}
				else lightDirReg = _lightDirFragmentRegs[i];

				if (_lightsColorIndex == -1) _lightsColorIndex = diffuseColorReg.index;
				_fragmentCode += _diffuseMethod.getFragmentCodePerLight(i, lightDirReg, diffuseColorReg, _registerCache);
				if (_specularMethod) _fragmentCode += specularMethod.getFragmentCodePerLight(i, lightDirReg, specularColorReg, _registerCache);

				if (light.positionBased) {
					_registerCache.removeFragmentTempUsage(lightDirReg);
				}
			}

//			_registerCache.removeFragmentTempUsage(lightDirReg);

			_vertexCode += _ambientMethod.getVertexCode(_registerCache);
			_fragmentCode += _ambientMethod.getFragmentPostLightingCode(_registerCache, _shadedTargetReg);

			if (_shadowMethod) {
				_vertexCode += _shadowMethod.getVertexCode(_registerCache);
//				shadowReg = _registerCache.getFreeFragmentSingleTemp();
				// risky :s
				// todo: improve compilation with lifetime analysis so this isn't necessary
				if (_normalDependencies == 0) {
					shadowReg = _registerCache.getFreeFragmentVectorTemp();
					_registerCache.addFragmentTempUsages(shadowReg, 1);
				}
				else
					shadowReg = _normalFragmentReg;

				_diffuseMethod.shadowRegister = shadowReg;
				_fragmentCode += _shadowMethod.getFragmentPostLightingCode(_registerCache, shadowReg);
			}
			_fragmentCode += _diffuseMethod.getFragmentPostLightingCode(_registerCache, _shadedTargetReg);

			if (_diffuseMethod.needsNormals) _registerCache.removeFragmentTempUsage(_normalFragmentReg);
			if (_diffuseMethod.needsView) _registerCache.removeFragmentTempUsage(_viewDirFragmentReg);

			if (_specularMethod) {
				_specularMethod.shadowRegister = shadowReg;
				_fragmentCode += _specularMethod.getFragmentPostLightingCode(_registerCache, _shadedTargetReg);
				if (_specularMethod.needsNormals) _registerCache.removeFragmentTempUsage(_normalFragmentReg);
				if (_specularMethod.needsView) _registerCache.removeFragmentTempUsage(_viewDirFragmentReg);
			}

			if (shadowReg && _normalDependencies > 0) _registerCache.removeFragmentTempUsage(shadowReg);
		}

		private function compileMethods() : void
		{
			var numMethods : uint = _methods.length;

			for (var i : uint = 0; i < numMethods; ++i) {
				_vertexCode += _methods[i].getVertexCode(_registerCache);
				if (_methods[i].needsGlobalPos) _registerCache.removeVertexTempUsage(_globalPositionReg);

				_fragmentCode += _methods[i].getFragmentPostLightingCode(_registerCache, _shadedTargetReg);
				if (_methods[i].needsNormals) _registerCache.removeFragmentTempUsage(_normalFragmentReg);
				if (_methods[i].needsView) _registerCache.removeFragmentTempUsage(_viewDirFragmentReg);
			}

			if (_colorTransformMethod) {
				_vertexCode += _colorTransformMethod.getVertexCode(_registerCache);
				_fragmentCode += _colorTransformMethod.getFragmentPostLightingCode(_registerCache, _shadedTargetReg);
			}
		}

		/**
		 * Updates the lights data for the render state.
		 * @param lights The lights selected to shade the current object.
		 * @param numLights The amount of lights available.
		 * @param maxLights The maximum amount of lights supported.
		 */
		private function updateLights(context : Context3D) : void
		{
			var light : LightBase;
			var i : uint, k : uint;
			var spec : BasicSpecularMethod = specularMethod;

			// update vertex data
			for (i = 0; i < _numLights; ++i) {
				light = _lights[i];
				light.setRenderState(context, _lightInputIndices[i], this);

				_lightColorData[k++] = light._diffuseR;
				_lightColorData[k++] = light._diffuseG;
				_lightColorData[k++] = light._diffuseB;
				_lightColorData[k++] = 1;

				if (spec) {
					_lightColorData[k++] = light._specularR * spec._specularR;
					_lightColorData[k++] = light._specularG * spec._specularG;
					_lightColorData[k++] = light._specularB * spec._specularB;
				}
				else {
					_lightColorData[k++] = 0;
					_lightColorData[k++] = 0;
					_lightColorData[k++] = 0;
				}

				_lightColorData[k++] = 1;
			}
		}
	}
}