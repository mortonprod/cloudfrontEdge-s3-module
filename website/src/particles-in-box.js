const {ParticlesInBox} = require('./processes');
const variables = require('./variables');

console.debug(`NODE_ENV: ${process.env.NODE_ENV}`);

//Initialize
const particlesInBox = ParticlesInBox(variables);
var animate = function () {
  requestAnimationFrame(animate);
  particlesInBox.update();
  
  particlesInBox.renderer.render(particlesInBox.scene, particlesInBox.camera);
};

animate();