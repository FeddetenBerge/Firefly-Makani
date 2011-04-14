package nl.igorski.visualisers.components.videovisualiser 
{
    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import nl.igorski.config.Config;
	/**
     * ...
     * @author Igor Zinken
     */
    public class BitmapVideo extends EventDispatcher
    {
        public static const PREPARING   :String = "BitmapVideo::PREPARING";
        public static const READY       :String = "BitmapVideo::READY";
        
        private var _frames             :Vector.<BitmapData>;
        private var _frameRate          :Number;
        
        private var _source             :MovieClip;
        
        public var currentFrame         :uint;
        public var currentCount         :uint;
        public var countMax             :uint;
        public var state                :String = PREPARING;
        
        public function BitmapVideo( source:MovieClip )
        {
            _frameRate   = 30;

            this._source = source;
            
            currentFrame =
            currentCount = 0;
            
            countMax     = Math.ceil( Config.fps / _frameRate );
        }
        
        public function draw():void
        {
            _frames = new Vector.<BitmapData>( _source.totalFrames );
            
            for ( var i:uint = 0; i < _source.totalFrames; ++i )
            {
                _source.gotoAndStop( i + 1 );
                var bmd:BitmapData = new BitmapData( _source.width, _source.height, false );
                bmd.draw( _source );
                _frames[ i ] = bmd;
            }  
            _source = null;
            dispatchEvent( new Event( READY ));
        }
        
        public function get frame():BitmapData
        {
            if ( currentFrame >= _frames.length )
                currentFrame = 0;
            
            return _frames[ currentFrame ];
        }
        
        public function get totalFrames():uint
        {
            return _frames.length - 1;
        }

        public function get width():Number
        {
            return frame.width;
        }

        public function get height():Number
        {
            return frame.height;
        }

        public function destroy():void
        {
            var i:int = _frames.length;

            while ( --i )
            {
                _frames[i].dispose();
                _frames[i] = null;
                _frames.splice( i, 1 );
            }
            _frames = null;
        }
    }
}
