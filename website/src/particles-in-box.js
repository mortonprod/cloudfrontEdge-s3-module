const Utils = require('./utils');
const variables = require('./variables');

console.debug(`NODE_ENV: ${process.env.NODE_ENV}`);

//Initialize
const utils = Utils(variables);
var animate = function () {
  requestAnimationFrame(animate);
  utils.update();
  
  utils.renderer.render(utils.scene, utils.camera);
};

animate();