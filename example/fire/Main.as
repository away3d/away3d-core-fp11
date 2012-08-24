package
{
	import a3dparticle.ParticlesContainer;
	import away3d.containers.View3D;
	import away3d.debug.AwayStats;
	import away3d.debug.WireframeAxesGrid;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	/**
	 * ...
	 * @author liaocheng.Email:liaocheng210@126.com
	 */
	[SWF(width="1024", height="768", frameRate="60")]
	public class Main extends Sprite 
	{
		protected var _view:View3D;
		
		private var particle:ParticlesContainer;
		
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
			_view.backgroundColor = 0xAAAAAA;
			_view.width = 1024;
			_view.height = 768;
			_view.antiAlias = 4;
			addChild(_view);
			addEventListener(Event.ENTER_FRAME, onRender);
			addChild(new AwayStats(_view));
			new HoverDragController(_view.camera, stage);
			_view.scene.addChild(new WireframeAxesGrid(4,1000));
			initScene();
		}
		
		private function initScene():void
		{
			var fire:Fire = new Fire();
			_view.scene.addChild(fire);
			var smoke:Smoke = new Smoke();
			_view.scene.addChild(smoke);
		}
		
		private function onRender(e:Event):void
		{
			_view.render();
		}
		private function onStageResize(e:Event):void
		{
			_view.width = stage.stageWidth;
			_view.height = stage.stageHeight;
		}
		
	}
	
}