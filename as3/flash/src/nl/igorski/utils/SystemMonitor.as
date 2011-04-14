package nl.igorski.utils
{

	import flash.display.MovieClip;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	import flash.events.Event;
 
	public class SystemMonitor extends MovieClip
    {
        private static const MEGABYTE   :int = 1024 * 1024;
        
		private var startTick           :Number;
		private var numFrames           :int;
		private var output              :TextField;
		private var memory              :Number;
        private var fps                 :Number;
		private var fpsMax              :int;

		public function SystemMonitor()
        {
			numFrames        = 0;
			startTick        = getTimer();
			output           = new TextField();
			output.width     = 300;
			output.textColor = 0xFFFFFF;
            
			addEventListener( Event.ADDED_TO_STAGE, initUI );
		}
		
		private function initUI( e:Event ):void
        {
            addChild( output );

			fpsMax = stage.frameRate;
			addEventListener( Event.ENTER_FRAME, onEnterFrame );	
		}
		
		private function onEnterFrame( event:Event ):void
        {	
			// FPS counter
			var t:Number = ( getTimer() - startTick ) * .001;
			++numFrames;
			if ( t > 1 )
            {
				memory = ( System.totalMemory / ( MEGABYTE ) * 100 ) * .01;
                fps    = (( numFrames / t ) * 10 ) * .1;
				output.text = "fps: " + fps.toFixed( 2 ) + " / " + fpsMax.toFixed( 2 ) + "\nmem: " + memory.toFixed( 2 ) + " Mb";
				startTick = getTimer();
				numFrames = 0;
			}
		}
		
	}
	
}