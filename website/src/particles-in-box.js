const THREE = require('three');
const get = require('lodash.get');
const set = require('lodash.set');
const OrbitControls = require('three-orbit-controls')(THREE)
const variables = require('./variables');


const visibleHeightAtZDepth = ( depth, camera ) => {
  // compensate for cameras not positioned at z=0
  const cameraOffset = camera.position.z;
  if ( depth < cameraOffset ) depth -= cameraOffset;
  else depth += cameraOffset;

  // vertical fov in radians
  const vFOV = camera.fov * Math.PI / 180; 

  // Math.abs to ensure the result is always positive
  return 2 * Math.tan( vFOV / 2 ) * Math.abs( depth );
};

const visibleWidthAtZDepth = ( depth, camera ) => {
  const height = visibleHeightAtZDepth( depth, camera );
  return height * camera.aspect;
};



const properties = new Map(variables.spheres.properties);
setInitialRandomVelocity() 
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
var scene = new THREE.Scene();
var camera = new THREE.PerspectiveCamera(variables.camera.fov, WIDTH / HEIGHT, variables.camera.near, variables.camera.far);
const depth = variables.camera.initial.position.z;
const boxWidth = visibleWidthAtZDepth(depth, camera);
const boxHeight = visibleHeightAtZDepth(depth, camera);
console.debug(`Width/Height: ${boxWidth}/${boxHeight} at visible at depth ${depth}`);
renderer.setSize(WIDTH, HEIGHT);
camera.position.z = variables.camera.initial.position.z;
controls = new OrbitControls(camera);
controls.target.set(0, 0, 0)

// var box = new THREE.BoxGeometry( variables.box.width, variables.box.height, variables.box.depth, variables.box.widthSegments, variables.box.heightSegment, variables.box.depthSegment  );
// var material = new THREE.MeshBasicMaterial( {color: variables.box.color} );
// var cube = new THREE.Mesh( box, material );
// cube.position.set(variables.box.position.x,variables.box.position.y,variables.box.position.z);
// scene.add( cube );

const indexToSphereMeshs = new Map();
createSpheres();
function createSpheres() {
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
    indexToSphereMeshs.set(i, sphereMesh);
    indexToSphereMeshs.get(i).position.set(getSafe(i, 'position.x'), getSafe(i, 'position.y'), getSafe(i, 'position.z'));
  }
  // sphereMeshs.get(1).position.set(0, 20, 0);
  // sphereMeshs.get(2).position.set(0, 0, 20);
  // return indexToSphereMeshs;
}

var animate = function () {
  requestAnimationFrame(animate);
  particleSimulation();
  // spheres[0].rotation.x += 0.01;
  // spheres[0].rotation.y += 0.01;
  
  renderer.render(scene, camera);
};

animate();

function particleSimulation() {
  for (let key of indexToSphereMeshs.keys()) {
    const mesh = indexToSphereMeshs.get(key);
    updateWall(key,mesh);
    updateVelocity(key,mesh);
  }
}

function setRandomPosition(mesh) {
  mesh.position.set(getRandom()/2, getRandom()/2, getRandom()/2);
}

function setInitialRandomVelocity() {
  for(let key of properties.keys()){
    const property = properties.get(key);
    set(property, 'velocity.x', -(Math.random() - 0.5) * variables.spheres.maxSpeed);
    set(property, 'velocity.y', -(Math.random() - 0.5) * variables.spheres.maxSpeed);
    set(property, 'velocity.z', -(Math.random() - 0.5) * variables.spheres.maxSpeed);
    properties.set(key, property);

  }
}

function updateVelocity(key,mesh) {
    const x = mesh.position.x + getSafe(key, 'velocity.x');
    const y = mesh.position.y + getSafe(key, 'velocity.y');
    const z = mesh.position.z + getSafe(key, 'velocity.z');
    mesh.position.set(x, y, z);
}

function updateWall(key,mesh) {
  let vx = getSafe(key, 'velocity.x');
  let vy = getSafe(key, 'velocity.y');
  let vz = getSafe(key, 'velocity.z');
  if (Math.abs(mesh.position.x) >= 0.5*boxWidth) {
    vx = -1*vx
    setSafe(key,'velocity.x',vx);
  }
  if (Math.abs(mesh.position.y) >= 0.5*boxWidth) {
    vy = -1*vy
    setSafe(key,'velocity.y',vy);
  }
  if (Math.abs(mesh.position.z) >= 0.5*boxWidth) {
    vz = -1*vz
    setSafe(key,'velocity.z',vz);
  }
}

function getRandom() {
  return -(Math.random() - 0.5) * boxWidth;
}
function getSafe(i,prop) {
  const temp =  properties.has(i) && get(properties.get(i), prop) ? get(properties.get(i), prop) : get(variables.spheres.initial, prop);
  if (typeof temp === 'undefined') {
    throw Error('Missing Info');
  }
  return temp;
}

function setSafe(key, prop, value) {
  set(properties.get(key), prop, value);
}