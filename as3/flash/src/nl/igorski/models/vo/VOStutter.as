package nl.igorski.models.vo
{
    import nl.igorski.config.Config;

    public class VOStutter
    {
        public var active           :Boolean;
        public var lastState        :Boolean;   // was the stutter trigger on or off after the last reset ?
        public var counter          :int;       // the amount of frames required for a reset
        public var index            :int;

        private var bpm             :Number;
        private const holdLength    :int = 3;
        private var _callback       :Function;

        public function VOStutter( activate:Boolean, index:int, bpm:Number ):void
        {
            active = activate;

            if ( activate )
            {
                /*
                 * a high index isn't visible at this framerate!
                 * TODO: check with BPM ?
                 */
                this.index = ( index > 32 ) ? 32 : index;
                this.bpm   = bpm;
                lastState  = false;

                counter = calculate();
            }
        }

        /*
         * we register a specific callback function here,
         * define this in the visualiser class
         */

        public function registerCallback( f:Function ):void
        {
            _callback = f;
        }

        public function process():void
        {
            _callback();
        }

        public function reset():void
        {
            lastState = !lastState;
            counter = calculate();
        }

        /*
         * for certain effects, we may hold the effect associated
         * with the lastState Boolean set to true, this function
         * checks if the we're allowed to do so, only for the
         * lower indexes though
         */
        public function get hold():Boolean
        {
            if ( lastState && index <= 4 )
            {
                if (( calculate() - holdLength ) >= counter )
                    return true;
            }
            return false;
        }

        public function destroy():void
        {
            _callback = null;
        }

        private function calculate():int
        {
            return Math.round(( Config.fps / ( bpm / 60 )) / index );
        }
    }
}
