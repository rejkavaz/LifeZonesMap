// 4 Onboarding screens — Welcome, Zones, Schedule, First check-in

function OnboardWelcome() {
  return (
    <Phone label="01 — Welcome" bg="#E8E2CE">
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {/* Topo bg */}
        <div style={{ position: 'absolute', inset: 0, opacity: 0.75 }}>
          <TopoTexture width={420} height={900} lines={40}
            palette={['#A9B59A', '#8DA383']} seed={4} opacity={0.85} strokeWidth={1.0}/>
        </div>
        <div style={{ position: 'absolute', inset: 0,
          background: 'radial-gradient(120% 80% at 50% 35%, transparent 55%, rgba(120,90,40,0.18) 100%)' }}/>

        {/* Centered radar / wordmark */}
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
          display: 'flex', flexDirection: 'column', justifyContent: 'center',
          alignItems: 'center', padding: '0 32px' }}>
          <div style={{ filter: 'drop-shadow(0 12px 24px rgba(40,30,15,0.15))', marginTop: -60 }}>
            <AnimatedRadar size={232}/>
          </div>
          <div style={{ marginTop: 28, textAlign: 'center' }}>
            <div style={{ fontSize: 11, letterSpacing: '0.28em', textTransform: 'uppercase',
              color: LZ.inkSoft, fontWeight: 600 }}>Life Zones</div>
            <h1 style={{ margin: '14px 0 10px', fontSize: 34, fontWeight: 500,
              color: LZ.ink, letterSpacing: '-0.022em', lineHeight: 1.05 }}>
              Your life,<br/>mapped.
            </h1>
            <p style={{ margin: 0, fontSize: 15.5, color: LZ.inkSoft, lineHeight: 1.5,
              fontFamily: LZ.fontSerif, fontStyle: 'italic', maxWidth: 280 }}>
              A quiet weekly check-in.<br/>No streaks. No judgment.
            </p>
          </div>
        </div>

        {/* Bottom button */}
        <BottomCTA>Get started</BottomCTA>
      </div>
    </Phone>
  );
}

function OnboardZones() {
  return (
    <Phone label="02 — The Zones" bg={LZ.paper}>
      <div style={{ padding: '30px 28px 14px' }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>Step 2 of 4</div>
        <h1 style={{ margin: '8px 0 6px', fontSize: 28, fontWeight: 500,
          color: LZ.ink, letterSpacing: '-0.022em', lineHeight: 1.15 }}>
          Seven areas.<br/>One picture.
        </h1>
        <p style={{ margin: 0, fontSize: 14, color: LZ.inkSoft, lineHeight: 1.5,
          maxWidth: 280 }}>
          Each week you'll rate these. Over time they sketch the shape of your life.
        </p>
      </div>

      {/* Horizontal scroll of zone cards */}
      <div style={{ marginTop: 18, position: 'relative', flex: 1 }}>
        {/* SVG connection lines behind */}
        <svg width="100%" height="100%" viewBox="0 0 393 540"
          style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
          {/* meandering connectors */}
          <path d="M30 180 C 80 140, 130 230, 190 180 S 290 130, 370 200"
            stroke={LZ.inkMute} strokeOpacity="0.35" strokeWidth="0.8"
            strokeDasharray="2 4" fill="none"/>
          <path d="M50 320 C 110 290, 170 360, 240 320 S 340 280, 380 340"
            stroke={LZ.inkMute} strokeOpacity="0.35" strokeWidth="0.8"
            strokeDasharray="2 4" fill="none"/>
        </svg>

        <div style={{ display: 'flex', gap: 12, padding: '0 24px 8px',
          overflowX: 'auto', WebkitOverflowScrolling: 'touch' }}>
          {ZONES.map((z, i) => (
            <div key={z.key} style={{
              flex: '0 0 auto', width: 138,
              background: '#FFFFFF', borderRadius: 14,
              border: `0.5px solid ${LZ.ruleSoft}`,
              padding: '14px 14px 14px',
              boxShadow: '0 1px 2px rgba(40,30,15,0.04)',
              position: 'relative', overflow: 'hidden',
              marginTop: i % 2 === 0 ? 0 : 22,
            }}>
              <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 3, background: z.color }}/>
              <div style={{ color: z.color, marginBottom: 10 }}>
                <ZoneGlyph glyph={z.glyph} size={22} stroke={1.7}/>
              </div>
              <div style={{ fontSize: 14, fontWeight: 500, color: LZ.ink,
                letterSpacing: '-0.005em', marginBottom: 4 }}>{z.name}</div>
              <div style={{ fontSize: 11, color: LZ.inkSoft, lineHeight: 1.4 }}>{z.blurb}</div>
            </div>
          ))}
          <div style={{ flex: '0 0 4px' }}/>
        </div>

        {/* Page indicator + scroll hint */}
        <div style={{ position: 'absolute', bottom: 12, left: 0, right: 0,
          display: 'flex', justifyContent: 'center', gap: 6 }}>
          {[0,1,2,3,4,5,6].map(i => (
            <span key={i} style={{ width: i === 0 ? 16 : 5, height: 5, borderRadius: 3,
              background: i === 0 ? LZ.tealDeep : '#D8CFBC' }}/>
          ))}
        </div>
      </div>

      <BottomCTA secondary="Skip">Continue</BottomCTA>
    </Phone>
  );
}

function OnboardSchedule() {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const hours = ['5 pm', '6 pm', '7 pm', '8 pm', '9 pm', '10 pm', '11 pm'];
  return (
    <Phone label="03 — Schedule" bg={LZ.paper}>
      <div style={{ padding: '30px 28px 6px' }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>Step 3 of 4</div>
        <h1 style={{ margin: '8px 0 6px', fontSize: 28, fontWeight: 500,
          color: LZ.ink, letterSpacing: '-0.022em', lineHeight: 1.15 }}>
          When should we<br/>remind you?
        </h1>
        <p style={{ margin: 0, fontSize: 14, color: LZ.inkSoft, lineHeight: 1.5,
          maxWidth: 280, fontFamily: LZ.fontSerif, fontStyle: 'italic' }}>
          A Sunday evening ritual. Or whenever works for you.
        </p>
      </div>

      {/* Wheel pickers */}
      <div style={{ marginTop: 24, padding: '0 18px', flex: 1 }}>
        <div style={{ background: LZ.cream, borderRadius: 18,
          border: `0.5px solid ${LZ.ruleSoft}`, overflow: 'hidden',
          position: 'relative' }}>
          {/* Selection band */}
          <div style={{ position: 'absolute', left: 12, right: 12, top: 'calc(50% - 18px)',
            height: 36, borderRadius: 8, background: '#FFFFFF',
            border: `0.5px solid ${LZ.rule}` }}/>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', position: 'relative' }}>
            <Wheel items={days}     selected={6}/>
            <Wheel items={hours}    selected={2}/>
          </div>
        </div>

        {/* Quiet hours note */}
        <div style={{ marginTop: 20, display: 'flex', alignItems: 'flex-start', gap: 10,
          background: LZ.cream, border: `0.5px solid ${LZ.ruleSoft}`, borderRadius: 12,
          padding: '12px 14px' }}>
          <div style={{ color: LZ.tealDeep, marginTop: 1 }}>
            <ZoneGlyph glyph="moon" size={16}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 12.5, color: LZ.ink, fontWeight: 500, marginBottom: 2 }}>
              One gentle nudge. Never more.
            </div>
            <div style={{ fontSize: 11.5, color: LZ.inkSoft, lineHeight: 1.45 }}>
              Skip a week and we'll keep quiet. Skip a month and we'll wait for you.
            </div>
          </div>
        </div>
      </div>

      <BottomCTA secondary="Back">Set reminder</BottomCTA>
    </Phone>
  );
}

function OnboardFirstCheckin() {
  const previewScores = { vit: 5.5, work: 0, con: 0, inn: 0, cre: 0, fnd: 0, gro: 0 };
  return (
    <Phone label="04 — First check-in" bg={LZ.paper}>
      <div style={{ padding: '30px 28px 12px' }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>Step 4 of 4</div>
        <h1 style={{ margin: '8px 0 6px', fontSize: 28, fontWeight: 500,
          color: LZ.ink, letterSpacing: '-0.022em', lineHeight: 1.15 }}>
          Where are you<br/>right now?
        </h1>
        <p style={{ margin: 0, fontSize: 14, color: LZ.inkSoft, lineHeight: 1.5,
          maxWidth: 300, fontFamily: LZ.fontSerif, fontStyle: 'italic' }}>
          Slide each line — gut feel is fine. Five seconds, not five minutes.
        </p>
      </div>

      <div style={{ padding: '8px 22px 110px', flex: 1, overflow: 'auto' }}>
        {ZONES.map((z, i) => {
          const v = previewScores[z.key];
          const set = v > 0;
          return (
            <div key={z.key} style={{
              display: 'grid', gridTemplateColumns: '24px 1fr 42px',
              gap: 12, alignItems: 'center',
              padding: '14px 0', borderBottom: i === ZONES.length - 1 ? 'none'
                : `0.5px solid ${LZ.ruleSoft}`,
            }}>
              <span style={{ color: z.color }}><ZoneGlyph glyph={z.glyph} size={18}/></span>
              <div>
                <div style={{ fontSize: 13.5, color: LZ.ink, fontWeight: 500, marginBottom: 6,
                  letterSpacing: '-0.005em' }}>{z.name}</div>
                <CompactSlider zone={z} value={v}/>
              </div>
              <div style={{ fontSize: 16, fontWeight: 300, textAlign: 'right',
                color: set ? LZ.ink : LZ.inkMute, opacity: set ? 1 : 0.4,
                fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>
                {set ? v.toFixed(1) : '—'}
              </div>
            </div>
          );
        })}
      </div>

      <BottomCTA primary>Begin</BottomCTA>
    </Phone>
  );
}

// ─────────────────────────────────────────────────────────────
function CompactSlider({ zone, value }) {
  const set = value > 0;
  const pct = (value / 10) * 100;
  return (
    <div style={{ position: 'relative', height: 14, display: 'flex', alignItems: 'center' }}>
      <div style={{ position: 'absolute', left: 0, right: 0, height: 4,
        background: '#EFE7D2', borderRadius: 2 }}/>
      {set && (
        <div style={{ position: 'absolute', left: 0, height: 4,
          width: `${pct}%`, background: zone.color, borderRadius: 2 }}/>
      )}
      {set && (
        <div style={{ position: 'absolute', left: `calc(${pct}% - 7px)`,
          width: 14, height: 14, borderRadius: 999,
          background: '#FFFFFF', border: `1.5px solid ${zone.color}` }}/>
      )}
    </div>
  );
}

function Wheel({ items, selected = 0 }) {
  return (
    <div style={{
      padding: '24px 0 24px',
      display: 'flex', flexDirection: 'column', alignItems: 'center',
      maskImage: 'linear-gradient(to bottom, transparent, #000 25%, #000 75%, transparent)',
      WebkitMaskImage: 'linear-gradient(to bottom, transparent, #000 25%, #000 75%, transparent)',
    }}>
      {items.map((it, i) => {
        const dist = Math.abs(i - selected);
        return (
          <div key={i} style={{
            fontSize: dist === 0 ? 19 : 15,
            color: dist === 0 ? LZ.ink : LZ.inkMute,
            fontWeight: dist === 0 ? 600 : 400,
            padding: '5px 0',
            opacity: 1 - dist * 0.22,
            letterSpacing: '-0.005em',
          }}>{it}</div>
        );
      })}
    </div>
  );
}

function BottomCTA({ children, primary = true, secondary }) {
  return (
    <div style={{
      position: 'absolute', bottom: 32, left: 0, right: 0,
      padding: '0 24px', display: 'flex', flexDirection: 'column', gap: 10,
      zIndex: 20,
    }}>
      <button style={{
        height: 52, width: '100%',
        background: LZ.tealDeep, color: LZ.cream,
        border: 'none', borderRadius: 14,
        fontFamily: LZ.font, fontSize: 16, fontWeight: 500,
        letterSpacing: '-0.005em',
        boxShadow: '0 4px 12px rgba(21,121,90,0.22)',
      }}>{children}</button>
      {secondary && (
        <button style={{
          height: 36, background: 'transparent', border: 'none',
          fontFamily: LZ.font, fontSize: 13, fontWeight: 500,
          color: LZ.inkSoft, letterSpacing: '0.01em',
        }}>{secondary}</button>
      )}
    </div>
  );
}

// Animated radar — same SVG as RadarMap but pulsing
function AnimatedRadar({ size = 232 }) {
  const cx = size / 2, cy = size / 2;
  const N = 7;
  const offsets = [0.78, 0.85, 0.72, 0.88, 0.80, 0.92, 0.74];
  const R = size * 0.36;
  const pts = [];
  for (let i = 0; i < N; i++) {
    const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
    pts.push([cx + Math.cos(a) * R * offsets[i], cy + Math.sin(a) * R * offsets[i]]);
  }
  const poly = pts.map(([x, y], i) => `${i ? 'L' : 'M'}${x.toFixed(2)},${y.toFixed(2)}`).join(' ') + ' Z';
  const axisPts = [];
  for (let i = 0; i < N; i++) {
    const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
    axisPts.push([cx + Math.cos(a) * R, cy + Math.sin(a) * R]);
  }
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      {/* Rings */}
      {[0.4, 0.7, 1].map((t, i) => (
        <polygon key={i} points={ZONES.map((_, k) => {
          const a = -Math.PI / 2 + (k / N) * Math.PI * 2;
          return `${cx + Math.cos(a) * R * t},${cy + Math.sin(a) * R * t}`;
        }).join(' ')} fill="none" stroke="#7E8C7A" strokeOpacity="0.4"
          strokeDasharray={i === 2 ? '0' : '3 4'} strokeWidth={i === 2 ? 1 : 0.6}/>
      ))}
      {/* Axis */}
      {axisPts.map(([x, y], i) => (
        <line key={i} x1={cx} y1={cy} x2={x} y2={y} stroke="#7E8C7A" strokeOpacity="0.25" strokeWidth="0.6"/>
      ))}
      {/* Polygon */}
      <path d={poly} fill={LZ.tealDeep} fillOpacity="0.22" stroke={LZ.tealDeep} strokeWidth="1.6">
        <animate attributeName="fill-opacity" values="0.18;0.30;0.18" dur="4s" repeatCount="indefinite"/>
      </path>
      {/* Nodes */}
      {pts.map(([x, y], i) => (
        <circle key={i} cx={x} cy={y} r="4" fill={LZ.tealDeep}/>
      ))}
      {/* Pulsing center */}
      <circle cx={cx} cy={cy} r="3" fill={LZ.tealDeep}>
        <animate attributeName="r" values="3;7;3" dur="3s" repeatCount="indefinite"/>
        <animate attributeName="opacity" values="1;0.2;1" dur="3s" repeatCount="indefinite"/>
      </circle>
    </svg>
  );
}

Object.assign(window, { OnboardWelcome, OnboardZones, OnboardSchedule, OnboardFirstCheckin });
