package away3d.core.pool {
    import away3d.materials.passes.IMaterialPass;

    public interface IMaterialPassData {
        function get materialPass():IMaterialPass;

        function dispose():void;
        
        function invalidate():void;
    }
}
