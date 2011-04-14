package nl.igorski.config 
{
    /**
     * ...
     * @author Igor Zinken
     */
    public class Config 
    {
        public static var INSTANCE                  :Config = new Config();
        
        public static const DEBUG                   :Boolean = false;
        
        private var _width                          :int = 800;
        private var _height                         :int = 600;
        private var _frameRate                      :int = 60;
        
        public function Config() 
        {
             if ( INSTANCE != null )
                throw new Error( "cannot instantiate Config" );
        }
        
        public static function get width():int
        {
            return INSTANCE._width;
        }
        
        public static function set width( value:int ):void
        {
            INSTANCE._width = value;
        }
        
        public static function get height():int
        {
            return INSTANCE._height;
        }
        
        public static function set height( value:int ):void
        {
            INSTANCE._height = value;
        }
        
        public static function get fps():int
        {
            return INSTANCE._frameRate;
        }
        
        public static function set fps( value:int ):void
        {
            INSTANCE._frameRate = value;
        }
    }
}
