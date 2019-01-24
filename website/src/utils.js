const set = require('lodash.set');
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

const getProperties = (variables, boxWidth, boxHeight) => {
  const properties = new Map();
  // for(let key of properties.keys()){
  for(let key=0; key < variables.spheres.number; key++){
    if(!properties.has(key)) {
      properties.set(key, {});
    }
    const property = properties.get(key);
    set(property, 'velocity.x', getRandom() * variables.spheres.maxSpeed);
    set(property, 'velocity.y', getRandom() * variables.spheres.maxSpeed);
    set(property, 'velocity.z', getRandom() * variables.spheres.maxSpeed);
    set(property, 'position.x',getRandom()*variables.box.widthFactor*boxWidth);
    set(property, 'position.y',getRandom()*variables.box.heightFactor*boxHeight);
    set(property, 'position.z',getRandom()*variables.box.depth);
    properties.set(key, property);
  }
  return properties
}

function getRandom() {
  return -(Math.random() - 0.5);
}

export {visibleHeightAtZDepth, visibleWidthAtZDepth, getProperties}