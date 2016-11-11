
import org.openkinect.processing.*; //<>//
import gab.opencv.*;
import org.opencv.core.*;
import org.opencv.photo.*;
import org.opencv.video.*;
import org.opencv.imgproc.*;

// Stuff to get the depth image
Kinect2 kinect2;
Mat depthDataInts, depthData;
Mat depthDataInvalidMask;
Mat previous;
final int DEPTH_WIDTH = 512;
final int DEPTH_HEIGHT = 424;
final int NUM_PIXELS = DEPTH_WIDTH * DEPTH_HEIGHT;

OpenCV opencv;
Mat flowGhosting;
PShader shader;
PGraphics main, test;

void setup() {
  //fullScreen(2);
  size(512, 424, P3D);
  opencv = new OpenCV(this, 1, 1); // Used for initializing stuff
  depthDataInts = new Mat(DEPTH_HEIGHT, DEPTH_WIDTH, CvType.CV_32S);
  depthData = new Mat();
  depthDataInvalidMask = new Mat();
  main = createGraphics(width, height, P3D);
  test = createGraphics(100, 100, P3D);
  
  shader = loadShader("fragment.glsl", "vertex.glsl");
  shader.set("flow", loadImage("flow.png"));

  kinect2 = new Kinect2(this);
  kinect2.initDepth();
  kinect2.initDevice();
}

void draw() {
  /*
  background(0, 0, 0);
  
  // Update Kinect and process it to a small image
  depthDataInts.put(0, 0, kinect2.getRawDepth());
  depthDataInts.convertTo(depthData, CvType.CV_8U, 1.0/4500.0*255.0); // These values may need to be finetuned
  
  // Downsample
  Imgproc.resize(depthData, depthData, new Size(150, 100), 0, 0, Imgproc.INTER_NEAREST);

  // Filter out noise
  Imgproc.threshold(depthData, depthDataInvalidMask, 0, 255, Imgproc.THRESH_BINARY_INV);
  Photo.inpaint(depthData, depthDataInvalidMask, depthData, 3, Photo.INPAINT_TELEA);
  Imgproc.blur(depthData, depthData, new Size(5, 5));
  
  // Calculate optical flow
  if(previous == null) {
    previous = depthData;
  }
  Mat flow = new Mat();
  Video.calcOpticalFlowFarneback(previous, depthData, flow, 0.5, 4, 20, 2, 9, 1.8, 0);
  
  // Save previous
  previous = depthData.clone();
  
  if(flowGhosting == null) {
    flowGhosting = flow.clone();
  }
  
  Core.addWeighted(flowGhosting, 1.0, flow, 0.5, 0.0, flowGhosting);
  Core.multiply(flowGhosting, new Scalar(0.97, 0.97), flowGhosting);
  
  ArrayList<Mat> channels = new ArrayList<Mat>();
  Core.split(flowGhosting, channels);
  Mat xFlow = channels.get(1);
  xFlow.convertTo(xFlow, CvType.CV_8U, 150, 128);
  // Debug
  showMat(xFlow);
 //*/
 
  //*
  test.beginDraw();
  {
    test.background(128);
    test.image(loadImage("rainbow.jpg"), 25, 25, 50, 50);
  }
  test.endDraw(); 
  
  
  main.beginDraw();
  {
    pushMatrix();
    background(0, 0, 0, 128);
    
    ortho();
    scale(width, height);
    fill(0, 0, 255);
    shader(shader);
      
    beginShape(QUADS);
    final int X_DIVISIONS = 30;
    final int Y_DIVISIONS = 30;
    final float X_STRIDE = 1.0/(float)X_DIVISIONS;
    final float Y_STRIDE = 1.0/(float)Y_DIVISIONS;
    
    for(float x = 0; x < 1.0; x += X_STRIDE) {
      for(float y = 0; y < 1.0; y += Y_STRIDE) {
        final float S = 0.0;
        vertex(x+S, y + Y_STRIDE);
        vertex(x + X_STRIDE, y + Y_STRIDE);
        vertex(x + X_STRIDE, y+S);
        vertex(x+S, y+S);
      }
    }
    endShape();
    resetShader();
    popMatrix();
  }
  main.endDraw();
  
  
  //*/
  background(0);
  noFill();
  noStroke();
  //shader.set("prevRender", main);
  
  ortho();
  image(main, 0, 0, width/2, height/2);
  image(test, width/2, 0, width/2, height/2);
  
  
}

/**
 * Debug method to make Mat's visible, not very efficient!
 */
 void showMat(Mat m) {
   image(Mat2PImage(m), 0, 0);
 }
 
 /**
  * Convert an OpenCV Mat to a PImage (assumes 1 channel)
  */
PImage Mat2PImage(Mat m) {
  Mat intMat = new Mat();
  m.convertTo(intMat, CvType.CV_32S);
  
  PImage image = new PImage(m.width(), m.height(), PImage.ALPHA);
  int[] matPixels = new int[m.width() * m.height()];
  intMat.get(0, 0, matPixels);
  
  arrayCopy(matPixels, 0, image.pixels, 0, m.width() * m.height());
  image.updatePixels();
  return image;
}