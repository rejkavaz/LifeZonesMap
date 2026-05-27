// Wireframe board — pencil-on-paper sketches of the four key screens
// Before the hi-fi: the structure, in graphite.

function WireframesBoard() {
  return (
    <div style={{ width: 1180, padding: 56, background: '#F4EDDD', color: LZ.ink,
      fontFamily: LZ.font, boxSizing: 'border-box', position: 'relative' }}>
      {/* Faint grid paper bg */}
      <div style={{ position: 'absolute', inset: 0, opacity: 0.45, pointerEvents: 'none',
        backgroundImage: 'linear-gradient(rgba(40,30,15,0.06) 1px, transparent 1px), linear-gradient(90deg, rgba(40,30,15,0.06) 1px, transparent 1px)',
        backgroundSize: '24px 24px',
      }}/>
      <header style={{ position: 'relative', marginBottom: 32, paddingBottom: 16,
        borderBottom: `1px dashed ${LZ.inkSoft}` }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>Pre-Volume · Wireframes</div>
        <h2 style={{ margin: '8px 0 4px', fontSize: 32, fontWeight: 500,
          letterSpacing: '-0.018em' }}>The structure, in graphite.</h2>
        <p style={{ margin: 0, fontSize: 15, color: LZ.inkSoft, maxWidth: 580, lineHeight: 1.55 }}>
          Before any color decisions: the bones of each screen at iPhone scale.
          One pencil weight. No type styling. No icons we haven't earned.
        </p>
      </header>

      <div style={{ position: 'relative', display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)', gap: 28, alignItems: 'start' }}>
        <WirePhone label="Map">
          <WireMap/>
        </WirePhone>
        <WirePhone label="Check-In">
          <WireCheckIn/>
        </WirePhone>
        <WirePhone label="Pulse">
          <WirePulse/>
        </WirePhone>
        <WirePhone label="Onboarding · Welcome">
          <WireOnboard/>
        </WirePhone>
      </div>

      {/* Margin notes */}
      <div style={{ position: 'relative', marginTop: 36, display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)', gap: 28, fontSize: 11.5,
        color: LZ.inkSoft, lineHeight: 1.55, fontFamily: LZ.fontSerif, fontStyle: 'italic' }}>
        <div>1. The radar sits at the top — it <em>is</em> the page. Everything below explains it.</div>
        <div>2. Cards, top to bottom. No tabs, no segmented control. Scroll is the only verb.</div>
        <div>3. Three sections, each separated by a hairline. Chart on its own surface.</div>
        <div>4. The radar pulses. Two lines of copy. One button. That is the whole screen.</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Wire phone — pencil-style frame, 240 × 510
// ─────────────────────────────────────────────────────────────
function WirePhone({ children, label }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      <div style={{
        width: 220, height: 478, borderRadius: 32, position: 'relative',
        border: `1.5px solid ${LZ.ink}`,
        background: '#FBF6E9',
        boxShadow: '2px 2px 0 0 rgba(40,30,15,0.08)',
        overflow: 'hidden',
      }}>
        {/* notch */}
        <div style={{ position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
          width: 64, height: 16, borderRadius: 9,
          border: `1px solid ${LZ.ink}`, background: 'transparent' }}/>
        {/* home line */}
        <div style={{ position: 'absolute', bottom: 8, left: '50%', transform: 'translateX(-50%)',
          width: 80, height: 3, background: LZ.ink, opacity: 0.5, borderRadius: 2 }}/>
        <div style={{ position: 'absolute', top: 32, left: 12, right: 12, bottom: 26 }}>
          {children}
        </div>
      </div>
      <div style={{ marginTop: 14, fontSize: 11, letterSpacing: '0.18em',
        textTransform: 'uppercase', color: LZ.inkMute, fontWeight: 600 }}>{label}</div>
    </div>
  );
}

// Wire primitives — drawn-in-pen, single weight
const wireLine = LZ.ink;
const wireSoft = 'rgba(40,35,32,0.45)';
const wireMute = 'rgba(40,35,32,0.28)';

function Box({ h, label, sub, fill, dashed }) {
  return (
    <div style={{
      height: h, border: `1px ${dashed ? 'dashed' : 'solid'} ${wireLine}`,
      borderRadius: 6, padding: '6px 8px',
      background: fill || 'transparent',
      fontSize: 9, color: wireSoft, display: 'flex',
      flexDirection: 'column', justifyContent: 'space-between',
    }}>
      <span>{label}</span>
      {sub && <span style={{ color: wireMute, fontSize: 8 }}>{sub}</span>}
    </div>
  );
}

function HairLine() {
  return <div style={{ height: 1, background: wireMute }}/>;
}

function Hatch({ h, label }) {
  // Diagonal hatching to indicate "image" or "data area"
  return (
    <div style={{
      height: h, border: `1px solid ${wireLine}`, borderRadius: 6,
      backgroundImage: `repeating-linear-gradient(45deg, ${wireMute} 0, ${wireMute} 1px, transparent 1px, transparent 7px)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontSize: 9, color: wireSoft, position: 'relative',
    }}>
      <span style={{ background: '#FBF6E9', padding: '2px 6px' }}>{label}</span>
    </div>
  );
}

function WireTabs() {
  return (
    <div style={{
      position: 'absolute', bottom: -10, left: 0, right: 0,
      height: 36, borderTop: `1px solid ${wireLine}`,
      display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
    }}>
      {['Map', 'Check In', 'Pulse'].map((t, i) => (
        <div key={t} style={{ display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center', gap: 3,
          fontSize: 8, color: i === 0 ? LZ.ink : wireSoft, fontWeight: i === 0 ? 600 : 400 }}>
          <span style={{ width: 12, height: 12, border: `1px solid ${i === 0 ? LZ.ink : wireSoft}`,
            borderRadius: 3 }}/>
          {t}
        </div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
function WireMap() {
  return (
    <div style={{ position: 'relative', height: '100%', display: 'flex', flexDirection: 'column', gap: 6 }}>
      {/* Nav */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <span style={{ fontSize: 11, fontWeight: 600 }}>Life Zones</span>
        <span style={{ fontSize: 8, color: wireSoft, letterSpacing: '0.08em' }}>WEEK OF MAY 25</span>
      </div>

      {/* Radar */}
      <div style={{ height: 196, border: `1px solid ${wireLine}`, borderRadius: 8, position: 'relative',
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <WireRadar size={180}/>
      </div>

      {/* Zone rows */}
      <div style={{ fontSize: 8, color: wireSoft, letterSpacing: '0.12em', marginTop: 2 }}>BY ZONE</div>
      {Array.from({ length: 7 }).map((_, i) => (
        <div key={i} style={{ display: 'grid', gridTemplateColumns: '8px 1fr 18px', alignItems: 'center',
          gap: 6, padding: '2px 0', borderBottom: i === 6 ? 'none' : `1px solid ${wireMute}` }}>
          <span style={{ width: 5, height: 5, borderRadius: 3, background: wireLine }}/>
          <div style={{ height: 4, border: `1px solid ${wireLine}`, borderRadius: 2,
            background: `linear-gradient(to right, ${wireLine} ${30 + i * 8}%, transparent ${30 + i * 8}%)` }}/>
          <span style={{ fontSize: 8, textAlign: 'right', color: wireSoft }}>x.x</span>
        </div>
      ))}
      <WireTabs/>
    </div>
  );
}

function WireRadar({ size = 180 }) {
  const cx = size / 2, cy = size / 2;
  const R = size * 0.36;
  const N = 7;
  const verts = [], axisVerts = [];
  const offs = [0.7, 0.85, 0.65, 0.78, 0.9, 0.6, 0.82];
  for (let i = 0; i < N; i++) {
    const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
    verts.push([cx + Math.cos(a) * R * offs[i], cy + Math.sin(a) * R * offs[i]]);
    axisVerts.push([cx + Math.cos(a) * R, cy + Math.sin(a) * R]);
  }
  const poly = verts.map(([x, y], i) => `${i ? 'L' : 'M'}${x.toFixed(2)},${y.toFixed(2)}`).join(' ') + ' Z';
  const ring = axisVerts.map((p, i) => `${i ? 'L' : 'M'}${p[0].toFixed(2)},${p[1].toFixed(2)}`).join(' ') + ' Z';
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      {[0.4, 0.7, 1].map((t, i) => (
        <polygon key={i} points={axisVerts.map(([x, y]) => `${cx + (x-cx)*t},${cy + (y-cy)*t}`).join(' ')}
          fill="none" stroke={wireMute} strokeDasharray={i === 2 ? '0' : '2 2'} strokeWidth="0.8"/>
      ))}
      {axisVerts.map(([x, y], i) => (
        <line key={i} x1={cx} y1={cy} x2={x} y2={y} stroke={wireMute} strokeWidth="0.6"/>
      ))}
      <path d={poly} fill="none" stroke={wireLine} strokeWidth="1.2"/>
      {verts.map(([x, y], i) => <circle key={i} cx={x} cy={y} r="2.5" fill={wireLine}/>)}
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
function WireCheckIn() {
  return (
    <div style={{ position: 'relative', height: '100%', display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div>
        <div style={{ fontSize: 8, color: wireSoft, letterSpacing: '0.12em' }}>SUNDAY, MAY 31</div>
        <div style={{ fontSize: 11, fontWeight: 600, marginTop: 2 }}>A quiet half-hour</div>
        <div style={{ marginTop: 4, height: 2, border: `1px solid ${wireLine}`, borderRadius: 2,
          background: `linear-gradient(to right, ${wireLine} 57%, transparent 57%)` }}/>
      </div>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 6, overflow: 'hidden' }}>
        {[0,1,2,3].map((i) => (
          <div key={i} style={{ border: `1px solid ${wireLine}`, borderRadius: 8,
            padding: '6px 8px', display: 'flex', flexDirection: 'column', gap: 4,
            position: 'relative' }}>
            <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: 3, background: wireLine, borderRadius: 2 }}/>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 9, fontWeight: 600 }}>Zone name</span>
              <span style={{ fontSize: 13, fontWeight: 300, color: wireSoft }}>x.x</span>
            </div>
            <div style={{ height: 4, border: `1px solid ${wireLine}`, borderRadius: 2,
              background: `linear-gradient(to right, ${wireLine} ${60 - i*10}%, transparent ${60 - i*10}%)` }}/>
            <div style={{ display: 'flex', gap: 3 }}>
              {[0,1,2,3].map(j => (
                <span key={j} style={{ width: 22, height: 9, borderRadius: 5,
                  border: `1px solid ${j === 0 && i === 0 ? wireLine : wireMute}`,
                  background: j === 0 && i === 0 ? wireLine : 'transparent' }}/>
              ))}
            </div>
          </div>
        ))}
      </div>
      <Box h={26} label="Save this week" fill="rgba(40,35,32,0.12)"/>
      <WireTabs/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
function WirePulse() {
  return (
    <div style={{ position: 'relative', height: '100%', display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div>
        <div style={{ fontSize: 8, color: wireSoft, letterSpacing: '0.12em' }}>PULSE REPORT</div>
        <div style={{ fontSize: 14, fontWeight: 600 }}>May</div>
      </div>
      {/* Stat cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 4 }}>
        {['Avg', 'Most up', 'Steady'].map(l => (
          <Box key={l} h={42} label={l} sub="x.x"/>
        ))}
      </div>
      {/* Chart */}
      <div style={{ border: `1px solid ${wireLine}`, borderRadius: 6, padding: 6,
        height: 92, position: 'relative' }}>
        <div style={{ fontSize: 7.5, color: wireSoft, marginBottom: 2 }}>CHART · 7 LINES</div>
        <svg width="100%" height="68" viewBox="0 0 180 68" preserveAspectRatio="none">
          {[14, 28, 42, 56].map(y => (
            <line key={y} x1="0" y1={y} x2="180" y2={y} stroke={wireMute} strokeDasharray="2 3"/>
          ))}
          {[0,1,2,3,4,5,6].map(s => {
            const d = `M 0 ${20 + s*4} C 60 ${50 - s*4}, 120 ${30 + (s%3)*5}, 180 ${15 + s*3}`;
            return <path key={s} d={d} fill="none" stroke={wireLine} strokeWidth="0.7"/>;
          })}
        </svg>
      </div>
      <Box h={22} label="Insight · positive"/>
      <Box h={22} label="Insight · correlation"/>
      <Hatch h={62} label="Connections graph"/>
      <WireTabs/>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
function WireOnboard() {
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column',
      justifyContent: 'space-between', alignItems: 'center', textAlign: 'center', padding: '20px 8px 6px' }}>
      <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <WireRadar size={120}/>
      </div>
      <div style={{ marginBottom: 12 }}>
        <div style={{ fontSize: 13, fontWeight: 600, marginBottom: 4 }}>Your life, mapped.</div>
        <div style={{ fontSize: 9, color: wireSoft, fontStyle: 'italic',
          fontFamily: LZ.fontSerif, lineHeight: 1.4 }}>
          A quiet weekly check-in.<br/>No streaks. No judgment.
        </div>
      </div>
      <div style={{ width: '100%' }}>
        <Box h={26} label="Get started" fill="rgba(40,35,32,0.18)"/>
      </div>
    </div>
  );
}

Object.assign(window, { WireframesBoard });
