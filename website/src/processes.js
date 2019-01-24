const THREE = require('three');
const OrbitControls = require('three-orbit-controls')(THREE)
const get = require('lodash.get');
const set = require('lodash.set');

const ID = 'canvas';

const visibleHeightAtZDepth = (depth, camera) => {
  // compensate for cameras not positioned at z=0
  const cameraOffset = camera.position.z;
  if (depth < cameraOffset) depth -= cameraOffset;
  else depth += cameraOffset;

  // vertical fov in radians
  const vFOV = camera.fov * Math.PI / 180;

  // Math.abs to ensure the result is always positive
  return 2 * Math.tan(vFOV / 2) * Math.abs(depth);
};

const visibleWidthAtZDepth = (depth, camera) => {
  const height = visibleHeightAtZDepth(depth, camera);
  return height * camera.aspect;
};

function ParticlesInBox(variables) {
  // Create canvas element and attach to dom
  var renderer = new THREE.WebGLRenderer();
  const container = document.getElementById(ID);
  container.appendChild(renderer.domElement);
  const WIDTH = container.clientWidth;
  const HEIGHT = container.clientHeight;
  var camera = new THREE.PerspectiveCamera(variables.camera.fov, WIDTH / HEIGHT, variables.camera.near, variables.camera.far);
  const depth = variables.camera.initial.position.z;
  const boxWidth = visibleWidthAtZDepth(depth, camera);
  const boxHeight = visibleHeightAtZDepth(depth, camera); 
  console.debug(`WIDTH/HEIGHT: ${WIDTH}/${HEIGHT}`);
  var scene = new THREE.Scene();
  console.debug(`Width/Height: ${boxWidth}/${boxHeight} at visible at depth ${depth}`);
  renderer.setSize(WIDTH, HEIGHT);
  camera.position.z = depth;
  const controls = new OrbitControls(camera); 
  controls.target.set(0, 0, 0)

  // Set properties and object variables. 
  let properties = new Map();
  const indexToObject = new Map();


  const setInitialProperties = () => {
    for (let key = 0; key < variables.spheres.number; key++) {
      if (!properties.has(key)) {
        properties.set(key, {});
      }
      const property = properties.get(key);
      set(property, 'velocity.x', getRandom() * variables.spheres.maxSpeed);
      set(property, 'velocity.y', getRandom() * variables.spheres.maxSpeed);
      set(property, 'velocity.z', getRandom() * variables.spheres.maxSpeed);
      set(property, 'position.x', getRandom() * variables.box.widthFactor * boxWidth);
      set(property, 'position.y', getRandom() * variables.box.heightFactor * boxHeight);
      set(property, 'position.z', getRandom() * variables.box.depth);
      properties.set(key, property);
    }
  }

  const getProperties = () => {
    if(properties.size > 0){
      return properties;
    } else {
      setInitialProperties();
      return properties;
    }
  }
  const updateVelocity = (key, mesh) => {
    const x = mesh.position.x + getSafe(key, 'velocity.x');
    const y = mesh.position.y + getSafe(key, 'velocity.y');
    const z = mesh.position.z + getSafe(key, 'velocity.z');
    mesh.position.set(x, y, z);
  }

  const updateWall = (key, mesh) => {
    let vx = getSafe(key, 'velocity.x');
    let vy = getSafe(key, 'velocity.y');
    let vz = getSafe(key, 'velocity.z');
    if (Math.abs(mesh.position.x) >= variables.box.widthFactor * boxWidth) {
      vx = -1 * vx
      setSafe(key, 'velocity.x', vx);
    }
    if (Math.abs(mesh.position.y) >= variables.box.heightFactor * boxHeight) {
      vy = -1 * vy
      setSafe(key, 'velocity.y', vy);
    }
    if (Math.abs(mesh.position.z) >= variables.box.depth) {
      vz = -1 * vz
      setSafe(key, 'velocity.z', vz);
    }
  }
  const getSafe = (key, prop) => {
    return get(properties.get(key), prop, get(variables.spheres.initial, prop));
  }

  const setSafe = (key, prop, value) => {
    set(properties.get(key), prop, value);
  }
  const stepInTimeObject = (key, mesh) => {
    updateWall(key,mesh);
    updateVelocity(key,mesh);
  }

  const setObjects = () => {
    for (let i = 0; i < variables.spheres.number; i++) {
      const colors = variables.spheres.colors;
      var color = colors[Math.floor(Math.random() * colors.length)];
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
      scene.add(sphereMesh);
      indexToObject.set(i, sphereMesh);
      indexToObject.get(i).position.set(getSafe(i, 'position.x'), getSafe(i, 'position.y'), getSafe(i, 'position.z'));
    }
  }

  const getRandom = () => {
    return -(Math.random() - 0.5);
  }
  setInitialProperties();
  setObjects();
  const update = () => {
    for (let key of indexToObject.keys()) {
      const mesh = indexToObject.get(key);
      stepInTimeObject(key, mesh)
    }
  }
  return {
    update,
    scene,
    camera,
    renderer
  }
}

export {ParticlesInBox}