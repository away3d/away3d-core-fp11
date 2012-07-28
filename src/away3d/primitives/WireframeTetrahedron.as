package away3d.primitives {
  import away3d.primitives.WireframePrimitiveBase;

  /**
   * @author loki
   */
  public class WireframeTetrahedron extends WireframePrimitiveBase {
    public function WireframeTetrahedron(color:uint = 0xffffff, thickness:Number = 1) {
      super(color, thickness);
    }
  }
}
