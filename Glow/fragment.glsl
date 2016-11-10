
uniform sampler2D flow;
varying vec2 flowPosition;

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {

  gl_FragColor = texture2D(flow, flowPosition.st);
  //vec4(1.0, 0.0, 0.0, 0.5);
}