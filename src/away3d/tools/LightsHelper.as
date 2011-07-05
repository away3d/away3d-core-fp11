package away3d.tools
{
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.SubMesh;
	import away3d.entities.Mesh;
	import away3d.lights.LightBase;

	/**
	* Helper Class for the LightBase objects <code>LightsHelper</code>
	* A series of methods to ease work with LightBase objects 
	*/
	 
	public class LightsHelper {
		
		private static var _lightsArray:Array;
		private static var _light:LightBase;
		private static var _state:uint;
		
		/**
		* Applys a series of lights to all materials found into an objectcontainer and its children.
		* The lights eventually set previously are replaced by the new ones.
		* @param	 objectContainer3D 	ObjectContainer3D. The target ObjectContainer3D object to be inspected.
		* @param	 lights						Vector.<LightBase>. A series of lights to be set to all materials found during parsing of the target ObjectContainer3D.
		*/
		public static function addLightsToMaterials(objectContainer3D:ObjectContainer3D, lights:Vector.<LightBase> ):void
		{
			if(lights.length == 0)
				return;
				
			_lightsArray = [];

			for(var i:uint = 0;i<lights.length;++i)
				_lightsArray.push(lights[i]);
			
			_state = 0;
			parseContainer(objectContainer3D);
			_lightsArray = null;
		}
		
		/**
		* Adds one light to all materials found into an objectcontainer and its children.
		* The lights eventually set previously on a material are kept unchanged. The new light is added to the lights array of the materials found during parsing.
		* @param	 objectContainer3D 	ObjectContainer3D. The target ObjectContainer3D object to be inspected.
		* @param	 light							LightBase. The light to add to all materials found during the parsing of the target ObjectContainer3D.
		*/
		public static function addLightToMaterials(objectContainer3D:ObjectContainer3D, light:LightBase):void
		{
			parse(objectContainer3D, light, 1);
		}
		
		/**
		* Removes a given light from all materials found into an objectcontainer and its children.
		* @param	 objectContainer3D 	ObjectContainer3D. The target ObjectContainer3D object to be inspected.
		* @param	 light							LightBase. The light to be removed from all materials found during the parsing of the target ObjectContainer3D.
		*/
		public static function removeLightFromMaterials(objectContainer3D:ObjectContainer3D, light:LightBase):void
		{
			parse(objectContainer3D, light, 2);
		}
		
		
		private static function parse(objectContainer3D:ObjectContainer3D, light:LightBase, id:uint):void
		{
			_light = light;
			if(!_light) return;
			_state = id;
			parseContainer(objectContainer3D);
		}
		
		private static function parseContainer(objectContainer3D:ObjectContainer3D):void
		{
			if(objectContainer3D is Mesh && objectContainer3D.numChildren == 0)
				parseMesh(Mesh(objectContainer3D));
				 
			for(var i:uint = 0;i<objectContainer3D.numChildren;++i)
				parseContainer(ObjectContainer3D(objectContainer3D.getChildAt(i) ) );
		}
		
		private static function parseMesh(mesh:Mesh):void
		{
			var hasLight:Boolean;
			var i :uint;
			var j :uint;
			var aLights:Array;
			
			if(mesh.material){
				switch(_state){
					case 0:
						mesh.material.lights = _lightsArray;
						break;
						
					case 1:
						aLights = mesh.material.lights;
						if(aLights && aLights.length> 0){
							for (i = 0; i<aLights.length; ++i){
								if(aLights[i] == _light){
									hasLight = true;
									break;
								}
							}

							if(!hasLight) {
								aLights.push(_light);
								mesh.material.lights = aLights;
							} else {
								hasLight = false;
								break;
							}
							
							
						} else {
							mesh.material.lights = [_light];
						}
						
						break;
						
					case 2:
						aLights = mesh.material.lights;
						if(aLights){
							for (i = 0; i<aLights.length; ++i){
								if(aLights[i] == _light){
									aLights.splice(i, 1);
									mesh.material.lights = aLights;
									break;
								}
							}
						}
				}
			}
				
			var subMeshes:Vector.<SubMesh> = mesh.subMeshes;
			var subMesh:SubMesh;
			for (i = 0; i<subMeshes.length; ++i){
				subMesh = subMeshes[i];
				if(subMesh.material){
					switch(_state){
						case 0:
							if(subMesh.material.lights !=_lightsArray )
								subMesh.material.lights = _lightsArray;
							break;
							
						case 1:
							aLights = subMesh.material.lights;
							
							if(aLights && aLights.length> 0){
								for (j = 0; j<aLights.length; ++j){
									if(aLights[j] == _light){
										hasLight = true;
										break;
									}
								}
								 
								if(!hasLight){
									aLights.push(_light);
									subMesh.material.lights = aLights;
								} else{
									hasLight = false;
									break;
								}
							} else {
								subMesh.material.lights = [_light];
							}
							break;
							
						case 2:
							aLights = subMesh.material.lights;
							if(aLights){
								for (j = 0; j<aLights.length; ++j){
									if(aLights[j] == _light){
										aLights.splice(j, 1);
										subMesh.material.lights = aLights;
										break;
									}
								}
							}
							
					}
					
				}
				
			}
		}
		
	}
}