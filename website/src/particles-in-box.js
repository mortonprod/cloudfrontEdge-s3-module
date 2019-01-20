const THREE = require('three');
const OrbitControls = require('three-orbit-controls')(THREE)
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

const spheres = createSpheres(variables.spheres, scene);
// var material = new THREE.MeshBasicMaterial( { color: 'red' } );
// var cube = new THREE.Mesh( spheres[0], material );
// scene.add( createSpheres(variables.spheres) );

camera.position.z = 5;

controls = new OrbitControls( camera );
controls.target.set( 0, 0, 0 )

var animate = function () {
  requestAnimationFrame( animate );

  spheres[0].rotation.x += 0.01;
  spheres[0].rotation.y += 0.01;

  renderer.render( scene, camera );
};

animate();

function createSpheres(spheres,scene) {
  var material = new THREE.MeshBasicMaterial( { color: 'red' } );
  return spheres.map((sphere) => {
    const sphereGeo = new THREE.SphereGeometry(
      sphere.radius, 
      sphere.widthSegments, 
      sphere.heightSegments,
      sphere.phiStart,
      sphere.phiLength,
      sphere.thetaStart,
      sphere.thetaLength
      );
      const geoMat = new THREE.Mesh( sphereGeo, material)
      scene.add(geoMat);
      return geoMat;
  });
}