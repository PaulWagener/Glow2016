
import org.openkinect.processing.*; //<>//

Kinect2 kinect2;

void setup() {
  size(1024, 848, P2D);

  kinect2 = new Kinect2(this);
  kinect2.initDepth();
  kinect2.initDevice();
}

public int depthWidth = 512;
public int depthHeight = 424;
PImage depthImg = createImage(depthWidth, depthHeight, PImage.ALPHA);

void draw() {
  background(0, 0, 0);
  
  int[] depthRawData = kinect2.getRawDepth();
  arrayCopy(depthRawData, 0, depthImg.pixels, 0, depthImg.width * depthImg.height);
  depthImg.updatePixels();
  image(depthImg, 0, 0);
}