package away3d.primitives {
  import away3d.primitives.WireframePrimitiveBase;


  /**
   * A WireframeTetrahedron primitive mesh
   */
  public class WireframeTetrahedron extends WireframePrimitiveBase {

    public static const ORIENTATION_YZ:String = "yz";
    public static const ORIENTATION_XY:String = "xy";
    public static const ORIENTATION_XZ:String = "xz";

    private var _width:Number;
    private var _height:Number;
    private var _orientation:String;

    /**
     * Creates a new WireframeTetrahedron object.
     * @param width The size of the tetrahedron buttom size.
     * @param height The size of the tetranhedron height.
     * @param color The color of the wireframe lines.
     * @param thickness The thickness of the wireframe lines.
     */
    public function WireframeTetrahedron(width:Number, height:Number, color:uint = 0xffffff, thickness:Number = 1, orientation:String = "yz") {
      super(color, thickness);

      _width = width;
      _height = height;

      _orientation = orientation;
    }
  }
}
