// Injects the three-frame "moving static" filters used by .boil, .boil-soft and .ink.
// Each frame is the same displacement with a different noise seed, so a line keeps its
// shape but redraws itself slightly every frame, like hand-inked animation on twos.

const frames = [
  ['boil-a', 3, 0.013, 4.5],
  ['boil-b', 11, 0.013, 4.5],
  ['boil-c', 23, 0.013, 4.5],
  ['boil-sa', 5, 0.035, 2.2],
  ['boil-sb', 17, 0.035, 2.2],
  ['boil-sc', 31, 0.035, 2.2],
];

export function installBoil() {
  const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  svg.setAttribute('width', 0);
  svg.setAttribute('height', 0);
  svg.style.position = 'absolute';
  svg.innerHTML = '<defs>' + frames.map(([id, seed, freq, scale]) => `
    <filter id="${id}" x="-10%" y="-10%" width="120%" height="120%" color-interpolation-filters="sRGB">
      <feTurbulence type="fractalNoise" baseFrequency="${freq}" numOctaves="1" seed="${seed}" result="n"/>
      <feDisplacementMap in="SourceGraphic" in2="n" scale="${scale}" xChannelSelector="R" yChannelSelector="G"/>
    </filter>`).join('') + '</defs>';
  document.body.prepend(svg);
}
