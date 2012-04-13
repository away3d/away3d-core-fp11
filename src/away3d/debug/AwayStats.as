package away3d.debug
{
	import away3d.arcane;
	import away3d.containers.View3D;
	
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	use namespace arcane;

	/**
	 * <p>Stats monitor for Away3D or general use in any project. The widget was designed to
	 * display all the necessary data in ways that are easily readable, while maintaining a
	 * tiny size.</p>
	 * 
	 * <p>The following data is displayed by the widget, either graphically, through
	 * text, or both.</p>
	 * <ul>
	 *   <li>Current frame rate in FPS (white in graph/bar)</li>
	 *   <li>SWF frame rate (Stage.frameRate)</li>
	 *   <li>Average FPS (blue in graph/bar)</li>
	 *   <li>Min/Max FPS (only on frame rate bar in minimized mode)</li>
	 *   <li>Current RAM usage (pink in graph)</li>
	 *   <li>Maximum RAM usage</li>
	 *   <li>Number of polygons in scene</li>
	 *   <li>Number of polygons last rendered (yellow in graph)</li>
	 * </ul> 
	 * 
	 * <p>There are two display modes; standard and minimized, which are alternated by clicking
	 * the button in the upper right corner, at runtime. The widget can also be configured to
	 * start in minimized mode by setting the relevant constructor parameter.</p>
	 * 
	 * <p>All data can be reset at any time, by clicking the lower part of the widget (where
	 * the RAM and POLY counters are located. The average FPS can be reset separately by
	 * clicking it's ²displayed value. Furthermore, the stage frame rate can be increased or
	 * decreased by clicking the upper and lower parts of the graph, respectively. Clicking close
	 * to the center will increment in small values, and further away will increase the steps. 
	 * The graph itself is only visible in standard (as opposed to minimized) display mode.</p>
	 * 
	 * <p>The average FPS is calculated using one of two methods, configurable via constructor
	 * parameters. By setting the meanDataLength to a non-zero value, the number of recorded
	 * frame rate values on which the average is based can be configured. This has a tiny
	 * impact on CPU usage, which is the reason why the default number is zero, denoting that
	 * the average is calculated from a running sum since the widget was last reset.</p>
	 */
	public class AwayStats extends Sprite
	{
		private var _views : Vector.<View3D>;
		private var _timer : Timer;
		private var _last_frame_timestamp : Number;
		
		private var _fps : uint;
		private var _ram : Number;
		private var _max_ram : Number;
		private var _min_fps : uint;
		private var _avg_fps : Number;
		private var _max_fps : uint;
		private var _tfaces : uint;
		private var _rfaces : uint;
		
		private var _num_frames : uint;
		private var _fps_sum : uint;
		
		private var _top_bar : Sprite;
		private var _btm_bar : Sprite;
		private var _btm_bar_hit : Sprite;
		
		private var _data_format : TextFormat;
		private var _label_format : TextFormat;
		
		private var _fps_bar : Shape;
		private var _afps_bar : Shape;
		private var _lfps_bar : Shape;
		private var _hfps_bar : Shape;
		private var _diagram : Sprite;
		private var _dia_bmp : BitmapData;
		
		private var _mem_points : Array;
		private var _mem_graph : Shape;
		private var _updates : int;
		
		private var _min_max_btn : Sprite;
		
		private var _fps_tf : TextField;
		private var _afps_tf : TextField;
		private var _ram_tf : TextField;
		private var _poly_tf : TextField;
		private var _swhw_tf : TextField;
		
		private var _drag_dx : Number;
		private var _drag_dy : Number;
		private var _dragging : Boolean;
		
		private var _mean_data : Array;
		private var _mean_data_length : int;
		
		private var _enable_reset : Boolean;
		private var _enable_mod_fr : Boolean;
		private var _transparent : Boolean;
		private var _minimized : Boolean;
		private var _showing_driv_info : Boolean;
		
		private static const _WIDTH : Number = 125;
		private static const _MAX_HEIGHT : Number = 85;
		private static const _MIN_HEIGHT : Number = 51;
		private static const _UPPER_Y : Number = -1;
		private static const _MID_Y : Number = 9;
		private static const _LOWER_Y : Number = 19;
		private static const _DIAG_HEIGHT : Number = _MAX_HEIGHT - 50;
		private static const _BOTTOM_BAR_HEIGHT : Number = 31;
		
		private static const _POLY_COL : uint = 0xffcc00;
		private static const _MEM_COL : uint = 0xff00cc;
		
		
		// Singleton instance reference
		private static var _INSTANCE : AwayStats;
		
		
		/**
		 * <p>Create an Away3D stats widget. The widget can be added to the stage
		 * and positioned like any other display object. Once on the stage, you
		 * can drag the widget to re-position it at runtime.</p>
		 * 
		 * <p>If you pass a View3D instance, the widget will be able to display
		 * the total number of faces in your scene, and the amount of faces that
		 * were rendered during the last render() call. Views can also be registered
		 * after construction using the registerView() method. Omit the view 
		 * constructor parameter to disable this feature altogether.</p>
		 * 
		 * @param view A reference to your Away3D view. This is required if you
		 * want the stats widget to display polycounts.
		 * 
		 * @param minimized Defines whether the widget should start up in minimized
		 * mode. By default, it is shown in full-size mode on launch.
		 * 
		 * @param transparent Defines whether to omit the background plate and print
		 * statistics directly on top of the underlying stage.
		 * 
		 * @param meanDataLength The number of frames on which to base the average
		 * frame rate calculation. The default value of zero indicates that all
		 * frames since the last reset will be used.
		 * 
		 * @param enableClickToReset Enables interaction allowing you to reset all
		 * counters by clicking the bottom bar of the widget. When activated, you 
		 * can also click the average frame rate trace-out to reset just that one
		 * value.
		 * 
		 * @param enableModifyFramerate When enabled, allows you to click the upper
		 * and lower parts of the graph area to increase and decrease SWF frame rate
		 * respectively.
		 */
		public function AwayStats(view3d : View3D = null, minimized : Boolean = false, transparent : Boolean = false, meanDataLength : uint = 0, enableClickToReset : Boolean = true, enableModifyFrameRate : Boolean = true)
		{
			super();
			
			_minimized = minimized;
			_transparent = transparent;
			_enable_reset = enableClickToReset;
			_enable_mod_fr = enableModifyFrameRate;
			_mean_data_length = meanDataLength;
			
			_views = new Vector.<View3D>();
			if (view3d)
				_views.push(view3d);
			
			
			// Store instance for singleton access. Singleton status
			// is not enforced, since the widget will work anyway.
			if (_INSTANCE) {
				trace('Creating several statistics windows in one project. Is this intentional?');
			}
			_INSTANCE = this;
			
			
			_fps = 0;
			_num_frames = 0;
			_avg_fps = 0;
			_ram = 0;
			_max_ram = 0;
			_tfaces = 0;
			_rfaces = 0;
			
			_init();
		}

		public function get max_ram() : Number
		{
			return _max_ram;
		}

		public function get ram() : Number
		{
			return _ram;
		}

		public function get avg_fps() : Number
		{
			return _avg_fps;
		}

		public function get max_fps() : uint
		{
			return _max_fps;
		}

		public function get fps():int
		{
			return _fps;
		}
		
		private function _init() : void
		{
			_initMisc();
			_initTopBar();
			_initBottomBar();
			_initDiagrams();
			_initInteraction();
			
			reset();
			_redrawWindow();
			
			addEventListener(Event.ADDED_TO_STAGE, _onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, _onRemovedFromStage);
		}
		
		
		
		
		
		
		/**
		 * Holds a reference to the stats widget (or if several have been created
		 * during session, the one that was last instantiated.) Allows you to set
		 * properties and register views from anywhere in your code.
		 */
		public static function get instance() : AwayStats
		{
			return _INSTANCE ? _INSTANCE : _INSTANCE = new AwayStats();
		}
		
		
		
		/**
		 * Add a view to the list of those that are taken into account when
		 * calculating on-screen and total poly counts. Use this method when the
		 * stats widget is not instantiated in the same place as where you create
		 * your view, or when using several views, or when views are created and
		 * destroyed dynamically at runtime.
		 */
		public function registerView(view3d : View3D) : void
		{
			if (view3d && _views.indexOf(view3d)<0)
				_views.push(view3d);
		}
		
		
		/**
		 * Remove a view from the list of those that are taken into account when
		 * calculating on-screen and total poly counts. If the supplied view is
		 * the only one known to the stats widget, calling this will leave the
		 * list empty, disabling poly count statistics altogether.
		 */
		public function unregisterView(view3d : View3D) : void
		{
			if (view3d) {
				var idx : int = _views.indexOf(view3d);
				if (idx >= 0)
					_views.splice(idx, 1);
			}
		}
		
		
		
		
		
		
		private function _initMisc() : void
		{
			_timer = new Timer(200, 0);
			_timer.addEventListener('timer', _onTimer);
			
			_label_format = new TextFormat('_sans', 9, 0xffffff, true);
			_data_format = new TextFormat('_sans', 9, 0xffffff, false);
			
			
			if (_mean_data_length>0) {
				var i : int;
				
				_mean_data = [];
				for (i=0; i<_mean_data_length;i++) {
					_mean_data[i] = 0.0;
				}
			}
		}
		
		
		/**
		 * @private
		 * Draw logo and create title textfield.
		 */
		private function _initTopBar() : void
		{
			var logo : Shape;
			var markers : Shape;
			//var logo_tf : TextField;
			var fps_label_tf : TextField;
			var afps_label_tf : TextField;
			
			_top_bar = new Sprite;
			_top_bar.graphics.beginFill(0, 0);
			_top_bar.graphics.drawRect(0, 0, _WIDTH, 20);
			addChild(_top_bar);
			
			logo = new Shape;
			logo.x = 9;
			logo.y = 7.5;
			logo.scaleX = 0.6;
			logo.scaleY = 0.6;
			logo.graphics.beginFill(0xffffff, 1);
			
			// Left
			logo.graphics.moveTo(-0.5, -7);
			logo.graphics.curveTo(-0.5, -7.7, -1, -7);
			logo.graphics.lineTo(-9, 5);
			logo.graphics.curveTo(-9.3, 5.5, -8, 5);
			logo.graphics.curveTo(-1, 1, -0.5, -7);
			
			// Right
			logo.graphics.moveTo(0.5, -7);
			logo.graphics.curveTo(0.5, -7.7, 1, -7);
			logo.graphics.lineTo(9, 5);
			logo.graphics.curveTo(9.3, 5.5, 8, 5);
			logo.graphics.curveTo(1, 1, 0.5, -7);
			
			// Bottom
			logo.graphics.moveTo(-8, 7);
			logo.graphics.curveTo(-8.3, 6.7, -7.5, 6.3);
			logo.graphics.curveTo(0, 2, 7.5, 6.3);
			logo.graphics.curveTo(8.3, 6.7, 8, 7);
			logo.graphics.lineTo(-8, 7);
			_top_bar.addChild(logo);
			
			
			// Color markers 
			markers = new Shape;
			markers.graphics.beginFill(0xffffff);
			markers.graphics.drawRect(20, 7, 4, 4);
			markers.graphics.beginFill(0x3388dd);
			markers.graphics.drawRect(77, 7, 4, 4);
			_top_bar.addChild(markers);
			
			// CURRENT FPS
			fps_label_tf = new TextField();
			fps_label_tf.defaultTextFormat = _label_format;
			fps_label_tf.autoSize = TextFieldAutoSize.LEFT; 
			fps_label_tf.text = 'FR:';
			fps_label_tf.x = 24;
			fps_label_tf.y = 2;
			fps_label_tf.selectable = false;
			_top_bar.addChild(fps_label_tf);
			
			_fps_tf = new TextField;
			_fps_tf.defaultTextFormat = _data_format;
			_fps_tf.autoSize = TextFieldAutoSize.LEFT;
			_fps_tf.x = fps_label_tf.x + 16;
			_fps_tf.y = fps_label_tf.y;
			_fps_tf.selectable = false;
			_top_bar.addChild(_fps_tf);
			
			// AVG FPS
			afps_label_tf = new TextField;
			afps_label_tf.defaultTextFormat = _label_format;
			afps_label_tf.autoSize = TextFieldAutoSize.LEFT;
			afps_label_tf.text = 'A:';
			afps_label_tf.x = 81;
			afps_label_tf.y = 2;
			afps_label_tf.selectable = false;
			_top_bar.addChild(afps_label_tf);
			
			_afps_tf = new TextField;
			_afps_tf.defaultTextFormat = _data_format;
			_afps_tf.autoSize = TextFieldAutoSize.LEFT;
			_afps_tf.x = afps_label_tf.x + 12;
			_afps_tf.y = afps_label_tf.y;
			_afps_tf.selectable = false;
			_top_bar.addChild(_afps_tf);
			
			// Minimize / maximize button
			_min_max_btn = new Sprite;
			_min_max_btn.x = _WIDTH-8;
			_min_max_btn.y = 7;
			_min_max_btn.graphics.beginFill(0, 0);
			_min_max_btn.graphics.lineStyle(1, 0xefefef, 1, true);
			_min_max_btn.graphics.drawRect(-4, -4, 8, 8);
			_min_max_btn.graphics.moveTo(-3, 2);
			_min_max_btn.graphics.lineTo(3, 2);
			_min_max_btn.buttonMode = true;
			_min_max_btn.addEventListener(MouseEvent.CLICK, _onMinMaxBtnClick);
			_top_bar.addChild(_min_max_btn);
		}
		
		
		private function _initBottomBar() : void
		{
			var markers : Shape;
			var ram_label_tf : TextField;
			var poly_label_tf : TextField;
			var swhw_label_tf : TextField;
			
			_btm_bar = new Sprite();
			_btm_bar.graphics.beginFill(0, 0.2);
			_btm_bar.graphics.drawRect(0, 0, _WIDTH, _BOTTOM_BAR_HEIGHT);
			addChild(_btm_bar);
			
			// Hit area for bottom bar (to avoid having textfields
			// affect interaction badly.)
			_btm_bar_hit = new Sprite;
			_btm_bar_hit.graphics.beginFill(0xffcc00, 0);
			_btm_bar_hit.graphics.drawRect(0, 1, _WIDTH, _BOTTOM_BAR_HEIGHT-1);
			addChild(_btm_bar_hit);
			
			
			// Color markers
			markers = new Shape;
			markers.graphics.beginFill(_MEM_COL);
			markers.graphics.drawRect(5, 4, 4, 4);
			markers.graphics.beginFill(_POLY_COL);
			markers.graphics.drawRect(5, 14, 4, 4);
			_btm_bar.addChild(markers);
			
			// CURRENT RAM
			ram_label_tf = new TextField;
			ram_label_tf.defaultTextFormat = _label_format;
			ram_label_tf.autoSize = TextFieldAutoSize.LEFT;
			ram_label_tf.text = 'RAM:';
			ram_label_tf.x = 10;
			ram_label_tf.y = _UPPER_Y;
			ram_label_tf.selectable = false;
			ram_label_tf.mouseEnabled = false;
			_btm_bar.addChild(ram_label_tf);
			
			_ram_tf = new TextField;
			_ram_tf.defaultTextFormat = _data_format;
			_ram_tf.autoSize = TextFieldAutoSize.LEFT;
			_ram_tf.x = ram_label_tf.x + 31;
			_ram_tf.y = ram_label_tf.y;
			_ram_tf.selectable = false;
			_ram_tf.mouseEnabled = false;
			_btm_bar.addChild(_ram_tf);
			
			// POLY COUNT
			poly_label_tf = new TextField;
			poly_label_tf.defaultTextFormat = _label_format;
			poly_label_tf.autoSize = TextFieldAutoSize.LEFT;
			poly_label_tf.text = 'POLY:';
			poly_label_tf.x = 10;
			poly_label_tf.y = _MID_Y;
			poly_label_tf.selectable = false;
			poly_label_tf.mouseEnabled = false;
			_btm_bar.addChild(poly_label_tf);
			
			_poly_tf = new TextField;
			_poly_tf.defaultTextFormat = _data_format;
			_poly_tf.autoSize = TextFieldAutoSize.LEFT;
			_poly_tf.x = poly_label_tf.x + 31;
			_poly_tf.y = poly_label_tf.y;
			_poly_tf.selectable = false;
			_poly_tf.mouseEnabled = false;
			_btm_bar.addChild(_poly_tf);
			
			// SOFTWARE RENDERER WARNING
			swhw_label_tf = new TextField;
			swhw_label_tf.defaultTextFormat = _label_format;
            swhw_label_tf.autoSize = TextFieldAutoSize.LEFT;
			swhw_label_tf.text = 'DRIV:';
			swhw_label_tf.x = 10;
			swhw_label_tf.y = _LOWER_Y;
			swhw_label_tf.selectable = false;
			swhw_label_tf.mouseEnabled = false;
			_btm_bar.addChild(swhw_label_tf);
			
			_swhw_tf = new TextField;
			_swhw_tf.defaultTextFormat = _data_format;
			_swhw_tf.autoSize = TextFieldAutoSize.LEFT;
			_swhw_tf.x = swhw_label_tf.x + 31;
			_swhw_tf.y = swhw_label_tf.y;
			_swhw_tf.selectable = false;
			_swhw_tf.mouseEnabled = false;
			_btm_bar.addChild(_swhw_tf);
		}
		
		
		private function _initDiagrams() : void
		{
			
			_dia_bmp = new BitmapData(_WIDTH, _DIAG_HEIGHT, true, 0);
			_diagram = new Sprite;
			_diagram.graphics.beginBitmapFill(_dia_bmp);
			_diagram.graphics.drawRect(0, 0, _dia_bmp.width, _dia_bmp.height);
			_diagram.graphics.endFill();
			_diagram.y = 17;
			addChild(_diagram);
			
			_diagram.graphics.lineStyle(1, 0xffffff, 0.03);
			_diagram.graphics.moveTo(0, 0);
			_diagram.graphics.lineTo(_WIDTH, 0);
			_diagram.graphics.moveTo(0, Math.floor(_dia_bmp.height/2));
			_diagram.graphics.lineTo(_WIDTH, Math.floor(_dia_bmp.height/2));
			
			// FRAME RATE BAR
			_fps_bar = new Shape;
			_fps_bar.graphics.beginFill(0xffffff);
			_fps_bar.graphics.drawRect(0, 0, _WIDTH, 4);
			_fps_bar.x = 0;
			_fps_bar.y = 16;
			addChild(_fps_bar);
			
			// AVERAGE FPS
			_afps_bar = new Shape;
			_afps_bar.graphics.lineStyle(1, 0x3388dd, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			_afps_bar.graphics.lineTo(0, 4);
			_afps_bar.y = _fps_bar.y;
			addChild(_afps_bar);
			
			// MINIMUM FPS
			_lfps_bar = new Shape;
			_lfps_bar.graphics.lineStyle(1, 0xff0000, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			_lfps_bar.graphics.lineTo(0, 4);
			_lfps_bar.y = _fps_bar.y;
			addChild(_lfps_bar);
			
			// MAXIMUM FPS
			_hfps_bar = new Shape;
			_hfps_bar.graphics.lineStyle(1, 0x00ff00, 1, false, LineScaleMode.NORMAL, CapsStyle.SQUARE);
			_hfps_bar.graphics.lineTo(0, 4);
			_hfps_bar.y = _fps_bar.y;
			addChild(_hfps_bar);
			
			
			_mem_points = [];
			_mem_graph = new Shape;
			_mem_graph.y = _diagram.y + _diagram.height;
			addChildAt(_mem_graph, 0);
		}
		
		
		
		
		private function _initInteraction() : void
		{
			// Mouse down to drag on the title
			_top_bar.addEventListener(MouseEvent.MOUSE_DOWN, _onTopBarMouseDown);
			
			// Reset functionality
			if (_enable_reset) {
				_btm_bar.mouseEnabled = false;
				_btm_bar_hit.addEventListener(MouseEvent.CLICK, _onCountersClick_reset);
				_afps_tf.addEventListener(MouseEvent.MOUSE_UP, _onAverageFpsClick_reset, false, 1);
			}
			
			// Framerate increase/decrease by clicking on the diagram
			if (_enable_mod_fr) {
				_diagram.addEventListener(MouseEvent.CLICK, _onDiagramClick);
			}
		}
		
		
		
		
		private function _redrawWindow() : void
		{
			var plate_height : Number;
			
			plate_height = _minimized? _MIN_HEIGHT : _MAX_HEIGHT;
			
			// Main plate
			if (!_transparent) {
				this.graphics.clear();
				this.graphics.beginFill(0, 0.6);
				this.graphics.drawRect(0, 0, _WIDTH, plate_height);
			}
			
			// Minimize/maximize button
			_min_max_btn.rotation = _minimized? 180 : 0;
			
			// Position counters
			_btm_bar.y = plate_height-_BOTTOM_BAR_HEIGHT;
			_btm_bar_hit.y = _btm_bar.y;
			
			// Hide/show diagram for minimized/maximized view respectively
			_diagram.visible = !_minimized;
			_mem_graph.visible = !_minimized;
			_fps_bar.visible = _minimized;
			_afps_bar.visible = _minimized;
			_lfps_bar.visible = _minimized;
			_hfps_bar.visible = _minimized;
			
			// Redraw memory graph
			if (!_minimized)
				_redrawMemGraph();
		}
		
		
		private function _redrawStats() : void
		{
			var dia_y : int;
			
			// Redraw counters
			_fps_tf.text = _fps.toString().concat('/', int(stage.frameRate));
			_afps_tf.text = Math.round(_avg_fps).toString();
			_ram_tf.text = _getRamString(_ram).concat(' / ', _getRamString(_max_ram));
			
			
			// Move entire diagram
			_dia_bmp.scroll(1, 0);
			
			
			// Only redraw polycount if there is a  view available
			// or they won't have been calculated properly
			if (_views.length > 0) {
//				_poly_tf.text = _rfaces.toString().concat(' / ', _tfaces); // TODO: Total faces not yet available in 4.x
				_poly_tf.text = _rfaces + "";

				// Plot rendered faces
				dia_y = _dia_bmp.height - Math.floor(_rfaces/_tfaces * _dia_bmp.height);
				_dia_bmp.setPixel32(1, dia_y, _POLY_COL+0xff000000);
			}
			else {
				_poly_tf.text = 'n/a (no view)';
			}
			
			// Show software (SW) or hardware (HW)
			if (!_showing_driv_info) {
				if (_views && _views.length && _views[0].renderer.stage3DProxy && _views[0].renderer.stage3DProxy.context3D) {
					var di : String = _views[0].renderer.stage3DProxy.context3D.driverInfo;
					_swhw_tf.text = di.substr(0, di.indexOf(' '));
					_showing_driv_info = true;
				}
				else {
					_swhw_tf.text = 'n/a (no view)';
				}
			}
			
			// Plot current framerate
			dia_y = _dia_bmp.height - Math.floor(_fps/stage.frameRate * _dia_bmp.height);
			_dia_bmp.setPixel32(1, dia_y, 0xffffffff);
			
			// Plot average framerate
			dia_y = _dia_bmp.height - Math.floor(_avg_fps/stage.frameRate * _dia_bmp.height);
			_dia_bmp.setPixel32(1, dia_y, 0xff33bbff);
			
			
			// Redraw diagrams
			if (_minimized) {
				_fps_bar.scaleX = Math.min(1, _fps/stage.frameRate);
				_afps_bar.x = Math.min(1, _avg_fps/stage.frameRate) * _WIDTH;
				_lfps_bar.x = Math.min(1, _min_fps/stage.frameRate) * _WIDTH;
				_hfps_bar.x = Math.min(1, _max_fps/stage.frameRate) * _WIDTH;
			}
			else if (_updates%5 == 0) {
				_redrawMemGraph();
			}
			
			// Move along regardless of whether the graph
			// was updated this time around
			_mem_graph.x = _updates%5;
			
			_updates++;
		}
		
		
		private function _redrawMemGraph() : void
		{
			var i : int;
			var g : Graphics;
			var max_val : Number = 0;
			
			// Redraw memory graph (only every 5th update)
			_mem_graph.scaleY = 1;
			g = _mem_graph.graphics;
			g.clear();
			g.lineStyle(.5, _MEM_COL, 1, true, LineScaleMode.NONE);
			g.moveTo(5*(_mem_points.length-1), -_mem_points[_mem_points.length-1]);
			for (i=_mem_points.length-1; i>=0; --i) {
				if (_mem_points[i+1]==0 || _mem_points[i]==0) {
					g.moveTo(i*5, -_mem_points[i]);
					continue;
				}
				
				g.lineTo(i*5, -_mem_points[i]);
				
				if (_mem_points[i] > max_val)
					max_val = _mem_points[i];
			}
			_mem_graph.scaleY = _dia_bmp.height / max_val;
		}
		
		
		private function _getRamString(ram : Number) : String
		{
			var ram_unit : String = 'B';
			
			if (ram > 1048576) {
				ram /= 1048576;
				ram_unit = 'M'; 
			}
			else if (ram > 1024) {
				ram /= 1024;
				ram_unit = 'K'; 
			}
			
			return ram.toFixed(1) + ram_unit;
		}
		
		
		
		public function reset() : void
		{
			var i : int;
			
			// Reset all values
			_updates = 0;
			_num_frames = 0;
			_min_fps = int.MAX_VALUE;
			_max_fps = 0;
			_avg_fps = 0;
			_fps_sum = 0;
			_max_ram = 0;
			
			// Reset RAM usage log
			for (i=0; i<_WIDTH/5; i++) {
				_mem_points[i]=0;
			}
			
			// Reset FPS log if any
			if (_mean_data) {
				for (i=0; i<_mean_data.length; i++) {
					_mean_data[i] = 0.0;
				}
			}
			
			
			
			// Clear diagram graphics
			_mem_graph.graphics.clear();
			_dia_bmp.fillRect(_dia_bmp.rect, 0);
		}
		
		
		private function _endDrag() : void
		{
			if (this.x < -_WIDTH)
				this.x = -(_WIDTH-20);
			else if (this.x > stage.stageWidth)
				this.x = stage.stageWidth - 20;
			
			if (this.y < 0)
				this.y = 0;
			else if (this.y > stage.stageHeight)
				this.y = stage.stageHeight - 15;
			
			// Round x/y position to make sure it's on
			// whole pixels to avoid weird anti-aliasing
			this.x = Math.round(this.x);
			this.y = Math.round(this.y);
			
			
			_dragging = false; 
			stage.removeEventListener(Event.MOUSE_LEAVE, _onMouseUpOrLeave);
			stage.removeEventListener(MouseEvent.MOUSE_UP, _onMouseUpOrLeave);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
		}
		
		
		private function _onAddedToStage(ev : Event) : void
		{
			_timer.start();
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		}
		
		private function _onRemovedFromStage(ev : Event) : void
		{
			_timer.stop();
			removeEventListener(Event.ENTER_FRAME, _onTimer);
		}
		
		private function _onTimer(ev : Event) : void
		{
			// Store current and max RAM
			_ram = System.totalMemory;
			if (_ram > _max_ram)
				_max_ram = _ram;
			
			// Remove first, add last
			if (_updates%5 == 0) {
				_mem_points.unshift(_ram/1024);
				_mem_points.pop();
			}
			
			_tfaces = _rfaces = 0;
			
			// Update polycount if views are available
			if (_views.length > 0) {
				var i : int;
				
				
				// Sum up poly counts across all registered views
				for (i=0; i<_views.length; i++) {
					_rfaces += _views[i].renderedFacesCount;
					//_tfaces += 0;// TODO: total faces
				}
			}
			
			_redrawStats();
		}
		
		
		private function _onEnterFrame(ev : Event) : void
		{
			var time : Number = getTimer() - _last_frame_timestamp;
			
			// Calculate current FPS
			_fps = Math.floor(1000/time);
			_fps_sum += _fps;
			
			// Update min/max fps
			if (_fps > _max_fps)
				_max_fps = _fps;
			else if (_fps!=0 && _fps < _min_fps)
				_min_fps = _fps;
			
			// If using a limited length log of frames
			// for the average, push the latest recorded
			// framerate onto fifo, shift one off and
			// subtract it from the running sum, to keep
			// the sum reflecting the log entries.
			if (_mean_data) {
				_mean_data.push(_fps);
				_fps_sum -= Number(_mean_data.shift());
				
				// Average = sum of all log entries over
				// number of log entries.
				_avg_fps = _fps_sum/_mean_data_length;
			}
			else {
				// Regular average calculation, i.e. using
				// a running sum since last reset
				_num_frames++;
				_avg_fps = _fps_sum/_num_frames;
			}
			
			_last_frame_timestamp = getTimer();
		}
		
		
		private function _onDiagramClick(ev : MouseEvent) : void
		{
			stage.frameRate -= Math.floor((_diagram.mouseY - _dia_bmp.height/2) / 5);
		}
		
		/**
		 * @private
		 * Reset just the average FPS counter.
		 */
		private function _onAverageFpsClick_reset(ev : MouseEvent) : void
		{
			if (!_dragging) {
				var i : int;
				
				_num_frames = 0;
				_fps_sum = 0;
				
				if (_mean_data) {
					for (i=0; i<_mean_data.length; i++) {
						_mean_data[i] = 0.0;
					}
				}
			}
		}
		
		private function _onCountersClick_reset(ev : MouseEvent) : void
		{
			reset();
		}
		
		private function _onMinMaxBtnClick(ev : MouseEvent) : void
		{
			_minimized = !_minimized;
			_redrawWindow();
		}
		
		private function _onTopBarMouseDown(ev : MouseEvent) : void
		{
			_drag_dx = this.mouseX;
			_drag_dy = this.mouseY;
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, _onMouseUpOrLeave);
			stage.addEventListener(Event.MOUSE_LEAVE, _onMouseUpOrLeave);
		}
		
		private function _onMouseMove(ev : MouseEvent) : void
		{
			_dragging = true;
			this.x = stage.mouseX - _drag_dx;
			this.y = stage.mouseY - _drag_dy;
		}
		
		private function _onMouseUpOrLeave(ev : Event) : void
		{
			_endDrag();
		}
	}
}
