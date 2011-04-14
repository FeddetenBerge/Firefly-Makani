package nl.igorski.visualisers.components.particlesystem 
{
    /**
     * ...
     * @author Igor Zinken
     */
    public class Particle
    {
        public var x	        :int;
        public var y			:int;
        public var dx           :Number;
        public var dy           :Number;
        public var angle    	:Number;

        public var col   		:uint;
        public var next         :Particle;

        public function Particle()
        {
            x     = 0;
            y     = 0;
            dx    = 0;
            dy    = 0;
            angle = 0;
            col   = 0x0000FF;
        }
    }
}
