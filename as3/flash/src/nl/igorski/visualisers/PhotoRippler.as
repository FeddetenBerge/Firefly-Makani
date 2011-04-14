package nl.igorski.visualisers 
{
    import be.nascom.flash.graphics.Rippler;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.Shape;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.filters.BlurFilter;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.utils.Timer;
    import nl.igorski.config.Config;
    import nl.igorski.models.vo.VOLive;
    import nl.igorski.utils.ArrayTool;
    import nl.igorski.utils.BitmapTool;
    import nl.igorski.utils.MathTool;
    import nl.igorski.visualisers.base.BaseVisualiser;
    import nl.igorski.visualisers.components.photosplitter.BitmapDistorter;
    import nl.igorski.visualisers.components.photosplitter.BitmapWarper;
    import nl.igorski.visualisers.helpers.ThresholdCalculator;
	/**
     * ...
     * @author Igor Zinken
     */
    public class PhotoRippler extends BaseVisualiser
    {
        private var _target             :Bitmap;
        private var _rippler            :Rippler;
        
        private var animationDelay      :int;
        private var animationCounter    :int;
        private var _rippleSize         :Number = 2.5;
        
        private var thresholdCalculator :ThresholdCalculator;
        
        private var ival                :uint;
        
        public function PhotoRippler() 
        {
            addEventListener( Event.ADDED_TO_STAGE, init );
        }
        
        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );
            
            thresholdCalculator = new ThresholdCalculator();
            
            _target   = new Bitmap( new FireFly( 0, 0 ));
            _target.x = Config.width * .5 - _target.width * .5;
            _target.y = Config.height * .5 - _target.height * .5;
            addChild( _target );
            
            _rippler = new Rippler( _target, 60, 6 );
            
            animationDelay   = Math.round( fps / ( bpm / 60 ));
            animationCounter = 0;
            
            if ( Config.DEBUG )
                stage.addEventListener( MouseEvent.MOUSE_MOVE, handleMouseMove );
                
            addEventListener( Event.ENTER_FRAME, onEnterFrame );
        }
        
        private function onEnterFrame( e:Event ):void
        {
            ++animationCounter;
            
            if ( animationCounter >= animationDelay )
            {
                var amount:int = 10;
                while ( --amount > 0 )
                {
                    var _x:Number = MathTool.rand( x, x + width );
                    var _y:Number = MathTool.rand( y, y + height );
                    
                    if ( _x > 0 && _y > 0 )
                        _rippler.drawRipple( _x, _y, _rippleSize, 1 );
                }
                animationCounter = 0;
            }
        }
        
        private function handleMouseMove( e:MouseEvent ):void
        {
            // the ripple point of impact is size 20 and has alpha 1
            _rippler.drawRipple( _target.mouseX, _target.mouseY, _rippleSize, 1 );
        }
        
        override public function process( data:VOLive ):void
        {
            super.process( data );
            
            if ( data.envfollow > -1 )
            {
                var beat:Boolean = thresholdCalculator.measure( data.envfollow );
                _rippleSize = MathTool.scale( thresholdCalculator.magnitude, 100, 60 );
                clearInterval( ival );
                setInterval( function():void
                {
                    _rippleSize = 2;
                    clearInterval( ival );
                }, 2000 );
            }
            var _x:Number = 0;
            var _y:Number = MathTool.rand( y, y + height );
            
            if ( data.playbacksize > -1 )
                _x = MathTool.scale( data.playbacksize, 127, _x + _target.width );
                
            if ( data.playbackspeed > -1 )
                _y = MathTool.scale( data.playbackspeed, 127, _y + _target.height );
            
          //  if ( _rippleSize < 20 )
          //      _rippleSize = 20;
            
            if ( _x > 0 && _y > 0 )
                _rippler.drawRipple( _x, _y, _rippleSize, 1 );
        }
        
        override public function destroy():void
        {
            removeEventListener( Event.ENTER_FRAME, onEnterFrame );
            
            clearInterval( ival );
            
            _target.bitmapData.dispose();
            super.destroy();
        }
    }
}
