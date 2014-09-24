package away3d.core.pool {
    public interface IMaterialData {
        function dispose():void;

        function invalidateMaterial():void;

        function invalidateAnimation():void;
    }
}
