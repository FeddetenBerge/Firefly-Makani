package nl.igorski.utils 
{
    import flash.events.EventDispatcher;
    import nl.igorski.utils.events.DebugEvent;
	/**
     * ...
     * @author Igor Zinken
     */
    public class Debug extends EventDispatcher
    {
        public static const INSTANCE    :Debug = new Debug();
        
        public function Debug() 
        {
            if ( INSTANCE != null )
                throw new Error( "cannot instantiate Debug" );
        }
        
        public static function trace( msg:String ):void
        {
            INSTANCE.dispatchEvent( new DebugEvent( DebugEvent.TRACE, msg ));
        }
    }
}
