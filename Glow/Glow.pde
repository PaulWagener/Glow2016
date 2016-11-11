
import org.openkinect.processing.*; //<>//
import gab.opencv.*;
import org.opencv.core.*;
import org.opencv.photo.*;
import org.opencv.video.*;
import org.opencv.imgproc.*;
import java.nio.*;
import g4p_controls.*;

// Stuff to get the depth image
Kinect2 kinect2;
Mat depthDataInts, depthData;
Mat depthDataInvalidMask;
Mat previous;

// Kinect dimensions
final int DEPTH_WIDTH = 512;
final int DEPTH_HEIGHT = 424;
final int NUM_PIXELS = DEPTH_WIDTH * DEPTH_HEIGHT;

OpenCV opencv;
Mat flowGhosting;
PShader shader;
PGraphics main, test;

boolean debug = false;
boolean calibrateKinect = false;

void settings() {
  if(debug && !calibrateKinect) {
    size(800, 600, P3D);
  } else {
    fullScreen(P3D, 2);
  }
}


void setup() {
   
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
  background(0);
  
  // Update Kinect and process it to a small image
  depthDataInts.put(0, 0, kinect2.getRawDepth());
  depthDataInts.convertTo(depthData, CvType.CV_8U, 1.0/4500.0*255.0); // These values may need to be finetuned
  Core.flip(depthData, depthData, 1);
  
  if(calibrateKinect) {
    image(Mat2PImage(depthData), 0, 0, width, height);
    return;
  }
  //*
  // Downsample
  Imgproc.resize(depthData, depthData, new Size(250, 200), 0, 0, Imgproc.INTER_NEAREST);

  // Filter out noise
  Imgproc.threshold(depthData, depthDataInvalidMask, 0, 255, Imgproc.THRESH_BINARY_INV);
  depthData.setTo(new Scalar(230.0), depthDataInvalidMask);
  //Photo.inpaint(depthData, depthDataInvalidMask, depthData, 3, Photo.INPAINT_TELEA);
  //Imgproc.blur(depthData, depthData, new Size(15, 15));
  
  // Processed image
  if(debug) {
    image(Mat2PImage(depthData), 0, 0, width/2, height/2);
  }
  
  // Calculate optical flow
  if(previous == null) {
    previous = depthData;
  }
  Mat flow = new Mat();
  Video.calcOpticalFlowFarneback(previous, depthData, flow, 0.5, 4, 20, 2, 9, 1.8, 0);
  
  if(debug) {
    image(FlowMat2PImage(flow), width/2, 0, width/2, height/2);
  }
  
  // Save previous
  previous = depthData.clone();
  
  if(flowGhosting == null) {
    flowGhosting = flow.clone();
  }
  
  Core.addWeighted(flowGhosting, 1.0, flow, 0.5, 0.0, flowGhosting);
  Core.multiply(flowGhosting, new Scalar(0.97, 0.97), flowGhosting);
  
  PImage flowImage = FlowMat2PImage(flowGhosting);
  shader.set("flow", flowImage);
  if(debug) {
    image(flowImage, 0, height/2, width/2, height/2);
  }
  
  shader.set("prevRender", main);
  main.beginDraw();
  {
    main.background(0);
    main.noStroke();
    //*
    main.ortho();
    main.scale(width, height);
    main.shader(shader);
    
    main.beginShape(QUADS);
    final int X_DIVISIONS = 30;
    final int Y_DIVISIONS = 30;
    final float X_STRIDE = 1.0/(float)X_DIVISIONS;
    final float Y_STRIDE = 1.0/(float)Y_DIVISIONS;
    
    for(float x = 0; x < 1.0; x += X_STRIDE) {
      for(float y = 0; y < 1.0; y += Y_STRIDE) {
        final float S = 0.0;
        main.vertex(x+S, y + Y_STRIDE);
        main.vertex(x + X_STRIDE, y + Y_STRIDE);
        main.vertex(x + X_STRIDE, y+S);
        main.vertex(x+S, y+S);
      }
    }
    
    main.endShape();
    main.resetShader();
    
    // Draw circles!
    
    
    for(int i = 0; i < 100; i++) {
      main.fill(random(10, 255), random(10, 255), random(10, 255));
      float size = random(0, 0.03);
      main.ellipse(random(0, 1), random(0,1), size, size);
    }
  }
  main.endDraw();
  
  if(debug) {
    image(main, width/2, height/2, width/2, height/2);
  } else {
    image(main, 0, 0, width, height);
  }
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

PImage FlowMat2PImage(Mat flow) {
  Mat ones = Mat.ones(flow.size(), CvType.CV_8U);
  Core.multiply(ones, new Scalar(255), ones);
  
  flow = flow.clone();
  // Maybe multiply / divide here?
  Core.multiply(flow, new Scalar(10.0, 10.0), flow);
  Core.add(flow, new Scalar(128.0, 128.0), flow);
  flow.convertTo(flow, CvType.CV_8UC4);
  
  ArrayList<Mat> flowChannels = new ArrayList<Mat>();
  Core.split(flow, flowChannels);
  
  //
  ArrayList<Mat> channels = new ArrayList<Mat>();
  channels.add(ones); // B
  channels.add(flowChannels.get(1)); // G
  channels.add(flowChannels.get(0)); // R
  channels.add(ones); // A
  
  Mat m = new Mat();
  Core.merge(channels, m);
  
  PImage image = new PImage(m.cols(), m.rows(), ARGB);
  
  int[] intPixels = new int[m.rows() * m.cols()];
  byte[] matPixels = new byte[m.rows() * m.cols() * 4];
  m.get(0, 0, matPixels);
  ByteBuffer.wrap(matPixels).order(ByteOrder.LITTLE_ENDIAN).asIntBuffer().get(intPixels);
  image.pixels = intPixels;
  image.updatePixels();
  
  return image;
}