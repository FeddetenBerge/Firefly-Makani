package nl.igorski.utils
{
    import com.gskinner.utils.Rndm;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    
    /**
     * @author     Igor Zinken
    */
    public class RandomActionTool
    {
        private var _probability    :Number;
        private var _idleProbability:Number;
        
        private var _idleLowerRange :Number;
        private var _idleUpperRange :Number;
        
        private var _isIdle         :Boolean;
        private var _idleIval       :uint;
        
        /*
         * @probability     Number ( 0 to 1 ) dictating the chance that an action should be executed
         * @idleProbability Number ( 0 to 1 ) dictating the chance that the RandomActionTool should enter
         *                                    it's idle state - essentially a timeout during which no actions
         *                                    can be performed - set to 0 to not disable the idle state
         * @idleTimeRange   Array             array holding two numbers holding the lower and upper range
         *                                    of the timeOut duration ( in milliseconds ), set second number to null
         *                                    or 0 to use a fixed duration instead of a random range between the lower
         *                                    and upper value
         */
        public function RandomActionTool( probability:Number = 0.25, idleProbability:Number = 0, idleTimeRange:Array = null )
        {
            _probability     = probability;
            _idleProbability = idleProbability;
            
            if ( idleTimeRange != null )
            {
                _idleLowerRange  = idleTimeRange[ 0 ];
                
                if ( idleTimeRange.length > 1 )
                    _idleUpperRange = idleTimeRange[ 1 ];
                else
                    _idleUpperRange = _idleLowerRange;
            }
            else {
                _idleLowerRange =
                _idleUpperRange = 0;
            }
            
            _isIdle          = false;
        }
        
        /*
         * this queries wether or not to perform an action
         * using the given probability rate
         */
        public function performAction():Boolean
        {
            if ( _isIdle )
                return false;
            
            var doIt:Boolean = Rndm.boolean( _probability );
            
            if ( !doIt )
                return false;
            
            // if we the idleProbability is set, check
            // wether we should set this tool to idle mode
            if ( _idleProbability > 0 )
            {
                if ( performIdle())
                    setIdle( true );
            }            
            return doIt;
        }
        
        public function get idle():Boolean
        {
            return _isIdle;
        }
        
        /*
         * checks wether we should enter the idle state
         */
        private function performIdle():Boolean
        {
            return Rndm.boolean( _idleProbability );
        }
        
        /*
         * activates the idle state
         */
        private function setIdle( active:Boolean = true ):void
        {
            _isIdle = active;
            clearInterval( _idleIval );
            
            if ( _isIdle )
            {
                var time:Number = _idleLowerRange;
                
                // use random timeout within set range
                if ( _idleUpperRange != _idleLowerRange )
                    time = Math.floor( Math.random() * ( 1 + _idleUpperRange - _idleLowerRange )) + _idleLowerRange;
                
                _idleIval = setInterval( function():void
                {
                    setIdle( false );
                }, time );
            }
        }
    }
}
