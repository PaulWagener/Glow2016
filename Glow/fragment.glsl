
uniform sampler2D flow;
varying vec2 flowPosition;
uniform sampler2D prevRender;

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {

  gl_FragColor = vec4(flowPosition.x, flowPosition.y, 0.3, 1);//;


  // Draw a green warp grid accros
  if(int(flowPosition.x * 300) % 10 == 0
  || int(flowPosition.y * 300) % 10 == 0) {
    gl_FragColor = vec4(0, 1, 0, 1);
  }

  //gl_FragColor += texture2D(flow, flowPosition.st);
  //vec4(1.0, 0.0, 0.0, 0.5);
}