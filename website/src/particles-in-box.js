const THREE = require('three');
const get = require('lodash.get');
const OrbitControls = require('three-orbit-controls')(THREE)
const variables = require('./variables');
const properties = new Map(variables.spheres.properties);
console.debug(variables);
var renderer = new THREE.WebGLRenderer();
container = document.getElementById('canvas');
container.appendChild(renderer.domElement);
console.debug(`NODE_ENV: ${process.env.NODE_ENV}`);
const WIDTH = container.clientWidth;
const HEIGHT = container.clientHeight;
console.debug(`WIDTH/HEIGHT: ${WIDTH}/${HEIGHT}`);

/**
 * The size should be a square of size the same same length as the smallest size.
 */
let diff = WIDTH < HEIGHT ? WIDTH : HEIGHT;
window.onresize = (event) => {
  diff = WIDTH < HEIGHT ? WIDTH : HEIGHT;
  console.debug(`--RESIZE-- diff: ${diff}`);
};
console.debug(`DIFF: ${diff}`);

process.env.CAMERA = {
  FOV: 75,
  NEAR: 0.1,
  FAR: 1000
};
process.env.RENDERER = {
  X: WIDTH,
  Y: HEIGHT
};
var scene = new THREE.Scene();
var camera = new THREE.PerspectiveCamera(process.env.CAMERA.FOV, WIDTH / HEIGHT, process.env.CAMERA.NEAR, process.env.CAMERA.FAR);
renderer.setSize(process.env.RENDERER.X, process.env.RENDERER.Y);
camera.position.z = -50;
controls = new OrbitControls(camera);
controls.target.set(0, 0, 0)

const indexToSphereMeshs = createSpheres();
// var box = new THREE.BoxGeometry( variables.box.width, variables.box.height, variables.box.depth, variables.box.widthSegments, variables.box.heightSegment, variables.box.depthSegment  );
// var material = new THREE.MeshBasicMaterial( {color: variables.box.color} );
// var cube = new THREE.Mesh( box, material );
// cube.position.set(variables.box.position.x,variables.box.position.y,variables.box.position.z);
// scene.add( cube );

var animate = function () {
  requestAnimationFrame(animate);
  particleSimulation(indexToSphereMeshs);
  // spheres[0].rotation.x += 0.01;
  // spheres[0].rotation.y += 0.01;

  renderer.render(scene, camera);
};

animate();

function createSpheres() {
  const sphereMeshs = new Map();
  for (let i = 0; i < variables.spheres.number; i++) {
    const color = getSafe(i, 'color');
    // const color = properties.has(i) && properties.get(i).color ? properties.get(i).color : info.initial.color
    const material = new THREE.MeshBasicMaterial({
      color: color
    });
    const sphereGeometry = new THREE.SphereGeometry(
      variables.spheres.initial.radius,
      variables.spheres.initial.widthSegments,
      variables.spheres.initial.heightSegments,
      variables.spheres.initial.phiStart,
      variables.spheres.initial.phiLength,
      variables.spheres.initial.thetaStart,
      variables.spheres.initial.thetaLength
    );
    const sphereMesh = new THREE.Mesh(sphereGeometry, material)
    // sphereMesh.position.set(getRandom(),getRandom(),getRandom());
    console.debug(sphereMesh.getWorldPosition());
    scene.add(sphereMesh);
    sphereMeshs.set(i, sphereMesh);
    sphereMeshs.get(i).position.set(getSafe(i, 'position.x'), getSafe(i, 'position.y'), getSafe(i, 'position.z'));
  }
  // sphereMeshs.get(1).position.set(0, 20, 0);
  // sphereMeshs.get(2).position.set(0, 0, 20);
  return sphereMeshs;
}

function particleSimulation(indexToSphereMeshs) {
  for (let sphere of indexToSphereMeshs.entries()) {

  }
}

function getRandom() {
  return Math.random() * diff / 2;
}
function getSafe(i,prop) {
  if(properties.has(i)) {
    const property = properties.get(i);
    let variable = get(property, prop);
    return variable;
  } else {
    console.debug('No properties found so use defaults');
    let variable = get(variables.spheres.initial, prop);
    if (!variable) {
      throw Error('Missing Info');
    }
    return variable;
  }
}