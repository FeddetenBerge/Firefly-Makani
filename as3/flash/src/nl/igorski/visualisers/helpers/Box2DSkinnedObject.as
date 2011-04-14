package nl.igorski.visualisers.helpers
{
    import com.actionsnippet.qbox.QuickObject;
    import com.greensock.easing.Sine;
    import com.greensock.TimelineLite;
    import com.greensock.TweenLite;
    import flash.geom.Point;
    import nl.igorski.visualisers.helpers.Box2DHelper;

    public class Box2DSkinnedObject extends EventDispatcher
    {
        /**
        * Created by IntelliJ IDEA.
        * User: igor.zinken
        * Date: 29-dec-2010
        * Time: 11:00:14
        */
        private static var PI_OVER_180  :Number = Math.PI / 180;
        
        private var _quickObject        :QuickObject;
        private var _skin               :*;
        private var _targetPoint        :Point;
        private var _targetAngle        :Number;
        private var _active             :Boolean;
        private var _animating          :Boolean;

        //_________________________________________________________________________________________________________
        //                                                                                    C O N S T R U C T O R
        public function Box2DSkinnedObject( quickObject:QuickObject, skin:* )
        {
           _quickObject                        = quickObject;
           _skin                               = skin;
           _targetPoint                        = new Point( skin.x, skin.y );
           _targetAngle                        = 0.0;
           _active                             = false;
           _animating                          = false;

           quickObject.body.m_angularDamping   = 125;
           quickObject.bodyDef.fixedRotation   = true;
           quickObject.body.m_linearDamping    = 6;
           
           // listeners can be added to the skin
        }

        //_________________________________________________________________________________________________________
        //                                                                                              P U B L I C

        public function animateTo( point:Point, angle:Number = 0, speed:Number = 1, delay:Number = 0, persist:Boolean = false ):void
        {
           _targetPoint = point;
           _targetAngle = angle;
           _animating   = true;

           var callback :Function = updateLoc;

           /** if this animation is part of a larger cycle, we set a timeout to restart
               this animation, to make sure the object ends up at the correct position
               ( as it might have collided with other objects in the animation altering it's end point )
            */
           if ( persist )
           {
               callback = function():void
               {
                   animateTo( point, angle, speed * .15, 1.5 );
               }
           }
           var ani:TimelineLite = new TimelineLite();

           ani.appendMultiple( [
               TweenLite.to( _quickObject, speed, { x: Box2DHelper.p2m( point.x ), ease: Sine.easeIn } ),
               TweenLite.to( _quickObject, speed, { y: Box2DHelper.p2m( point.y ), ease: Sine.easeIn, onComplete: callback } )
                               ], delay );
        }

        public function rotateTo( aAngle:Number = 0.0, speed:Number = .65 ):void
        {
           TweenLite.to( this, speed, { angle: aAngle, ease: Sine.easeIn, onComplete: function():void
               {
                   _animating = false;
               }
           });
        }

        public function destroy():void
        {
           removeListeners();
           _quickObject.destroy();
        }

        //_________________________________________________________________________________________________________
        //                                                                        G E T T E R S   /   S E T T E R S

        public function get quickObject():QuickObject
        {
           return _quickObject;
        }

        public function get skin():*
        {
           return _skin;
        }

        public function get animating():Boolean
        {
           return _animating;
        }

        /**
        * position of this object should be applied to it's body
        * these getters / setters take care of this, including the
        * box2D metric conversion for x and y coordinates
        */

        public function get x():Number
        {
           return Box2DHelper.m2p( quickObject.x );
        }

        public function set x( value:Number ):void
        {
           quickObject.setLoc( Box2DHelper.p2m( value ), quickObject.y );
        }

        public function get y():Number
        {
           return Box2DHelper.m2p( quickObject.y );
        }

        public function set y( value:Number ):void
        {
           quickObject.setLoc( quickObject.x, Box2DHelper.p2m( value ) );
        }

        /**
        * angles in Box2D are in radians, these getters/setters
        * convert them to more Flash friendly degrees
        */
        public function get angle():Number
        {
           return quickObject.body.GetAngle() / PI_OVER_180;
        }

        public function set angle( value:Number ):void
        {
           quickObject.bodyDef.fixedRotation = false;
           quickObject.body.SetXForm( quickObject.body.GetPosition(), value * PI_OVER_180 );
           quickObject.bodyDef.fixedRotation = true;
        }

        //_________________________________________________________________________________________________________
        //                                                                              E V E N T   H A N D L E R S

        private function updateLoc():void
        {
           quickObject.setLoc( Box2DHelper.p2m( _targetPoint.x ), Box2DHelper.p2m( _targetPoint.y ));
           rotateTo( _targetAngle );
        }

        //_________________________________________________________________________________________________________
        //                                                                        P R O T E C T E D   M E T H O D S

        //_________________________________________________________________________________________________________
        //                                                                            P R I V A T E   M E T H O D S

    }
}
