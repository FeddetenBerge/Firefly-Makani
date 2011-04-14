package nl.igorski.managers 
{
    import com.cheezeworld.utils.Input;
    import flash.display.Stage;
    import flash.events.EventDispatcher;
    import flash.events.KeyboardEvent;
    import flash.utils.setTimeout;
    import nl.igorski.events.InputEvent;
	/**
     * ...
     * @author Igor Zinken
     */
    public class InputManager extends EventDispatcher
    {
        public static var INSTANCE    :InputManager = new InputManager();
        
        private var lastKey           :int  = -1;
        
        public function InputManager() 
        {
            
        }
        
        public static function init( stage:Stage ):void
        {
            Input.instance.activate( stage );
            stage.addEventListener( KeyboardEvent.KEY_DOWN, INSTANCE.handleKeyboardInput );
        }
        
        /*
         * we check if the current key press matches the previous one
         * ( the previous key is released after a short delay ), this prevents
         * firing the same event for the during of the key down event
         */
        private function handleKeyboardInput( e:KeyboardEvent ):void
        {
            if ( e.charCode != lastKey )
            {
                lastKey = e.charCode;
                dispatchEvent( new InputEvent( InputEvent.KEY_PRESS, e.charCode ));
                setTimeout( releaseLastKey, 25 );
            }
        }
        
        private function releaseLastKey():void
        {
            lastKey = -1;
        }  
    }
}
