package 
{
	import a3dparticle.ParticlesContainer;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.entities.Mesh;
	import away3d.materials.ColorMaterial;
	import away3d.primitives.PlaneGeometry;
	import away3d.primitives.SphereGeometry;
	import away3d.tools.utils.Drag3D;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.utils.setTimeout;
	/**
	 * ...
	 * @author liaocheng
	 */
	[SWF(width="1024", height="768", frameRate="60")]
	public class Main extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
		private var target:Vector3D = new Vector3D();
		private var speed:Number = 1;
		private var drag:Drag3D;
		private var object:ObjectContainer3D;
		
		public function Main():void 
		{
			if (stage) setTimeout(init, 0);
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.RESIZE, onStageResize);
			
			// entry point
			_view = new View3D();
			_view.width = 1024;
			_view.height = 768;
			_view.antiAlias = 4;
			_view.backgroundColor = 0x888888;
			_view.camera.y = 400;
			_view.camera.z = -400;
			_view.camera.lookAt(new Vector3D());
			addChild(_view);
			addEventListener(Event.ENTER_FRAME, onRender);
			addEventListener(MouseEvent.CLICK, onMove);
			addChild(new AwayStats(_view));
			initScene();
		}
		
		
		private function onMove(e:Event):void
		{
			target = drag.getIntersect();
		}
		
		private function updateMove():void
		{
			var direction:Vector3D = target.subtract(object.position);
			if (direction.length > speed)
			{
				direction.normalize();
				direction.scaleBy(speed);
				object.position = object.position.add(direction);
			}
			else
			{
				object.position = target;
			}
			
		}
		
		private function initScene():void
		{
			var plane:Mesh = new Mesh(new PlaneGeometry(2000, 2000), new ColorMaterial(0x880000));
			_view.scene.addChild(plane);
			var smoke:Smoke = new Smoke();
			_view.scene.addChild(smoke);
			object = new Mesh(new SphereGeometry(3),new ColorMaterial(0x00ff00));
			_view.scene.addChild(object);
			smoke.target = object;
			drag=new Drag3D(_view);
		}

		private function onRender(e:Event):void
		{
			updateMove();
			_view.render();
		}
		private function onStageResize(e:Event):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
		
	}
	
}