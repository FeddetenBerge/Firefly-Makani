package nl.igorski.visualisers.helpers 
{
    /**
     * ...
     * @author Igor Zinken
     */
    public class ThresholdCalculator 
    {
        private var measures        :Vector.<Number>;
        private var measuredPeaks   :Vector.<Number>;
        private var window          :int;
        private var windowPeaks     :int;
        private var _average        :Number;
        
        /*
         * buffer sets the maximum amount of measures
         * to be stored and used for calculating the average
         */
        public function ThresholdCalculator( buffer:int = 128 )
        {
            this.window      = buffer;
            this.windowPeaks = Math.round( buffer * .125 );
            measures         = new Vector.<Number>();
            measuredPeaks    = new Vector.<Number>();
        }
        
        /*
         * add measure to the vector, if the current value is higher
         * than the average, return a Boolean indicating that a peak occured
         */
        public function measure( value:Number ):Boolean
        {
            if ( measures.length == window )
                measures.splice( measures.length - 1, 1 );
            
            measures.push( value );
            
            // calculate average
            var sum:Number = 0;

            for each( var n:Number in measures )
                sum += n;
            
            _average = sum / measures.length;
            
            var peak:Boolean = ( value > _average ) ? true : false;

            if ( peak )
                addPeak( value );

            return peak;
        }
        /*
         * to determine the magnitude of the last / current peak
         * we check it against the other measured peaks, magnitudes
         * are in percents ( range 0 - 100 )
         */
        public function get magnitude():Number
        {
            var max:Number = 0;
            
            for each( var n:Number in measuredPeaks )
            {
                if ( n > max )
                    max = n;
            }
            return ( measures[ measures.length - 1 ] / max ) * 100;
        }

        public function get average():Number
        {
            return _average;
        }

        private function addPeak( value:Number ):void
        {
            if ( measuredPeaks.length == windowPeaks )
                measuredPeaks.splice( measuredPeaks.length - 1, 1 );

            measuredPeaks.push( value );
        }
    }
}
