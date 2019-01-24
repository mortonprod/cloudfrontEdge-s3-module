const THREE = require('three');
const utils = require('./utils');
const get = require('lodash.get');
const set = require('lodash.set');
const OrbitControls = require('three-orbit-controls')(THREE)
const variables = require('./variables');

// Create canvas scene
var renderer = new THREE.WebGLRenderer();
container = document.getElementById('canvas');
container.appendChild(renderer.domElement);
console.debug(`NODE_ENV: ${process.env.NODE_ENV}`);
const WIDTH = container.clientWidth;
const HEIGHT = container.clientHeight;
console.debug(`WIDTH/HEIGHT: ${WIDTH}/${HEIGHT}`);
var scene = new THREE.Scene();
var camera = new THREE.PerspectiveCamera(variables.camera.fov, WIDTH / HEIGHT, variables.camera.near, variables.camera.far);
const depth = variables.camera.initial.position.z;
const boxWidth = utils.visibleWidthAtZDepth(depth, camera);
const boxHeight = utils.visibleHeightAtZDepth(depth, camera);
console.debug(`Width/Height: ${boxWidth}/${boxHeight} at visible at depth ${depth}`);
renderer.setSize(WIDTH, HEIGHT);
camera.position.z = depth;
controls = new OrbitControls(camera);
controls.target.set(0, 0, 0)

const properties = utils.getProperties(variables, boxWidth, boxHeight);
const indexToSphereMeshs = new Map();
console.debug(`variables: ${JSON.stringify(variables)} properties: ${JSON.stringify([...properties])}`);
createSpheres();

function createSpheres() {
  for (let i = 0; i < variables.spheres.number; i++) {
    const colors = variables.spheres.colors;
    var color = colors[Math.floor(Math.random() * colors.length)];
    // const color = getSafe(i, 'color');
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
    // setRandomPosition(sphereMesh);


    // sphereMesh.position.set(getRandom(),getRandom(),getRandom());
    // console.debug(sphereMesh.getWorldPosition());
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

// function setRandomPosition(mesh) {
//   mesh.position.set(getRandom()/2, getRandom()/2, getRandom()/2);
// }

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
  if (Math.abs(mesh.position.x) >= variables.box.widthFactor*boxWidth) {
    vx = -1*vx
    setSafe(key,'velocity.x',vx);
  }
  if (Math.abs(mesh.position.y) >= variables.box.heightFactor*boxHeight) {
    vy = -1*vy
    setSafe(key,'velocity.y',vy);
  }
  if (Math.abs(mesh.position.z) >= variables.box.depth) {
    vz = -1*vz
    setSafe(key,'velocity.z',vz);
  }
}
function getSafe(key,prop) {
  return get(properties.get(key), prop, get(variables.spheres.initial, prop));
  // const useProperties = properties.has(i) && (typeof get(properties.get(i), prop) !== 'undefined');
  // console.debug(`Property found: ${useProperties} with value: ${get(properties.get(i), prop)}`);
  // const temp =  useProperties ? get(properties.get(i), prop) : get(variables.spheres.initial, prop);
  // console.debug(`From properties or initial defaults: ${temp}`);
  // if (typeof temp === 'undefined') {
  //   throw Error('Missing Info');
  // }
  // return temp;
}

function setSafe(key, prop, value) {
  set(properties.get(key), prop, value);
}