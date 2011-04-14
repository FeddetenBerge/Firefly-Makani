/**
 * Created by IntelliJ IDEA.
 * User: igorzinken
 * Date: 12-03-11
 * Time: 15:37
 * To change this template use File | Settings | File Templates.
 */
package nl.igorski.visualisers
{
import com.cheezeworld.utils.Input;

import com.cheezeworld.utils.KeyCode;

import flash.display.Sprite;
    import flash.events.Event;
import flash.utils.clearInterval;

import flash.utils.setInterval;

import flash.utils.setTimeout;

import nl.igorski.config.Config;
    import nl.igorski.models.vo.VOLive;
import nl.igorski.utils.MathTool;
import nl.igorski.visualisers.base.BaseVisualiser;

import nl.igorski.visualisers.components.particlesystem.ParticleShape;
import nl.igorski.visualisers.helpers.ThresholdCalculator;

public final class ParticleSystemShapes extends BaseVisualiser
    {
        private const PARTICLE_NUMBER   :uint = 250;
        private var particles           :Array/*Vector.<ParticleShape>*/;
        private var firstParticle       :ParticleShape;
        private var container           :Sprite;

        private var _acceleration       :int = 1;
        private var _maxAcceleration    :int = 4;
        private var _mass               :int = 1;

        private var thresholdCalculator :ThresholdCalculator;
        private var _tremble            :Boolean = false;
        private var acceleratorIval     :uint;
        private var massIval            :uint;
        private var trembleIval         :uint;

        public function ParticleSystemShapes()
        {
            addEventListener( Event.ADDED_TO_STAGE, init );
        }

        private function init( e:Event ):void
        {
            removeEventListener( Event.ADDED_TO_STAGE, init );

            thresholdCalculator = new ThresholdCalculator();

            container = new Sprite();
            addChild( container );

            particles = []/*new Vector.<ParticleShape>()*/;

            var i           :int = PARTICLE_NUMBER;
            var particle    :ParticleShape;
            var nextParticle:ParticleShape;

            // repeat until i is false (less than zero)
            while ( --i )
            {
                particle      = new ParticleShape();
                particle.next = nextParticle;
                container.addChild( particle );
                particles.push( particle );
                nextParticle  = particle;
            }
            firstParticle = particle;

            container.x = Config.width * .5 - /*container.*/width * .5 + 125;
            container.y = Config.height * .5 - /*container.*/height * .5 + 125;
            cacheAsBitmap = true;
            addEventListener( Event.ENTER_FRAME, render );
        }

        private function render( e:Event ):void
        {
            if ( Config.DEBUG )
                handleKeyboardInput();

            var particle:ParticleShape = firstParticle;
            while ( particle )
            {
                particle.update( _acceleration, _mass );
                particle = particle.next;
            }
            if ( _tremble )
            {
                x = 20 - MathTool.rand( 0, 40 );
            }
            else {
                x = 0;
            }
             /*
            //depth sort: sort particles by z distance
            particles.sortOn("z", Array.DESCENDING | Array.NUMERIC);
            //add re-add to display list one at a time (particle[0] ends up at the bottom)
            for ( var i:uint = 0; i < PARTICLE_NUMBER; ++i )
            {
                if ( particles[i] != null )
                 addChild( particles[i]);
            }
            */
        }

        private function handleKeyboardInput():void
        {
            if ( Input.instance.isKeyDown( KeyCode.UP ))
            {
                if ( _acceleration < _maxAcceleration )
                {
                    ++_acceleration;
                    setAcceleratorTimeout();
                }
            }
            if ( Input.instance.isKeyDown( KeyCode.DOWN ))
            {
                if ( _acceleration > 1 )
                {
                    --_acceleration;
                    setAcceleratorTimeout();
                }
            }
        }

        private function setAcceleratorTimeout():void
        {
            clearInterval( acceleratorIval );
            clearInterval( massIval );
            acceleratorIval = setInterval( restoreAccelerator, 250 );
        }

        private function restoreAccelerator():void
        {
            clearInterval( acceleratorIval );
            _acceleration = 1;
            setMassTimeout();
        }

        /*
         * temporarily increase mass so particles
         * draw to eachother with a greater force
         */
        private function setMassTimeout():void
        {
            _mass = 5;
            clearInterval( massIval );
            massIval = setInterval( restoreMass, 1000 );
        }

        /*
         * restore mass and restore each particle to it's starting
         * position ( with a slight delay so animation keeps going )
         */
        private function restoreMass():void
        {
            clearInterval( massIval );
            _mass = 1;

            var particle:ParticleShape = firstParticle;
            var i:int = 0;
            while ( particle )
            {
                setTimeout( particle.initPos, i * 1.5 );
                particle = particle.next;
                ++i;
            }
        }

        override public function process( data:VOLive ):void
        {
            super.process( data );

            if ( data.playbacksize > -1 ) {
                _acceleration = 1 + MathTool.scale( data.playbacksize, 127, _maxAcceleration );
                setAcceleratorTimeout();
            }
            if ( data.envfollow > -1 )
            {
                var beat:Boolean = thresholdCalculator.measure( data.envfollow );
                if ( beat ) {
                    var col1:uint = 0xFFFFFF;
                    var col2:uint = 0x666666;
                } else {
                    col1 = 0x00FF00;
                    col2 = 0x006600;
                }
                var particle:ParticleShape = firstParticle;
                while( particle )
                {
                    particle.createShape( col1, col2 );
                    particle = particle.next;
                }
            }
            if ( data.momsw > -1 )
            {
                if ( data.momState )
                    tremble();
            }
        }

        private function tremble():void
        {
            clearInterval( trembleIval );
            trembleIval = setInterval( undoTremble, 1000 );
            _tremble = true;
        }

        private function undoTremble():void
        {
            clearInterval( trembleIval );
            _tremble = false;
        }

        override public function destroy():void
        {
            removeEventListener( Event.ENTER_FRAME, render );

            clearInterval( acceleratorIval );
            clearInterval( massIval );
            clearInterval( trembleIval );

            super.destroy();
        }
    }
}
