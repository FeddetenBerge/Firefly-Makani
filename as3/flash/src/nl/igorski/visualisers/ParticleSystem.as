package nl.igorski.visualisers
{
    import com.cheezeworld.utils.Input;
    import com.cheezeworld.utils.KeyCode;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.Shader;
	import flash.events.Event;
    import flash.filters.ColorMatrixFilter;
	import flash.filters.ShaderFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
    import flash.utils.ByteArray;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import nl.igorski.config.Config;
    import nl.igorski.models.vo.VOLive;
    import nl.igorski.utils.MathTool;
    import nl.igorski.visualisers.base.BaseVisualiser;
    import nl.igorski.visualisers.components.particlesystem.Particle;
    import nl.igorski.visualisers.helpers.ThresholdCalculator;

    public final class ParticleSystem extends BaseVisualiser
    {
        private const TWO_PI                :Number = 2 * Math.PI;
        private var amount					:int = 250;
        private var bmpd					:BitmapData;
        private var particles				:Vector.<Particle>;

        private var WIDTH					:int = 0;
        private var HEIGHT					:int = 0;

        private var centerPoint             :Point;
        private var radiusWidth             :int;
        private var radiusHeight            :int;
        private var rotationSpeed           :Number = .01;

        [Embed(source = "../../../../lib/pixel bender/smoke_v2.pbj", mimeType="application/octet-stream")]
        private var _fluidShader 			:Class;

        private var _shader					:Shader;
        private var _filter					:ShaderFilter;
        private var _buffer1				:BitmapData;
        private var _destBuffer				:BitmapData;
        private var _rect					:Rectangle;
        private var _nullPoint				:Point = new Point( 0, 0 );
        private var _blankRect              :Rectangle;
        private var _bitmap					:Bitmap;

        private var bitmapRatio             :Number;
        private var thresholdCalculator     :ThresholdCalculator;

        private var grayscaleFilter         :ColorMatrixFilter;
        private var _grayscale              :Boolean = false;
        private var direction               :uint = 0;
        private var ival                    :uint;
        private var beatIval                :uint;

        public function ParticleSystem()
        {
            WIDTH        = Config.width * .5;
            HEIGHT       = Config.height * .5;

            centerPoint  = new Point( WIDTH * .5, HEIGHT * .5 );
            radiusWidth  = WIDTH * .25;
            radiusHeight = HEIGHT * .25;

            _blankRect   = new Rectangle( 0, 0, WIDTH, HEIGHT );

            addEventListener( Event.ADDED_TO_STAGE, initUI );
        }

        private function initUI( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, initUI );
            bmpd = new BitmapData( WIDTH, HEIGHT, false, 0x00000000 );

            thresholdCalculator = new ThresholdCalculator();
            particles           = new Vector.<Particle>();

            var maxCols:int = 700;
            var curRow:int  = 1;
            var curCol:int  = 1;

            var particle:Particle;

            for ( var i:uint = 0; i < amount; ++i )
            {
                particle = new Particle();

                var radians:Number = MathTool.scale( i, amount, 360 ) * TWO_PI;
                particle.x         = centerPoint.x/* + Math.cos( radians ) * radiusWidth + i*/;
                particle.y         = centerPoint.y/* +  Math.sin( radians ) * radiusHeight + i*/;
                particle.angle     = MathTool.scale( i, amount, 360 ) / 360;
                particle.col       = 0x00ff00;

                particles.push( particle );

                if ( i > 0 )
                    particles[ i - 1 ].next = particles[i];

                ++curCol;

                if ( curCol > maxCols )
                {
                    curCol = 1;
                    ++curRow;
                }
            }
            initBitmapData( WIDTH, HEIGHT );
            initShader();

            y -= ( HEIGHT * .5 - _buffer1.height * .5 );

            addEventListener( Event.ENTER_FRAME, render );
        }

        private function initShader() : void
        {
            _shader                       = new Shader( new _fluidShader() as ByteArray );
            _filter                       = new ShaderFilter( _shader );
            _shader.data.timeStep.value   = [ 0.002 ];		// 0.002 as default, 0.02 as max, 0.0002 as min
            _shader.data.density.value    = [ 0.01 ];	 	// 0.01
            _shader.data.viscosityV.value = [ 0.1 ];	// 0.01
            _shader.data.viscosityP.value = [ 1 ];	// 0.1
            _shader.data.force.value      = [ 1, -1 ];
        }

        private function initBitmapData( w:int, h:int = 0 ):void
        {
            if ( h == 0 )
                h = w;

            _buffer1    = new BitmapData( w, h, false, 0x7f7f00 );
            _destBuffer = new BitmapData( w, h, false, 0x000000 );
            _rect       = new Rectangle( 0, 0, w, h );
            _bitmap     = new Bitmap( _destBuffer );
            addChild( _bitmap );

            bitmapRatio    = Config.width / WIDTH;
            _bitmap.scaleX = _bitmap.scaleY = bitmapRatio;
        }

        public function render( e:Event ):void
        {
            if ( Config.DEBUG )
                handleInput();

            bmpd.fillRect( _blankRect, 0x000000 );

            var p:Particle = particles[0];

            while ( p.next )
            {
                var gravity:Number = 3;
                p.angle -= rotationSpeed;
                var xDiff:Number = centerPoint.x + Math.cos( p.angle * TWO_PI ) * radiusWidth/* + MathTool.rand( -10, 10 )*/;
                var yDiff:Number = centerPoint.y + Math.sin( p.angle * TWO_PI ) * radiusHeight;

                if ( p.angle < -1 )
                    p.angle = 0;

                var dist:Number    = Math.sqrt(( xDiff * xDiff ) + ( yDiff * yDiff ));

                if ( p.next != null )
                {
                    var speedX:int = Math.abs( p.x - xDiff ) * .7;
                    var speedY:int = Math.abs( p.y - yDiff ) * .7;

                    p.x = ( xDiff > p.x ) ? p.x + speedX : p.x - speedX;
                    p.y = ( yDiff > p.y ) ? p.y + speedY : p.y - speedY;

                    if ( p.x > 0 && p.x < WIDTH && p.y > 0 && p.y < HEIGHT )
                       bmpd.setPixel( p.x, p.y, p.col );

                    // used to setPixel ( and no alpha values for the colors )
                    if ( p.x > 0 && p.x < WIDTH && p.y > 0 && p.y < HEIGHT )
                    {
                        var pix : int = bmpd.getPixel( p.x, p.y );
                        pix = ( pix & 0x33ffff00 ) + 0xff;
                        _buffer1.setPixel32( p.x, p.y, pix );

                        pix =  bmpd.getPixel( p.x + 1, p.y );
                        pix = ( pix & 0x33ffff00 ) + 0xff;
                        _buffer1.setPixel32( p.x + 1, p.y, pix );

                        pix = bmpd.getPixel( p.x, p.y + 1 );
                        pix = ( pix & 0x33ffff00 ) + 0xff;
                        _buffer1.setPixel32( p.x, p.y + 1, pix );

                        pix = bmpd.getPixel( p.x + 1, p.y + 1 );
                        pix = ( pix & 0x33ffff00 ) + 0xff;
                        _buffer1.setPixel32( p.x + 1, p.y + 1, pix );
                    }
                }
                p = p.next;
            }
            _buffer1.applyFilter( _buffer1, _rect, _nullPoint, _filter );
            _destBuffer.copyChannel( _buffer1, _rect, _nullPoint, BitmapDataChannel.BLUE, BitmapDataChannel.GREEN );
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );

            if ( data.envfollow > -1 )
            {
                var beat:Boolean = thresholdCalculator.measure( data.envfollow );
                _shader.data.timeStep.value = [ 0.02 / thresholdCalculator.magnitude ];
                grayscale = (  beat ) ? true : false;
            }
            if ( data.playbacksize > -1 )
            {
                if ( direction == 0 ) {
                    radiusWidth = MathTool.scale( data.playbacksize, 127, 250 );
                } else {
                    radiusHeight = MathTool.scale( data.playbacksize, 127, 250 );
                }
                setReleaseTimer();
            }
        }

        private function setReleaseTimer():void
        {
            clearInterval( ival );
            ival = setInterval( release, 250 );
        }

        private function release():void
        {
            clearInterval( ival );

            if ( radiusWidth > radiusHeight )
            {
                radiusHeight = 0;
                direction    = 1;
            }
            else {
                radiusWidth = 0;
                direction   = 0;
            }
        }

        private function handleInput():void
        {
            if ( Input.instance.isKeyDown( KeyCode.SPACEBAR ))
                handleBeat();

            if ( Input.instance.isKeyDown( KeyCode.UP )) {
                radiusHeight += 15;
                setReleaseTimer();
            }
            if ( Input.instance.isKeyDown( KeyCode.DOWN )) {
                radiusHeight -= 15;
                setReleaseTimer();
            }
            if ( Input.instance.isKeyDown( KeyCode.LEFT )) {
                radiusWidth -= 15;
                setReleaseTimer();
            }
            if ( Input.instance.isKeyDown( KeyCode.RIGHT )) {
                radiusWidth += 15;
                setReleaseTimer();
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
                if ( _bitmap != null )
                    _bitmap.filters = [ grayscaleFilter ];
            }
            else {
                if ( _bitmap != null )
                    _bitmap.filters = [];
            }
        }

        override public function destroy():void
        {
            removeEventListener( Event.ENTER_FRAME, render );

            if ( particles.length > 0 )
            {
                var h:int = particles.length;
                while ( --h >= 0 )
                {
                    var i:Particle = particles[h];
                    i              = null;
                    particles.splice( h, 1 );
                }
            }
            _buffer1.dispose();
            _destBuffer.dispose();

            clearInterval( ival );
            clearInterval( beatIval );

            _shader     = null;
            _filter     = null;
            _buffer1    = null;
            _destBuffer = null;
            _bitmap     = null;

            super.destroy();
        }
    }
}
