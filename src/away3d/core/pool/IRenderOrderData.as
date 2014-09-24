package away3d.core.pool {
    public interface IRenderOrderData {
        function dispose():void;

        function reset():void;

        function invalidate():void;
    }
}
