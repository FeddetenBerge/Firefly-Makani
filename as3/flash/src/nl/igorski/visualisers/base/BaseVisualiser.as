package nl.igorski.visualisers.base 
{
    import flash.display.MovieClip;
    import nl.igorski.config.Config;
    import nl.igorski.models.vo.VOLive;
    import nl.igorski.visualisers.base.interfaces.IVisualiser;
	/**
     * ...
     * @author Igor Zinken
     */
    public class BaseVisualiser extends MovieClip implements IVisualiser
    {
        public var bpm  :Number = 120;
        public var fps  :int    = Config.fps;
        
        public function BaseVisualiser() 
        {
            
        }
        
        // override in subclasses
        public function process( data:VOLive ):void
        {
            if ( data.bpm > -1 )
                bpm = data.bpm;
        }

        public function special():void
        {

        }
        
        public function destroy():void
        {
            while ( numChildren > 0 )
            {
                var c:* = getChildAt( 0 );
                removeChild( c );
                c = null;
            }
        }
        
    }

}