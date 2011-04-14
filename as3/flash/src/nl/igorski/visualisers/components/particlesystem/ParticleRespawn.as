package nl.igorski.visualisers.components.particlesystem
{
    import flash.display.BitmapData;

    final public class ParticleRespawn  {

        public var x:Number;
        public var y:Number;
        public var velX:Number;
        public var velY:Number;
        public var spawnX:Number;
        public var spawnY:Number;
        public var next:ParticleRespawn;

        public function ParticleRespawn(x:Number, y:Number, velX:Number, velY:Number) {
            this.spawnX = this.x = x;
            this.spawnY = this.y = y;
            this.velX = velX;
            this.velY = velY;
        }

    }
}
