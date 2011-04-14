/**
 * Created by IntelliJ IDEA.
 * User: igorzinken
 * Date: 12-03-11
 * Time: 16:13
 * To change this template use File | Settings | File Templates.
 */
package nl.igorski.visualisers
{
import com.cheezeworld.utils.Input;

import com.cheezeworld.utils.KeyCode;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.BitmapDataChannel;
import flash.events.Event;
import flash.geom.Rectangle;

import flash.utils.clearInterval;
import flash.utils.setInterval;

import nl.igorski.config.Config;
import nl.igorski.models.vo.VOLive;
import nl.igorski.utils.MathTool;
import nl.igorski.visualisers.base.BaseVisualiser;
import nl.igorski.visualisers.components.particlesystem.Particle;
import nl.igorski.visualisers.helpers.ThresholdCalculator;

public final class ParticleSystemWaves extends BaseVisualiser
    {
        private const BMD_RECT          :Rectangle = new Rectangle( 0, 0, Config.width * .5, Config.height * .5 );
        private const PARTICLE_NUMBER   :uint = 10000;

        private var firstParticle       :Particle;
        private var bitmapData          :BitmapData;
        private var mapBitmapData       :BitmapData;

        private var map                 :Vector.<uint>;

        private var _dividerValue       :int = 64;
        private var _divider            :Number = 1 / _dividerValue;

        private var _displacement       :Number = 127.5;

        private var thresholdCalculator :ThresholdCalculator;
        private var beat                :Boolean = false;
        private var ival                :uint;

        public function ParticleSystemWaves()
        {
            addEventListener( Event.ADDED_TO_STAGE, init );
        }

        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );

            thresholdCalculator = new ThresholdCalculator();

            //create mapping data
            mapBitmapData = new BitmapData( BMD_RECT.width, BMD_RECT.height);
            createNoise();

            bitmapData = new BitmapData( BMD_RECT.width, BMD_RECT.height, false, 0x000000 );
            addChild( new Bitmap( bitmapData ));

            var i           :int = PARTICLE_NUMBER;
            var particle    :Particle;
            var nextParticle:Particle;

            while ( --i )
            {
                particle = new Particle();
                particle.next = nextParticle;
                particle.x    = BMD_RECT.width * Math.random();
                particle.y    = BMD_RECT.height * Math.random();
                particle.col  = 0xFFFF*Math.random();
                nextParticle  = particle;
            }
            firstParticle = particle;

            scaleX = scaleY = 2;

            addEventListener( Event.ENTER_FRAME, render );
        }

        private function createNoise():void
        {
            mapBitmapData.perlinNoise( BMD_RECT.width, BMD_RECT.height, 2, 2, true, false, BitmapDataChannel.GREEN|BitmapDataChannel.BLUE );
            map = mapBitmapData.getVector( BMD_RECT );
        }

        private function render( e:Event ):void
        {
            if ( Config.DEBUG )
                handleKeyboardInput();

            bitmapData.lock();
            bitmapData.fillRect( BMD_RECT, 0x000000 );

            //read data from bitmap
            var v:Vector.<uint> = bitmapData.getVector( BMD_RECT );

            var particle:Particle = firstParticle;

            while ( particle )
            {
                var mapCol:uint = map[ BMD_RECT.width * int( particle.y ) + int( particle.x )];
                var mapX:uint   = mapCol>>8 & 0xFF;
                var mapY:uint   = mapCol & 0xFF;
                particle.x     += ( mapX - _displacement ) * _divider;
                particle.y     += ( mapY - _displacement ) * _divider;

                if ( particle.x < 0 )
                    particle.x += BMD_RECT.width;
                else if ( particle.x >= BMD_RECT.width )
                    particle.x -= BMD_RECT.width;
                if ( particle.y < 0 )
                    particle.y += BMD_RECT.height;
                else if ( particle.y >= BMD_RECT.height )
                    particle.y -= BMD_RECT.height;

                v[ BMD_RECT.width * int( particle.y ) + int( particle.x )] = ( beat ) ? 0xFFFFFF : particle.col;

                particle = particle.next;
            }

            bitmapData.setVector( BMD_RECT, v );
            bitmapData.unlock();
        }

        private function get divider():int
        {
            return _dividerValue;
        }

        private function set divider( value:int ):void
        {
            _dividerValue = value;
            _divider = 1 / _dividerValue;
        }

        private function handleKeyboardInput():void
        {
            if ( Input.instance.isKeyDown( KeyCode.UP ))
            {
                if ( divider > 1 )
                    --divider;
                if ( divider < 5 )
                    activateRestoreTimer();
            }
            if ( Input.instance.isKeyDown( KeyCode.DOWN ))
            {
                if ( divider < 64 )
                    ++divider;
            }
            if ( Input.instance.isKeyDown( KeyCode.LEFT ))
                --_displacement;

            if ( Input.instance.isKeyDown( KeyCode.RIGHT ))
                ++_displacement;
        }

        private function activateRestoreTimer():void
        {
            clearInterval( ival );
            ival = setInterval( function():void
            {
                clearInterval( ival );
                divider = 64;

                var p:Particle = firstParticle;
                while ( p )
                {
                    p.x = BMD_RECT.width * Math.random();
                    p.y = BMD_RECT.height * Math.random ();
                    p = p.next;
                }
                bitmapData.fillRect( BMD_RECT, 0xFFFFFF );
            }, 1000 );
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );

            if ( data.playbacksize > -1 ) {
                divider = 64 - MathTool.scale( data.playbacksize, 127, 63 );
                if ( divider < 5 )
                    activateRestoreTimer();
                else
                    clearInterval( ival );
            }
            if ( data.envfollow > -1 )
                beat = thresholdCalculator.measure( data.envfollow );

            if ( data.momsw > -1 )
            {
                divider = 64 - MathTool.scale( data.momIndex, 127, 63 );
            }
        }

        override public function destroy():void
        {
            removeEventListener( Event.ENTER_FRAME, render );

            clearInterval( ival );

            bitmapData.dispose();
            mapBitmapData.dispose();

            super.destroy();
        }
    }
}
