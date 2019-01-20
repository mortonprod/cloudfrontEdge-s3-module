const variables = require('./variables');
process.env.CAMERA = {
  FOV: 75,
  NEAR: 0.1,
  FAR: 1000
};

process.env.RENDERER = {
  X: window.innerWidth,
  Y: window.innerHeight
};
var scene = new THREE.Scene();
var camera = new THREE.PerspectiveCamera(process.env.CAMERA.FOV, window.innerWidth/window.innerHeight, process.env.CAMERA.NEAR, process.env.CAMERA.FAR);

var renderer = new THREE.WebGLRenderer();
renderer.setSize( process.env.RENDERER.X, process.env.RENDERER.Y);
document.body.appendChild( renderer.domElement );

var spheres = createSpheres(variables.spheres);
var material = new THREE.MeshBasicMaterial( { color: 'red' } );
var cube = new THREE.Mesh( spheres[0], material );
var light = new THREE.PointLight( 'green', 1, 100 );
light.position.set( 10, 10, 10 );
scene.add( light );
scene.add( cube );

camera.position.z = 5;

var animate = function () {
  requestAnimationFrame( animate );

  cube.rotation.x += 0.01;
  cube.rotation.y += 0.01;

  renderer.render( scene, camera );
};

animate();

function createSpheres(spheres) {
  return spheres.map((sphere) => {
    return new THREE.SphereGeometry(
      sphere.radius, 
      sphere.widthSegments, 
      sphere.heightSegments,
      sphere.phiStart,
      sphere.phiLength,
      sphere.thetaStart,
      sphere.thetaLength
      );
  });
}