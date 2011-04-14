/**
 * Created by IntelliJ IDEA.
 * User: igorzinken
 * Date: 12-03-11
 * Time: 18:39
 * To change this template use File | Settings | File Templates.
 */
package nl.igorski.visualisers
{
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Shader;
import flash.events.Event;

import flash.filters.ShaderFilter;
import flash.geom.Rectangle;

import flash.utils.ByteArray;

import flash.utils.clearInterval;
import flash.utils.getDefinitionByName;

import flash.utils.setInterval;

import nl.igorski.config.Config;
import nl.igorski.definitions.Videos;
import nl.igorski.managers.VideoManager;
import nl.igorski.models.vo.VOLive;
import nl.igorski.utils.MathTool;
import nl.igorski.visualisers.base.BaseVisualiser;
import nl.igorski.visualisers.components.particlesystem.ParticleRespawn;
import nl.igorski.visualisers.components.videovisualiser.BitmapVideo;
import nl.igorski.visualisers.helpers.ThresholdCalculator;

    public final class ParticleSystemVideo extends BaseVisualiser
    {
        private var video               :BitmapVideo;
        private var count               :int = 0;
        private var duration            :Number;

        private const PARTICLE_NUMBER   :uint    = 30000;
        private var particlesCreated    :Boolean = false;

        private var firstParticle       :ParticleRespawn;
        private var bitmapData          :BitmapData;

        private var bitmap              :Bitmap;
        private var bitmapRect          :Rectangle;
        private var velocityVector      :Vector.<uint>;

        private var thresholdCalculator :ThresholdCalculator;
        private var stutterInterval     :uint;
        private var counter             :int;
        private var stutterRestorePoint :Number;
        private var stutterLock         :Boolean = false;

        private const SCALE             :Number = 1.5;
        private var MASK                :Bitmap = new Bitmap( new VideoMask( 0, 0 ));

        [Embed("../../../../lib/pixel bender/VelocityConverter.pbj", mimeType="application/octet-stream")]
        private static var VelocityConverter:Class;

        public function ParticleSystemVideo()
        {
            addEventListener( Event.ADDED_TO_STAGE, init );
        }

        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );

            scaleX = scaleY = SCALE;
            MASK.scaleX =
            MASK.scaleY = 1 / scaleX;

            addChild( MASK );

            thresholdCalculator = new ThresholdCalculator();

            loadMovie();
        }

        private function createParticles():void
        {
            var particle        :ParticleRespawn;
            var previousParticle:ParticleRespawn;

            for( var i:uint = 0; i < PARTICLE_NUMBER; ++i )
            {
                particle = new ParticleRespawn( Math.random() * bitmapData.width, Math.random() * bitmapData.height , Math.random() * 2 - 1, Math.random() * 2 - 1 );
                particle.next    = previousParticle;
                previousParticle = particle;
            }
            firstParticle    = particle;
            particlesCreated = true;
        }

        private function loadMovie( inCount:int = -1 ):void
        {
            if ( inCount == -1 )
                inCount = ( Videos.videos.length > 1 ) ? MathTool.rand( 0, Videos.videos.length - 1 ) : 0;

            count = inCount;

            // video wasn't cached yet ? cache it to bitmaps
            if ( VideoManager.getVideo( Videos.videos[ count ] ) == null )
            {
                var vidClass:Class = getDefinitionByName( Videos.videos[ count ] ) as Class;
                video = new BitmapVideo( new vidClass());
                video.addEventListener( BitmapVideo.READY, startRender, false, 0, true );
                video.draw();
            }
            // video was cached, retrieve it's contents from the VideoManager
            else {
                video = VideoManager.getVideo( Videos.videos[ count ] );
                startRender( null );
            }
        }

        private function startRender( e:Event ):void
        {
            if ( video.hasEventListener( BitmapVideo.READY ))
            {
                video.removeEventListener( BitmapVideo.READY, startRender );
                VideoManager.setVideo( Videos.videos[ count ], video ); // cache video
            }
            duration = video.totalFrames;
            video.currentCount = 0;

            // create the canvas to draw on
            bitmapData = new BitmapData( 500, 405, false, 0x000000);
            bitmapRect = bitmapData.rect;
            if ( bitmap == null )
            {
                bitmap = new Bitmap( bitmapData );
                addChild( bitmap );
                swapChildren( bitmap, MASK );
            }
            createMap( video.frame );

            if ( !particlesCreated )
                createParticles();
            try {
                x = Config.width * .5 - ( bitmapData.width * scaleX ) * .5;
                y = Config.height * .5 - ( bitmapData.height * scaleY ) * .5;
            } catch( e:Error )
            {
                // most likely on destroy of previous video
            }
            addEventListener( Event.ENTER_FRAME, render );
        }

        /*
         * creates a new bitmapData object, writes the filter results to it
         * and writes the result into a fast readable vector
         */
        private function createMap( imageMap:BitmapData ):void
        {
            var velocityConverterShader:Shader = new Shader( new VelocityConverter() as ByteArray );
            var velocityConverterFilter:ShaderFilter = new ShaderFilter( velocityConverterShader );
            var perlinVelocityMap      :BitmapData = imageMap;
            //perlinVelocityMap.applyFilter( imageMap, imageMap.rect, imageMap.rect.topLeft, velocityConverterFilter );

            velocityVector = perlinVelocityMap.getVector( perlinVelocityMap.rect );

            perlinVelocityMap.dispose();
            imageMap.dispose();
        }

        private function render( e:Event ):void
        {
            if ( !stutterLock )
                ++video.currentCount;

            if ( video.currentCount >= video.countMax )
            {
                video.currentCount = 0;
                ++video.currentFrame;

                // video reached end, load new
                if ( video.currentFrame > video.totalFrames )
                {
                    removeEventListener( Event.ENTER_FRAME, render );
                    loadMovie();
                    return;
                }
                createMap( video.frame.clone());
            }
            bitmapData.lock();
            bitmapData.fillRect( bitmapRect, 0x000000 );
            var vec:Vector.<uint> = bitmapData.getVector( bitmapRect );

            var w:int = bitmapRect.width;
            var h:int = bitmapRect.height;

            var p:ParticleRespawn = firstParticle;
            var pos:int;
            while ( p )
            {
                p.x += p.velX;
                p.y += p.velY;

                // keep the particles in bounds
                if( p.x > w || p.x < 0 )
                    p.x = p.spawnX;

                if ( p.y > h || p.y < 0 )
                    p.y = p.spawnY;

                // calculate the new position index;
                pos = ( w * int( p.y ) + int( p.x ));

                // draw the pixel
                vec[pos] = velocityVector[ pos ]/*0xFFFFFFFF*/;

                // read the velocityfield at the new particles position
                var velocities:int = velocityVector[ pos ];
                var velXU     :int = (( velocities &0xFF00)>>8)-127.5;
                var velYU     :int = (( velocities )&0xFF)-127.5;

                // add a fraction of the position velocity to the current velocity
                p.velX += velXU * .073;
                p.velY += velYU * .073;

                // dampen the current particle velocity
                p.velX = p.velX * .99;
                p.velY = p.velY * .99;

                p = p.next;
            }
            bitmapData.setVector( bitmapRect, vec );
            bitmapData.unlock();
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );
            var beat:Boolean = false;

            if ( data.envfollow > -1 )
                beat = thresholdCalculator.measure( data.envfollow );

            if ( data.playbacksize > -1 )
              video.currentFrame = video.currentFrame + MathTool.scale( data.playbacksize, 127, ( duration - video.currentFrame ));

            if ( data.momsw > -1 )
            {
                if ( !data.momState )
                    clearInterval( stutterInterval );

                if ( data.momState )
                    stutter( data.momIndex );
            }
        }

        private function stutter( position:Number = -1 ):void
        {
            if ( stutterLock )
                return;

            if ( position < 0 )
                position = video.currentFrame;

            clearInterval( stutterInterval );
            counter             = 0;
            stutterLock         = true;
            stutterRestorePoint = video.currentFrame;

            var targetFrame:int = position - 2;
            if ( targetFrame < 0 )
                targetFrame = 0;

            video.currentFrame  = targetFrame;
            stutterInterval     = setInterval( updateStutterProgress, Config.fps / 60 );
        }

        private function updateStutterProgress():void
        {
            var targetFrame:int = ( video.currentFrame - 2 + ( counter - stutterRestorePoint ));
            if ( targetFrame < 0 )
                targetFrame = MathTool.rand( 0, 5 );

            video.currentFrame = targetFrame;

            if ( ++counter >= Config.fps * .5 )
            {
                clearInterval( stutterInterval );
                video.currentCount = 0;
                video.currentFrame = stutterRestorePoint;
            }
            else {
                if ( counter > 5 )
                    stutterLock = false;
            }
        }

        override public function destroy():void
        {
            removeEventListener( Event.ENTER_FRAME, render );

            clearInterval( stutterInterval );

            if ( bitmapData != null )
                bitmapData.dispose();
            /*
             video.destroy(); // CAUTION: clears cached reference !!
             video = null;
            */
            super.destroy();
        }
    }
}
