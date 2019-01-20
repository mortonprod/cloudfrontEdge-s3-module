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
var box = new THREE.BoxGeometry( variables.box.width, variables.box.height, variables.box.depth, variables.box.widthSegments, variables.box.heightSegment, variables.box.depthSegment  );
var material = new THREE.MeshBasicMaterial( {color: variables.box.color} );
var cube = new THREE.Mesh( box, material );
cube.position.set(variables.box.position.x,variables.box.position.y,variables.box.position.z);
scene.add( cube );


camera.position.z = -50;

controls = new OrbitControls( camera );
controls.target.set( 0, 0, 0 )

var animate = function () {
  requestAnimationFrame( animate );

  // spheres[0].rotation.x += 0.01;
  // spheres[0].rotation.y += 0.01;

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
      const sphe = new THREE.Mesh( sphereGeo, material)
      sphe.position.set(0,0,0);
      scene.add(sphe);
      return sphe;
  });
}