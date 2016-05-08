/**
 * Background Subtraction 
 * by Golan Levin. 
 *
 * Detect the presence of people and objects in the frame using a simple
 * background-subtraction technique. To initialize the background, press a key.
 */


import processing.video.*;
import processing.serial.*;
import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress myRemoteLocation;

int threshold=100;
int numPixels;
int[] backgroundPixels;
Movie movie;
PImage photo;
Serial myPort;
String inString;
float inFloat;
float movSpeed = 1;
int lf = 10;

void setup() {
  size(640, 480);
  photo = loadImage("train2.png");
  
  osc = new OscP5(this,3000);
  myRemoteLocation = new NetAddress("127.0.0.1",3000);  
  
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil(lf);

  // This the default video input, see the GettingStartedCapture 
  // example if it creates an error
  //video = new Capture(this, 160, 120);
  movie = new Movie(this, "MVI_2713.MP4");
  movie.loop();
  movie.speed(movSpeed);

  // Start capturing the images from the camera
  
  movie.volume(0); //turn off the audio in the movie


  numPixels = photo.width * photo.height;
  backgroundPixels= new int  [numPixels];
  // Create array to store the background image
  photo.loadPixels();
  println(numPixels, photo.pixels.length);
  arraycopy(photo.pixels, backgroundPixels);

  // Make the pixels[] array available for direct manipulation
  loadPixels();
}

void mouseMoved() {
  threshold =  mouseX;
}

void serialEvent (Serial p) {
 inString = p.readString();
 if(inString != null){ // check to make sure the string read isn't empty
   inString = trim(inString); // Trim the end off the string so it doesn't corrupt the program
   inFloat = float(inString)+1; // convert the string read over serial to a float
   inFloat = map(inFloat,1,1024,-2,2); // map the new serial number to a playback speed (max of 2, minimum of 0.2)
   println("Playback speed: " + inFloat + "x");
 }
}

void draw() {
  
  
 
  if (movie.available()) {
    movie.read();
    movie.speed(inFloat); // adjust the playback speed based on the serial value
    //println("running at ", frameRate);
    if (movie.time() <1 && inFloat<0){
      movie.jump(movie.duration()-1);
    }
    //video.read(); // Read a new video frame
    movie.loadPixels(); // Make the pixels of video available
    // Difference between the current frame and the stored background
    int presenceSum = 0;
    for (int i = 0; i < numPixels; i++) { // For each pixel in the video frame...
      // Fetch the current color in that location, and also the color
      // of the background in that spot
      color currColor = movie.pixels[i];
      color bkgdColor = backgroundPixels[i];
      // Extract the red, green, and blue components of the current pixel's color
      int currR = (currColor >> 16) & 0xFF;
      int currG = (currColor >> 8) & 0xFF;
      int currB = currColor & 0xFF;
      // Extract the red, green, and blue components of the background pixel's color
      int bkgdR = (bkgdColor >> 16) & 0xFF;
      int bkgdG = (bkgdColor >> 8) & 0xFF;
      int bkgdB = bkgdColor & 0xFF;
      // Compute the difference of the red, green, and blue values
      int diffR = abs(currR - bkgdR);
      int diffG = abs(currG - bkgdG);
      int diffB = abs(currB - bkgdB);
      // Add these differences to the running tally
      presenceSum += diffR + diffG + diffB;

      int differenceThisFrame= diffR + diffG + diffB;

      // Render the difference image to the screen

      pixels[i] = color(diffR, diffG, diffB);

      //if (differenceThisFrame>threshold) {
      //  pixels[i]=color(255, 255, 255);
      //} else {
      //  pixels[i]=color(0, 0, 0);
      //}
      // The following line does the same thing much faster, but is more technical
      //pixels[i] = 0xFF000000 | (diffR << 16) | (diffG << 8) | diffB;
    }
    updatePixels(); // Notify that the pixels[] array has changed
    //  println(presenceSum); // Print out the total amount of movement
  }
}

// When a key is pressed, capture the background image into the backgroundPixels
// buffer, by copying each of the current frame's pixels into it.

//void movieEvent(Movie m) {
//  println("movie event called");
//  m.read();
//}