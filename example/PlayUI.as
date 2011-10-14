package  
{
	import a3dparticle.ParticlesContainer;
	import flash.display.Sprite;
	import com.bit101.components.CheckBox;
	import com.bit101.components.HUISlider;
	import com.bit101.components.PushButton;
	import flash.events.Event;
	/**
	 * this class base on the MinimalComps.To complie the class,please add the MinimalComps.swc to your libs.
	 * 
	 */
	public class PlayUI extends Sprite
	{
		public var max:Number = 30;
		public var min:Number = 0;
		
		private var slider:HUISlider;
		private var check:CheckBox;
		private var play:PushButton;
		
		private var target:ParticlesContainer;
		
		public function PlayUI(target:ParticlesContainer,_max:Number=NaN) 
		{
			if (_max) this.max = _max;
			this.target = target;
			slider = new HUISlider(this, 0, 0, "release time", onChange);
			slider.minimum = min;
			slider.maximum = max;
			slider.setSize(500, slider.height);
			check = new CheckBox(this, 500, 5, "reverTime", onReverTime);
			play = new PushButton(this, 200, 20, "play", onPlay);
			play.toggle = true;
			play.selected = true;
			addEventListener(Event.ENTER_FRAME, onUpdate);
		}
		
		private function onReverTime(e:Event):void
		{
			if (check.selected)
			{
				target.timeScale = -1;
			}
			else
			{
				target.timeScale = 1;
			}
			e.stopPropagation();
		}
		
		private function onPlay(e:Event):void
		{
			if (play.selected)
			{
				target.start();
			}
			else
			{
				target.stop();
			}
			e.stopPropagation();
		}
		
		public function get value():Number
		{
			return slider.value;
		}
		
		private function onUpdate(e:Event):void
		{
			slider.value = target.time;
			if (target.time >= max && target.time <= min)
			{
				target.stop();
			}
			
		}
		
		private function onChange(e:Event):void
		{
			target.time = slider.value;
			e.stopImmediatePropagation();
		}
		
	}

}