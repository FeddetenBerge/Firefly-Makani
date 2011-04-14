/**
 * Created by IntelliJ IDEA.
 * User: igorzinken
 * Date: 12-03-11
 * Time: 16:31
 * To change this template use File | Settings | File Templates.
 */
package nl.igorski.visualisers
{
import com.cheezeworld.utils.Input;

import com.cheezeworld.utils.KeyCode;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;

import flash.geom.Rectangle;

import flash.utils.clearInterval;
import flash.utils.setInterval;
import nl.igorski.config.Config;
import nl.igorski.models.vo.VOLive;
import nl.igorski.models.vo.VOStutter;
import nl.igorski.utils.MathTool;
import nl.igorski.visualisers.base.BaseVisualiser;
import nl.igorski.visualisers.components.particlesystem.Particle;
import nl.igorski.visualisers.helpers.ThresholdCalculator;

public final class ParticleSystemImageMap extends BaseVisualiser
    {
        private var BMD_RECT            :Rectangle;
        private const PARTICLE_NUMBER   :uint = 10000;

        private var firstParticle       :Particle;
        private var bitmapData          :BitmapData;

        private var map                 :Vector.<uint>;

        [Embed(source="../../.././../assets/map1.jpg")]
        //[Embed(source="../../.././../assets/map2.png")]
        private var imgClass            :Class;

        private var _multiplier         :uint = 1;

        private var ival                :uint;

        private var thresholdCalculator :ThresholdCalculator;
        private var stutter             :VOStutter;
        private var white               :Boolean = false;
        private const SCALE             :Number  = 1.5;

        private var MASK                :Bitmap  = new Bitmap( new ParticleSystemImageMapMask( 0, 0 ));

        public function ParticleSystemImageMap()
        {
            addEventListener( Event.ADDED_TO_STAGE, init );
        }

        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );

            thresholdCalculator = new ThresholdCalculator();

            /* create mapping data ( the source image dictating movement
             * to the particle stream )
             */
            var bitmap:Bitmap = new imgClass();

            BMD_RECT = new Rectangle( 0, 0, bitmap.width, bitmap.height );

            map = bitmap.bitmapData.getVector( BMD_RECT );
            // add bitmap to stage
            bitmapData = new BitmapData( BMD_RECT.width, BMD_RECT.height, false, 0x000000 );
            addChild( new Bitmap( bitmapData ));

            var i           :int = PARTICLE_NUMBER;
            var particle    :Particle;
            var nextParticle:Particle;

            // repeat until i is false (less than zero)
            while ( --i )
            {
                particle      = new Particle();
                particle.x    = BMD_RECT.width * Math.random();
                particle.y    = BMD_RECT.height * Math.random();
                particle.next = nextParticle;
                nextParticle  = particle;
            }
            firstParticle = particle;

            scale = SCALE;
            addChild( MASK );

            addEventListener( Event.ENTER_FRAME, render );
        }

        public function get scale():Number
        {
            return scaleX;
        }

        public function set scale( value:Number ):void
        {
            scaleX =
            scaleY = value;

            MASK.scaleX = 1 / SCALE;
            MASK.scaleY = 1 / SCALE;

            x = Config.width * .5 - ( BMD_RECT.width * scaleX ) * .5;
            y = Config.height * .5 - ( BMD_RECT.height * scaleY ) * .5;
        }

        private function render( e:Event ):void
        {
            if ( Config.DEBUG )
                handleKeyboardInput();

            bitmapData.lock();
            bitmapData.fillRect( BMD_RECT, 0xFF000000 );

            var _divider:Number = 1 / 512;

            var v:Vector.<uint>   = bitmapData.getVector( BMD_RECT );

            var particle:Particle = firstParticle;
            while ( particle )
            {
                var mapCol:uint = map[ BMD_RECT.width * int( particle.y ) + int( particle.x ) ] * _multiplier;
                var mapX:uint   = mapCol>>8 & 0xFF;
                var mapY:uint   = mapCol & 0xFF;
                particle.dx    += ( mapX - 127.5 ) * _divider;
                particle.dy    += ( mapY - 127.5 ) * _divider;
                particle.dx    *= 0.98;
                particle.dy    *= 0.98;
                particle.x     += particle.dx;
                particle.y     += particle.dy;

                if ( particle.x < 0 )
                    particle.x += BMD_RECT.width;
                else if (particle.x >= BMD_RECT.width )
                     particle.x -= BMD_RECT.width;
                if ( particle.y < 0 )
                    particle.y += BMD_RECT.height;
                else if ( particle.y >= BMD_RECT.height )
                    particle.y -= BMD_RECT.height;

                v[ BMD_RECT.width * int( particle.y ) + int( particle.x )] = ( white ) ? 0xFFFFFF : particle.col;

                particle = particle.next;
            }
            bitmapData.setVector( BMD_RECT, v );
            bitmapData.unlock();

            if ( stutter != null )
                stutter.process();
        }

        private function handleKeyboardInput():void
        {
            if ( Input.instance.isKeyDown( KeyCode.DOWN ))
            {
                if ( _multiplier > 2 )
                     --_multiplier;
                activateRestoreCounter();
            }
            if ( Input.instance.isKeyDown( KeyCode.UP ))
            {
                if ( _multiplier < 0xFFFFFF )
                    ++_multiplier;
                activateRestoreCounter();
            }
        }

        private function activateRestoreCounter():void
        {
            clearInterval( ival );
            ival = setInterval( function():void
            {
                clearInterval( ival );
                _multiplier = 1;
            }, 2000 );
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );

            if ( data.playbacksize > -1 )
            {
                _multiplier = 1 + ( MathTool.scale( data.playbacksize, 127, 0xFFFFFE ));
                activateRestoreCounter();
            }
            // scale on beat ( if playbacksize isn't manipulated )
            if ( data.envfollow > -1 && data.playbacksize == -1 )
            {
                var beat:Boolean = thresholdCalculator.measure( data.envfollow );
                scale = ( beat ) ? SCALE + MathTool.scale( data.envfollow, 127, .3 ) : SCALE;
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
        }

        private function stutterCallback():void
        {
            --stutter.counter;

            if ( stutter.counter <= 0 )
            {
                stutter.reset();
                white = true;
            }
            else if ( stutter.hold )
            {
                white = false;
            }
        }

        override public function destroy():void
        {
            removeEventListener( Event.ENTER_FRAME, render );

            clearInterval( ival );
            bitmapData.dispose();

            if ( stutter != null )
                stutter.destroy();

            super.destroy();
        }
    }
}
