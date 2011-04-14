package nl.igorski.visualisers.components.pixelblitter
{
	import flash.display.BitmapData;
    import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Block extends Sprite
    {
        public static const WIDTH       :int = 20;
        
		public var tileWidth            :int;
		public var tileHeight           :int;
		public var sprite               :BitmapData;
		public var spriteRect           :Rectangle;
		public var spritePoint          :Point;
		public var tileColors           :Vector.<uint>;
		public var tilesLength          :int;
		public var animationIndex       :int;
		public var animationCount       :int;
		public var animationDelay       :int;

		public var nextXpos             :Number;					// doubles as starting X position
		public var nextYpos             :Number;					// doubles as starting Y position

		public var speed                :Number;
		public var moveDir              :int;						// 0 = down, 1 = up
		
		public var myNum                :int;
        public var displacer            :int;
        
        public var col                  :uint;
		
		public function Block( myInitialNum:int = 0, myInitialMoveDir:int = 0 )
        {
            tileWidth     =
            tileHeight    = WIDTH;
            
            tileColors = new Vector.<uint>( 3 );
            tileColors[0] = 0x000000;
            tileColors[1] = 0xB7E28A;
            tileColors[2] = 0x7E9E4D;
            tilesLength   = tileColors.length;
            
            animationIndex = 0;
            animationCount = 0;
            animationDelay = 3;
            
            sprite =  new BitmapData( tileWidth, tileHeight, true, 0xFF000000 );
            
            nextXpos  =
            nextYpos  = 0;
            speed     = 3.5;
            moveDir   = 1;
            
			myNum     = myInitialNum;
			nextXpos += myInitialNum * 35;
			moveDir   = myInitialMoveDir;
            
            displacer = 0;
			
			spritePoint = new Point( nextXpos, nextYpos );
			spriteRect  = new Rectangle( 0, 0, tileWidth, tileHeight );
		}
	}
}
