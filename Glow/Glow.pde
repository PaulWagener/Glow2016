
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
void setup() {
  //fullScreen(2);
  size(512, 424, P3D);
  opencv = new OpenCV(this, 1, 1); // Used for initializing stuff
  depthDataInts = new Mat(DEPTH_HEIGHT, DEPTH_WIDTH, CvType.CV_32S);
  depthData = new Mat();
  depthDataInvalidMask = new Mat();

  kinect2 = new Kinect2(this);
  kinect2.initDepth();
  kinect2.initDevice();
}

Mat flowGhosting;

float angle;
void draw() {
  //*
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
  Core.multiply(flowGhosting, new Scalar(0.9, 0.9), flowGhosting);
  
  ArrayList<Mat> channels = new ArrayList<Mat>();
  Core.split(flowGhosting, channels);
  Mat xFlow = channels.get(1);
  xFlow.convertTo(xFlow, CvType.CV_8U, 150, 128);
  // Debug
  showMat(xFlow);
 //*/
 
  /*
  background(0);
  
  camera(width/2, height/2, 300, width/2, height/2, 0, 0, 1, 0);
  pointLight(200, 200, 200, width/2, height/2, -200);
  
  translate(width/2, height/2);
  rotateY(angle);
  
  beginShape(QUADS);
  normal(0, 0, 1);
  fill(50, 50, 200);
  vertex(-100, +100);
  vertex(+100, +100);
  fill(200, 50, 50);
  vertex(+100, -100);
  vertex(-100, -100);
  endShape();  
  
  angle += 0.01;
  //*/
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