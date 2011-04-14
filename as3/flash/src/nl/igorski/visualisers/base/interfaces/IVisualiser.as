package nl.igorski.visualisers.base.interfaces 
{  
    import nl.igorski.models.vo.VOLive;
    /**
     * ...
     * @author Igor Zinken
     */
    public interface IVisualiser 
    {
        function process( data:VOLive ):void
        function special():void
        function destroy():void
    }
}
