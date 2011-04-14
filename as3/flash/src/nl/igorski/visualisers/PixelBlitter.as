package nl.igorski.visualisers
{
    import com.cheezeworld.utils.Input;
    import com.cheezeworld.utils.KeyCode;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.filters.ColorMatrixFilter;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;

    import nl.igorski.config.Config;
    import nl.igorski.models.vo.VOLive;
    import nl.igorski.models.vo.VOStutter;
    import nl.igorski.utils.MathTool;
    import nl.igorski.visualisers.base.BaseVisualiser;
    import nl.igorski.visualisers.components.pixelblitter.Block;
    import nl.igorski.visualisers.helpers.ThresholdCalculator;

    public final class PixelBlitter extends BaseVisualiser
    {
        public static const OUTLINE         :String = "PixelBlitter::OUTLINE";
        public static const FILLED          :String = "PixelBlitter::FILLED";

        private var bgwidth                 :Number;
        private var bgheight                :Number;
        private var bgCol                   :uint;
        private var bg                      :BitmapData;
        private var bgRect                  :Rectangle;
        private var bgPoint                 :Point;

        private var blocks                  :Vector.<Block>;
        private var blockSheet              :BitmapData;

        private var screen                  :BitmapData;
        private var screenContainer         :Bitmap;
        private var screenRectangle         :Rectangle;

        // speed up animation ? (1 = animate on beat, 4 = on quaver, 8 = on eight, 16 = sixteenth, etc.)
        private var accelerator             :int;
        private var lastAccelerator         :int;
        private var lastActionAccelerator   :int;
        public var acceleratorMax           :int;
        // amount of blocks to be displayed in each row and column
        private var amount                  :int;

        private static const amountMax      :int = 12; // maximum amount for multiplier
        private static const amtMargin      :int = 2;  // extra set of blocks added to each column (prevents blank space during animation)
        private var rowamount               :int;	   // amount of blocks that fit in one row for this resolution

        // current step in column movement ( 0 = down, 1 = up )
        private var autoScroll              :int;
        private var autoScrollDir           :int;

        private var ival                    :uint;
        private var amountIval              :uint;
        private var beatIval                :uint;
        private var acceleratorFlip         :Array = [];

        private var fillType                :String  = FILLED;
        private var fillBlock               :Boolean = false;

        private var perspective             :Boolean = false;
        private var perspectiveBlock        :Boolean = false;
        private var mirror                  :BitmapData;
        private var mirrorContainer         :Bitmap;
        private var mirrorRectangle         :Rectangle;
        private var nullPoint               :Point = new Point( 0, 0 );
        private var acceleratorDelay        :Boolean;

        private var thresholdCalculator     :ThresholdCalculator;

        private var _grayscale              :Boolean = false;
        private var grayscaleFilter         :ColorMatrixFilter;

        private var stutter                 :VOStutter;

        // debug
        private var input                   :Input = Input.instance;

        public function PixelBlitter()
        {
            bgwidth               = Config.width;
            bgheight              = Config.height;
            bgCol                 = 0xFF000000;
            bg                    = new BitmapData( bgwidth, bgheight, true, bgCol );
            bgRect                = new Rectangle( 0, 0, bgwidth, bgheight );
            bgPoint               = new Point( 0, 0 );

            accelerator           = 6;
            lastAccelerator       = accelerator;
            lastActionAccelerator = lastAccelerator;
            acceleratorMax        = 32;
            amount                = 1;

            bpm                   = 120;
            autoScroll            =
            autoScrollDir         = 0;
            acceleratorDelay      = false;

            addEventListener( Event.ADDED_TO_STAGE, initUI );
        }

        private function initUI( e:Event = null ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, initUI );

            thresholdCalculator = new ThresholdCalculator();

            screen          = new BitmapData( bgwidth, bgheight, false, bgCol );
            screenContainer = new Bitmap( screen );
            screenRectangle = new Rectangle( 0, 0, screen.width, screen.height );

            mirror          = new BitmapData( screen.width, screen.height * .5 );
            mirrorContainer = new Bitmap( mirror );
            mirrorRectangle = new Rectangle( 0, 0, mirror.width, mirror.height );

            // TODO: do we really need this??
            blockSheet      = new Blocks( 0, 0 );

            var ratio:Number   = bgheight / bgwidth;

            // TODO: we are forgetting something... when the block sizes shrink the amount of blocks that fit on
            // screen aren't enough... so we multiply this a tad...
            var multiplier:int = 3;
            createBlocks(( Math.ceil( amountMax + amtMargin ) * Math.ceil(( amountMax + amtMargin ) * ratio ) ) * multiplier );

            addChild( screenContainer );

            // actually RUN this program
            addEventListener( Event.ENTER_FRAME, pixelLoop, false, 0, true );
        }

        // creates initial block(s)
        public function createBlocks( amt:int = 0 ):void
        {
            var cols        :int = 0;
            var rows        :int = 0;
            var anistart    :int = 1;

            if ( amt == 0 )
                amt = bgwidth * 1.55;

            if ( blocks != null )
            {
                if ( amt < blocks.length )
                    return;
            }
            blocks = new Vector.<Block>( amt );

            for ( var i:int = 0; i < amt; ++i )
            {
                var obj:Block = new Block( i, 0 );
                obj.nextXpos = cols * obj.tileWidth;
                obj.nextYpos = rows * obj.tileHeight;
                obj.animationIndex = Math.round( obj.tilesLength / anistart );
                obj.animationDelay = calculateSynchedDelay();

                blocks[ i ] = ( obj );

                ++cols;

                if (( cols * obj.tileWidth ) > bgwidth )
                {
                    ++rows;
                    rowamount = cols;
                    cols = 0;
                }
                ++anistart;
                if ( anistart > obj.tilesLength )
                    anistart = 1;
            }
        }

        public function set grayscale( value:Boolean ):void
        {
            _grayscale = value;

            if ( value )
            {
                if ( grayscaleFilter == null )
                {
                    var b:Number  = 1 / 3;
                    var c:Number  = 1 - ( b * 2 );
                    var m:Array   = [ c, b, b, 0, 0,
                                      b, c, b, 0, 0,
                                      b, b, c, 0, 0,
                                      0, 0, 0, 1, 0 ];

                    grayscaleFilter = new ColorMatrixFilter( m );
                }
                this.filters = [ grayscaleFilter ];
            }
            else {
                this.filters = [];
            }
        }

        public function pixelLoop( e:Event ):void
        {
            if ( Config.DEBUG )
                handleInput();

            handleBlocks();						// handle block program behaviour
            render();							// display the result on screen
        }

        private function handleBlocks():void
        {
            var currow  :int = 0;
            var curcol  :int = 0;

            var i       :Block;

            // COLUMN BASED approach
            var colHeight    :int = bgheight / ( amount + amtMargin );
            var rowWidth     :int = bgwidth / amount;
            var yDisplacement:int = 0;

            if ( amount >= 6 )
                yDisplacement = autoScroll;

            for ( var h:uint = 0; h < blocks.length; ++h )
            {
                i = blocks[h];

                // tiles are squares
                i.tileHeight =
                i.tileWidth  = colHeight;

                i.col = curcol;

                i.displacer     = ( autoScrollDir == 1 ) ? i.displacer + yDisplacement : 0/* i.displacer - yDisplacement*/;
                i.spritePoint   = new Point( curcol * i.tileWidth, ( currow * i.tileHeight ));

                i.spritePoint.y = ( curcol % 2 ) ? i.spritePoint.y + i.displacer : i.spritePoint.y - i.displacer;

                i.spriteRect.x = int(( i.animationIndex % i.tilesLength )) * i.tileWidth;
                i.spriteRect.y = int(( i.animationIndex / i.tilesLength )) * i.tileHeight;

                if (( currow * colHeight ) >= bgheight )
                {

                    ++curcol;
                    currow = 0;
                    switch( autoScrollDir )
                    {
                        case 0:
                            autoScrollDir = 1;
                            break;
                        case 1:
                            autoScrollDir = 0;
                            break;
                    }
                } else {
                    ++currow;
                }
            }
            switch( autoScrollDir )
            {
                case 0:					// down
                    autoScroll += accelerator;
                    if ( autoScroll > ( colHeight * i.tilesLength ))
                        resetAutoScroller();
                        break;
                case 1:					// up
                    autoScroll -= accelerator;
                    if ( autoScroll < -( colHeight * i.tilesLength ))
                        resetAutoScroller();
                    break;
             }
        }

        private function toggleFillType():void
        {
            if ( fillBlock )
                return;

            switch( fillType )
            {
                case OUTLINE:
                    fillType = FILLED;
                    break;
                case FILLED:
                    fillType = OUTLINE;
                    break;
            }
            fillBlock = true;

            setTimeout( function():void
            {
                fillBlock = false;
            }, 250 );
        }

        private function togglePerspective():void
        {
            if ( perspectiveBlock )
                return;

            switch( perspective )
            {
                // perspective was active, restore visualiser
                case true:

                    screenContainer.rotationX = 0;
                    screenContainer.x         =
                    screenContainer.y         = 0;
                    mirrorContainer.rotationY = 0;
                    mirror.fillRect( mirrorRectangle, 0xFF000000 );
                    removeChild( mirrorContainer );
                    break;

                case false:

                    mirrorContainer.rotationY = 40;
                    mirrorContainer.x         = 0;

                    screenContainer.rotationX = -90;
                    screenContainer.x         = -Config.width * .25;
                    screenContainer.y         = Config.height * .5;
                    addChildAt( mirrorContainer, 0 );
                    break;
            }
            perspective      = !perspective;
            perspectiveBlock = true;

            setTimeout( function():void
            {
                perspectiveBlock = false;
            }, 250 );
        }

        // halts and inverts vertical movement
        private function resetAutoScroller():void
        {
            autoScroll = 0;
        }

        // informs all blocks objects of the new tempo accents
        private function updateAnimationDelays():void
        {
            for each ( var i:Block in blocks )
                i.animationDelay = calculateSynchedDelay();

            delayAccelerator();
        }

        private function calculateSynchedDelay():uint
        {
            var multiplier:uint = 3;  // multiply the delay
            return Math.round(( fps * multiplier / ( bpm / 60 )) / accelerator );	// fps / bps
        }

        private function delayAccelerator():void
        {
            if ( !ival > 0 && !acceleratorDelay )
                ival = setInterval( evaluateAccelerator, fps );
        }

        private function evaluateAccelerator():void
        {
            if ( lastActionAccelerator != lastAccelerator && lastActionAccelerator != accelerator && !acceleratorDelay )
            {
                setTimeout( unlockAcceleratorDelay, fps * .75 );
                lastActionAccelerator = lastAccelerator;
                acceleratorDelay      = true;
            }
            clearInterval( ival );
        }

        private function unlockAcceleratorDelay():void
        {
            if ( acceleratorDelay )
            {
                lastActionAccelerator = lastAccelerator;
    //			lastAccelerator       = accelerator;
                accelerator           = 0;
                amount                = 1;
                acceleratorDelay      = false;
                clearInterval( ival );
            }
        }

        private function render():void
        {
            // clear previous frame ( depending on beat choose colour )
            var col:uint = ( _grayscale ) ? 0xFFFFFFFF : 0xFF000000;

            screen.fillRect( screenRectangle, col );

            if ( blocks.length > 0 )
            {
                // blocks
                var h:int = blocks.length;
                while( --h >= 0 )
                {
                    var i:Block = blocks[h];

                    i.tileColors[0] = col;

                    // select tile for animation
                    if ( i.animationCount >= i.animationDelay )
                    {
                        ++i.animationIndex;
                        i.animationCount = 0;
                    } else {
                        ++i.animationCount;
                    }
                    if ( i.animationIndex == i.tilesLength )
                        i.animationIndex = 0;

                    // single color
                    if ( fillType == FILLED )
                    {
                       // screen.copyPixels( blockSheet, new Rectangle( i.tileWidth * i.animationIndex, 0, i.tileWidth, i.tileHeight ), new Point( i.spritePoint.x, i.spritePoint.y ));
                       // OLD: screen.fillRect( new Rectangle( i.spritePoint.x * i.animationIndex, i.spritePoint.y * i.animationIndex, i.tileWidth, i.tileHeight), i.tileColors[i.animationIndex] );
                       screen.fillRect( new Rectangle( i.spritePoint.x, i.spritePoint.y, i.tileWidth, i.tileHeight), i.tileColors[i.animationIndex] );
                    } else {
                        // outlines only
                        screen.fillRect( new Rectangle( i.spritePoint.x, i.spritePoint.y, i.tileWidth - 2, 2 ), i.tileColors[i.animationIndex] );
                        screen.fillRect( new Rectangle( i.spritePoint.x + i.tileWidth, i.spritePoint.y, 2, i.tileHeight - 2 ), i.tileColors[i.animationIndex] );
                        screen.fillRect( new Rectangle( i.spritePoint.x, i.spritePoint.y + i.tileHeight, i.tileWidth - 2, 2 ), i.tileColors[i.animationIndex] );
                        screen.fillRect( new Rectangle( i.spritePoint.x, i.spritePoint.y, 2, i.tileHeight - 2 ), i.tileColors[i.animationIndex] );
                    }
                }
                // perspective mirror
                if ( perspective )
                {
                    mirror.fillRect( mirrorRectangle, 0xFF000000 );
                    mirror.copyPixels( screen, screenRectangle, nullPoint );
                }
            }
            if ( stutter != null )
                stutter.process();
        }

        public function updateAccelerator( val:int ):void
        {
            var taccelerator:int = acceleratorFlip[val];

            if ( lastActionAccelerator != taccelerator )
            {
                acceleratorDelay      = false;
                accelerator           = taccelerator;
                lastAccelerator       = lastActionAccelerator;
                lastActionAccelerator = accelerator;
                evaluateAccelerator();
            }
            else
            {
                accelerator = acceleratorMax * .25;
                return;

                if ( !acceleratorDelay )
                {
                    accelerator = taccelerator;
                    if ( lastActionAccelerator != lastAccelerator )
                    {
                        lastAccelerator       = lastActionAccelerator;
                        lastActionAccelerator = accelerator;
                    }
                    evaluateAccelerator();
                }
                else {
                    acceleratorDelay = false;
                    evaluateAccelerator();
                }
            }
        }

        public function updateStretch( val:int ):void
        {
            if ( lastActionAccelerator != acceleratorFlip[val] && !acceleratorDelay )
                amount = /*amountFlip[*/val//];

            clearInterval( amountIval );
            amountIval = setInterval( resetAmount, 500 );
        }

        /*
         * we only display a massive amount of blocks when the
         * MIDI controllers are actively triggering data, so shortly
         * after the controllers are idle, we return to a smaller amount
         */
        private function resetAmount():void
        {
            clearInterval( amountIval );

            var th:uint = 3;

            if ( amount > th )
                amount = th;
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );

            if ( data.envfollow > -1 )
            {
                var beat:Boolean = thresholdCalculator.measure( data.envfollow );

                if ( beat && thresholdCalculator.magnitude > 80 )
                    handleBeat();
            }
            if ( data.momsw > -1 )
            {
                if ( data.momState ) {
                    stutter = new VOStutter( data.momState, data.momIndex, bpm );
                    stutter.registerCallback( stutterCallback );
                } else {
                    stutter = null;
                }
            }
            if ( data.playbacksize > -1 )
                updateStretch( ( amountMax - 1 ) - MathTool.scale( data.playbacksize, 127, amountMax ));

            if ( data.playbackspeed > -1 )
                updateAccelerator( MathTool.scale( data.playbackspeed, 127, acceleratorMax ));
        }

        override public function special():void
        {
            togglePerspective();
        }

        private function handleInput( e:Event = null ):void
        {
            if ( input.isKeyDown( KeyCode.SPACEBAR ))
                handleBeat();

            if ( input.isKeyDown( KeyCode.P ))
                togglePerspective();

            // animation speed
            if ( input.isKeyDown( KeyCode.RIGHT ))
            {
                if ( accelerator < acceleratorMax )
                    updateAccelerator( ++accelerator );
                updateAnimationDelays();
            }
            if ( input.isKeyDown( KeyCode.LEFT ))
            {
                if ( accelerator > 1 )
                    updateAccelerator( --accelerator );
                updateAnimationDelays();
            }
            // block amount
            if ( input.isKeyDown( KeyCode.DOWN ))
            {
                if ( amount > 1 )
                    updateStretch( --amount );
            //	resetAutoScroller();
            }
            if ( input.isKeyDown( KeyCode.UP ))
            {
                if ( amount < amountMax )
                    updateStretch( ++amount );
            //	resetAutoScroller();
            }
        }

        private function stutterCallback():void
        {
            --stutter.counter;

            if ( stutter.counter == 0 )
            {
                stutter.reset();
                var col:uint = ( stutter.lastState ) ? 0xFF000000 : 0xFFFFFFFF;
                screen.fillRect( screen.rect, col );
            }
            else if ( stutter.hold )
            {
                screen.fillRect( screen.rect, 0xFFFFFFFF );
            }
        }

        private function handleBeat():void
        {
            grayscale = true;
            clearInterval( beatIval );
            beatIval = setInterval( resetBeat, 250 );
        }

        private function resetBeat():void
        {
            clearInterval( beatIval );
            grayscale = false;
        }

        override public function destroy():void
        {
            removeEventListener( Event.ENTER_FRAME, pixelLoop );

            clearInterval( amountIval );
            clearInterval( ival );
            clearInterval( beatIval );

            while ( numChildren > 0 )
                removeChildAt( 0 );

            if ( blocks.length > 0 )
            {
                var h:int = blocks.length;
                while ( --h >= 0 )
                {
                    var i:Block = blocks[h];
                    i           = null;
                    blocks.splice( h, 1 );
                }
            }
            screen.dispose();
            mirror.dispose();

            if ( stutter != null )
                stutter.destroy();

            if ( blockSheet != null )
                blockSheet.dispose();

            thresholdCalculator = null;
        }
    }
}
