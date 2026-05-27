// Life Zones — shared tokens and primitives
// Color palette: deep teal + cream + 7 muted zone colors
// Font: Inter (humanist sans-serif)

const LZ = {
  // Surfaces
  cream:      '#F2EBDC',
  creamSoft:  '#EFE7D5',
  paper:      '#FAF6EB',
  ink:        '#262320',
  inkSoft:    '#5B554A',
  inkMute:    '#9A9182',
  rule:       '#D8CFBC',
  ruleSoft:   '#E6DEC9',
  // Brand
  teal:       '#1D9E75',
  tealDeep:   '#15795A',
  // Zone signature colors (muted, earthy)
  zVitality:  '#BE5A45',  // terracotta red
  zDeepWork:  '#3C6E91',  // ink blue
  zConnect:   '#2D9474',  // moss teal (same family as brand)
  zInner:     '#6E5B8A',  // dusky violet
  zCreate:    '#CC8A4A',  // burnt orange
  zFound:     '#B6913E',  // amber ochre
  zGrowth:    '#5E8C5A',  // forest green
  font: '"Inter", ui-sans-serif, system-ui, -apple-system, sans-serif',
  fontSerif: '"Source Serif 4", "Source Serif Pro", Georgia, serif',
};

// Canonical zone order (clockwise from top)
const ZONES = [
  { key: 'vit',  name: 'Vitality',    color: LZ.zVitality, glyph: 'spark',   blurb: 'Body, sleep, energy' },
  { key: 'work', name: 'Deep Work',   color: LZ.zDeepWork, glyph: 'focus',   blurb: 'Focus, craft, output' },
  { key: 'con',  name: 'Connection',  color: LZ.zConnect,  glyph: 'people',  blurb: 'People you love' },
  { key: 'inn',  name: 'Inner World', color: LZ.zInner,    glyph: 'moon',    blurb: 'Mind, mood, meaning' },
  { key: 'cre',  name: 'Creation',    color: LZ.zCreate,   glyph: 'pen',     blurb: 'Make something new' },
  { key: 'fnd',  name: 'Foundation',  color: LZ.zFound,    glyph: 'house',   blurb: 'Money, home, admin' },
  { key: 'gro',  name: 'Growth',      color: LZ.zGrowth,   glyph: 'leaf',    blurb: 'Learn, stretch, change' },
];

// Demo scores for "Week of May 25"
const SCORES = { vit: 6.5, work: 8.2, con: 7.0, inn: 5.8, cre: 7.5, fnd: 8.0, gro: 6.2 };

// ─────────────────────────────────────────────────────────────
// Zone glyph — small line icons drawn in currentColor
// ─────────────────────────────────────────────────────────────
function ZoneGlyph({ glyph, size = 18, stroke = 1.6 }) {
  const s = stroke;
  const props = {
    width: size, height: size, viewBox: '0 0 24 24', fill: 'none',
    stroke: 'currentColor', strokeWidth: s,
    strokeLinecap: 'round', strokeLinejoin: 'round',
  };
  switch (glyph) {
    case 'spark': return (
      <svg {...props}><path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8"/></svg>
    );
    case 'focus': return (
      <svg {...props}><circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="8"/></svg>
    );
    case 'people': return (
      <svg {...props}><circle cx="9" cy="9" r="3"/><circle cx="17" cy="10" r="2.2"/><path d="M3 19c.6-3 3-5 6-5s5.4 2 6 5"/><path d="M15 17.2c.4-1.6 1.8-2.7 3.5-2.7 1.4 0 2.6.7 3 2"/></svg>
    );
    case 'moon': return (
      <svg {...props}><path d="M19 14.5A8 8 0 0 1 9.5 5a7.5 7.5 0 1 0 9.5 9.5z"/></svg>
    );
    case 'pen': return (
      <svg {...props}><path d="M4 20l3.5-1 11-11-2.5-2.5-11 11L4 20z"/><path d="M14.5 7.5l2.5 2.5"/></svg>
    );
    case 'house': return (
      <svg {...props}><path d="M4 11l8-7 8 7"/><path d="M6 10v9h12v-9"/><path d="M10 19v-5h4v5"/></svg>
    );
    case 'leaf': return (
      <svg {...props}><path d="M5 19c0-8 6-14 14-14 0 8-6 14-14 14z"/><path d="M5 19c4-4 8-8 14-14"/></svg>
    );
    default: return <svg {...props}><circle cx="12" cy="12" r="6"/></svg>;
  }
}

// ─────────────────────────────────────────────────────────────
// Radar polygon (7-axis). Used at many sizes.
// ─────────────────────────────────────────────────────────────
function RadarMap({
  size = 320, scores = SCORES, zones = ZONES,
  showNodes = true, showLabels = true, showRings = true,
  showGrid = true, fill = LZ.teal, fillOpacity = 0.14, stroke = LZ.teal,
  ringColor = '#C9C0AB', labelColor = LZ.inkSoft, dotRadius = 5.5,
  scale = 10, // max score
}) {
  const cx = size / 2, cy = size / 2;
  const inset = size * 0.18; // label gutter
  const R = size / 2 - inset;
  const N = zones.length;
  const angle = (i) => -Math.PI / 2 + (i / N) * Math.PI * 2;
  const point = (i, r) => [cx + Math.cos(angle(i)) * r, cy + Math.sin(angle(i)) * r];

  const rings = [0.25, 0.5, 0.75, 1].map((t) => t * R);

  // Score polygon vertices
  const verts = zones.map((z, i) => {
    const v = (scores[z.key] ?? 0) / scale;
    return point(i, R * v);
  });
  const polyPath = verts.map(([x, y], i) => `${i ? 'L' : 'M'}${x.toFixed(2)},${y.toFixed(2)}`).join(' ') + ' Z';

  // Axis lines (faint)
  const axes = zones.map((_, i) => {
    const [x, y] = point(i, R);
    return <line key={i} x1={cx} y1={cy} x2={x} y2={y} stroke={ringColor} strokeWidth="0.6" strokeOpacity="0.55"/>;
  });

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ display: 'block' }}>
      {/* Rings */}
      {showRings && rings.map((r, i) => {
        // 7-sided polygon ring for an unmistakably hand-drawn map feel
        const pts = zones.map((_, k) => {
          const [x, y] = point(k, r);
          return `${x.toFixed(2)},${y.toFixed(2)}`;
        }).join(' ');
        return (
          <polygon key={i} points={pts} fill="none"
            stroke={ringColor} strokeWidth={i === rings.length - 1 ? 0.9 : 0.7}
            strokeDasharray={i === rings.length - 1 ? '0' : '3 4'}
            strokeOpacity={0.55}/>
        );
      })}
      {showGrid && axes}

      {/* Score polygon */}
      <path d={polyPath} fill={fill} fillOpacity={fillOpacity}
        stroke={stroke} strokeWidth="1.4" strokeLinejoin="round"/>

      {/* Nodes */}
      {showNodes && zones.map((z, i) => {
        const [x, y] = verts[i];
        return (
          <g key={z.key}>
            <circle cx={x} cy={y} r={dotRadius + 2} fill={LZ.paper} stroke={z.color} strokeWidth="1.2"/>
            <circle cx={x} cy={y} r={dotRadius - 1} fill={z.color}/>
          </g>
        );
      })}

      {/* Labels — zone name + score */}
      {showLabels && zones.map((z, i) => {
        const [x, y] = point(i, R + inset * 0.62);
        const a = angle(i);
        const isRight = Math.cos(a) > 0.2;
        const isLeft = Math.cos(a) < -0.2;
        const anchor = isRight ? 'start' : isLeft ? 'end' : 'middle';
        return (
          <g key={'l' + z.key} style={{ fontFamily: LZ.font }}>
            <text x={x} y={y - 4} textAnchor={anchor}
              fontSize={size * 0.034} fontWeight="500" fill={LZ.ink}
              letterSpacing="0.01em">{z.name}</text>
            <text x={x} y={y + size * 0.038} textAnchor={anchor}
              fontSize={size * 0.038} fontWeight="600" fill={z.color}
              fontVariantNumeric="tabular-nums">{(scores[z.key] ?? 0).toFixed(1)}</text>
          </g>
        );
      })}
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Topographic line texture — abstract isolines for backgrounds
// ─────────────────────────────────────────────────────────────
function TopoTexture({
  width = 1200, height = 1600, lines = 28, palette = ['#C9BDA0', '#B8AB89'],
  seed = 1, opacity = 0.7, strokeWidth = 1.0,
}) {
  // Deterministic pseudo-random — same seed → same lines
  const rng = (() => { let s = seed * 9301 + 49297;
    return () => { s = (s * 9301 + 49297) % 233280; return s / 233280; }; })();
  const paths = [];
  const cx = width * (0.3 + rng() * 0.4);
  const cy = height * (0.4 + rng() * 0.2);
  for (let i = 0; i < lines; i++) {
    const rx = (i + 4) * (width / (lines * 0.8)) * (0.6 + rng() * 0.3);
    const ry = rx * (0.55 + rng() * 0.25);
    const rot = (rng() - 0.5) * 30;
    const wob = 6 + rng() * 12;
    // Build a wobbly closed loop
    const pts = [];
    const N = 60;
    for (let k = 0; k <= N; k++) {
      const t = (k / N) * Math.PI * 2;
      const r1 = rx + Math.sin(t * 3 + rng() * 2) * wob;
      const r2 = ry + Math.cos(t * 2 + rng() * 2) * wob;
      const x = cx + Math.cos(t) * r1;
      const y = cy + Math.sin(t) * r2;
      pts.push([x, y]);
    }
    const d = pts.map(([x, y], k) => `${k ? 'L' : 'M'}${x.toFixed(1)},${y.toFixed(1)}`).join(' ') + ' Z';
    const color = palette[i % palette.length];
    paths.push(<path key={i} d={d} fill="none" stroke={color}
      strokeWidth={strokeWidth} strokeOpacity={opacity}
      transform={`rotate(${rot} ${cx} ${cy})`}/>);
  }
  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`}
      preserveAspectRatio="xMidYMid slice" style={{ display: 'block' }}>
      {paths}
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// The icon mark — abstract 7-point polygon
// ─────────────────────────────────────────────────────────────
function IconMark({ size = 200, color = LZ.tealDeep, bg = LZ.cream, rounded = 44 }) {
  // Seven points around a circle; slightly irregular for "island" feel
  const offsets = [0.95, 0.78, 1.0, 0.86, 0.92, 0.74, 1.0];
  const cx = size / 2, cy = size / 2;
  const R = size * 0.34;
  const N = 7;
  const pts = [];
  for (let i = 0; i < N; i++) {
    const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
    const r = R * offsets[i];
    pts.push([cx + Math.cos(a) * r, cy + Math.sin(a) * r]);
  }
  const d = pts.map(([x, y], i) => `${i ? 'L' : 'M'}${x.toFixed(2)},${y.toFixed(2)}`).join(' ') + ' Z';
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ display: 'block', borderRadius: rounded }}>
      <rect width={size} height={size} fill={bg} rx={rounded} ry={rounded}/>
      {/* Faint inner ring — survey marker */}
      <circle cx={cx} cy={cy} r={R * 1.05} fill="none" stroke={color} strokeOpacity="0.12" strokeWidth="1"/>
      <path d={d} fill={color} fillOpacity="0.92"/>
      {/* Center survey dot */}
      <circle cx={cx} cy={cy} r="2.4" fill={bg}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Wordmark — "Life Zones" with a small mark dot
// ─────────────────────────────────────────────────────────────
function Wordmark({ size = 44, color = LZ.ink, accent = LZ.tealDeep, withMark = false }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: size * 0.32,
      fontFamily: LZ.font, color,
    }}>
      {withMark && <IconMark size={size * 1.15} color={accent} bg={LZ.cream} rounded={size * 0.26}/>}
      <span style={{
        fontSize: size, fontWeight: 500, letterSpacing: -size * 0.022,
        lineHeight: 1,
      }}>
        Life&nbsp;Zones
      </span>
    </div>
  );
}

Object.assign(window, { LZ, ZONES, SCORES, ZoneGlyph, RadarMap, TopoTexture, IconMark, Wordmark });
