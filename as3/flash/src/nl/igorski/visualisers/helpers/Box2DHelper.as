package nl.igorski.visualisers.helpers 
{
	/**
     * ...
     * @author Igor Zinken
     */
    public class Box2DHelper 
    {
        public static const PIXELS_PER_METER    :int = 30;
        public static const CONVERSION          :Number = 1 / PIXELS_PER_METER;
        
        public function Box2DHelper() 
        {
            
        }
        
        public static function p2m( px:Number ):Number
        {
            return px * CONVERSION;
        }
        
        public static function m2p( m:Number ):Number
        {
            return m * PIXELS_PER_METER;
        }
        
    }

}