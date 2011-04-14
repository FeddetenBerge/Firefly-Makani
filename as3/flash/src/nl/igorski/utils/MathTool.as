package nl.igorski.utils 
{	
	/**
	 * ...
	 * @author Igor Zinken
	 */
	public class MathTool
	{		
		public function MathTool() 
		{
			
		}
		
		/*
		 * @method rand
		 * returns a random number within a given range
		 */
		public static function rand( low:Number = 0, high:Number = 1 ):Number
		{
			return Math.round( Math.random() * ( high - low )) + low;
		}
		
		/*
		 * @method scale
		 * scales a value to match against a scale by comparing ranges
         * 
		 * @param value           => value to get scaled to 
		 * @param maxValue 		  => the maximum value we are likely to expect for param value
		 * @param maxCompareValue => the maximum value in the scale we're matching against
		 */
		public static function scale( value:Number, maxValue:Number, maxCompareValue:Number ):Number
		{
			var ratio:Number = maxCompareValue / maxValue;
			return value * ratio;
		}
        
        /**
         * @method deg2rad
         * translates a value in degrees to radians
         */
        public static function deg2rad( deg:Number ):Number
        {
            return deg / ( 180 / Math.PI );
        }
        
        /**
         * @method rad2deg
         * translates a value in radians to degrees
         */
        public static function rad2deg( rad:Number ):Number
        {
            return rad / ( Math.PI / 180 );
        }
	}	
}
