// Visual identity board: app icon, wordmark variations, 3 wallpaper variants
// Reference: Field Notes notebooks, Monocle, well-worn maps

function IdentitySheet() {
  return (
    <div style={{
      width: 1180, padding: '56px 64px', background: LZ.paper, color: LZ.ink,
      fontFamily: LZ.font, boxSizing: 'border-box',
    }}>
      {/* Masthead */}
      <header style={{ borderBottom: `1px solid ${LZ.rule}`, paddingBottom: 28, marginBottom: 40,
        display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase', color: LZ.inkMute, marginBottom: 12 }}>
            Volume 01 · Visual Identity · May 2026
          </div>
          <h1 style={{ margin: 0, fontSize: 52, fontWeight: 500, letterSpacing: '-0.02em', lineHeight: 1 }}>
            Life Zones
          </h1>
          <div style={{ marginTop: 10, fontSize: 16, color: LZ.inkSoft, fontStyle: 'italic', fontFamily: LZ.fontSerif }}>
            A quiet weekly map of you.
          </div>
        </div>
        <div style={{ textAlign: 'right', fontSize: 12, color: LZ.inkMute, letterSpacing: '0.04em', lineHeight: 1.6 }}>
          field guide<br/>no. 001<br/>iOS · 26
        </div>
      </header>

      {/* APP ICON */}
      <Section eyebrow="A — App icon" title="The 7-point landmark.">
        <p style={{ ...sheetCopy, maxWidth: 540 }}>
          A seven-sided polygon — half gem, half island silhouette — quietly rotates around a
          surveyor's pin. Deep teal on cream. No gradient, no gloss, no badge.
        </p>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 40, marginTop: 32, alignItems: 'end' }}>
          {/* Large icon */}
          <div>
            <div style={{ filter: 'drop-shadow(0 18px 32px rgba(40,30,15,0.10))' }}>
              <IconMark size={300} color={LZ.tealDeep} bg={LZ.cream} rounded={66}/>
            </div>
            <Caption>1024 × 1024 · App Store</Caption>
          </div>
          {/* Mid */}
          <div>
            <div style={{ filter: 'drop-shadow(0 8px 16px rgba(40,30,15,0.10))' }}>
              <IconMark size={180} color={LZ.tealDeep} bg={LZ.cream} rounded={40}/>
            </div>
            <Caption>180 × 180 · home screen</Caption>
            <div style={{ marginTop: 28, filter: 'drop-shadow(0 4px 8px rgba(40,30,15,0.08))' }}>
              <IconMark size={87} color={LZ.tealDeep} bg={LZ.cream} rounded={20}/>
            </div>
            <Caption>87 × 87 · spotlight</Caption>
          </div>
          {/* Inversions */}
          <div>
            <div style={{ display: 'grid', gap: 18 }}>
              <Tile bg={LZ.tealDeep} label="Inverted">
                <IconMark size={120} color={LZ.cream} bg={LZ.tealDeep} rounded={28}/>
              </Tile>
              <Tile bg={LZ.ink} label="On ink">
                <IconMark size={120} color={LZ.teal} bg={LZ.ink} rounded={28}/>
              </Tile>
            </div>
          </div>
        </div>

        {/* Construction */}
        <div style={{ marginTop: 48, display: 'grid', gridTemplateColumns: '300px 1fr', gap: 40, alignItems: 'center' }}>
          <IconConstruction size={300}/>
          <div style={{ fontSize: 14, color: LZ.inkSoft, lineHeight: 1.7, maxWidth: 460 }}>
            <span style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase', color: LZ.inkMute }}>Geometry</span>
            <div style={{ height: 8 }}/>
            Seven vertices set on a circle at <em style={{ fontFamily: LZ.fontSerif }}>−90°</em> + (i/7) × 360°. Each radius is multiplied
            by a slight irregularity (0.74–1.00) so the shape reads as a real island rather than a
            generic heptagon. The polygon is closed and filled — no outline — at 92% opacity so it
            sits softly against cream.
          </div>
        </div>
      </Section>

      {/* WORDMARK */}
      <Section eyebrow="B — Wordmark" title="Set in Inter Medium.">
        <p style={{ ...sheetCopy, maxWidth: 540 }}>
          Humanist, low-contrast, slightly open. Set tight at −2.2% tracking. No clever ligatures,
          no swash, no &nbsp;<em style={{ fontFamily: LZ.fontSerif }}>app</em>&nbsp; in the name.
        </p>

        <div style={{ marginTop: 28, padding: '44px 48px', background: LZ.cream,
          border: `1px solid ${LZ.rule}`, borderRadius: 4 }}>
          <Wordmark size={64} withMark color={LZ.ink} accent={LZ.tealDeep}/>
        </div>

        <div style={{ marginTop: 24, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18 }}>
          <Tile bg={LZ.paper} label="Wordmark only">
            <Wordmark size={40} color={LZ.ink}/>
          </Tile>
          <Tile bg={LZ.tealDeep} label="Reversed">
            <Wordmark size={40} color={LZ.cream}/>
          </Tile>
          <Tile bg={LZ.ink} label="Ink ground">
            <Wordmark size={40} color={LZ.cream} accent={LZ.teal} withMark/>
          </Tile>
          <Tile bg={LZ.cream} label="Stacked lockup">
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14 }}>
              <IconMark size={64} color={LZ.tealDeep} bg={LZ.cream} rounded={14}/>
              <Wordmark size={26} color={LZ.ink}/>
            </div>
          </Tile>
        </div>

        {/* Type specimens */}
        <div style={{ marginTop: 36, padding: 28, background: LZ.cream, borderRadius: 4,
          border: `1px solid ${LZ.rule}`,
          display: 'grid', gridTemplateColumns: '120px 1fr', rowGap: 16, columnGap: 24, alignItems: 'baseline' }}>
          {[
            ['Display', 500, 56, 'A quiet weekly check-in.'],
            ['Heading', 500, 28, 'Where are you right now?'],
            ['Body', 400, 17, 'Seven small things, taken once a week. No streaks. No judgment.'],
            ['Caption', 500, 12, 'WEEK OF MAY 25 · INTER'],
            ['Numerals', 600, 32, '7.2 · 6.5 · 8.0'],
          ].map(([label, w, sz, txt], i) => (
            <React.Fragment key={i}>
              <div style={{ fontSize: 11, letterSpacing: '0.18em', textTransform: 'uppercase', color: LZ.inkMute }}>
                {label}
              </div>
              <div style={{ fontSize: sz, fontWeight: w, letterSpacing: sz > 30 ? '-0.02em' : 0,
                color: LZ.ink, lineHeight: 1.25,
                fontVariantNumeric: 'tabular-nums' }}>{txt}</div>
            </React.Fragment>
          ))}
        </div>
      </Section>

      {/* COLOR */}
      <Section eyebrow="C — Palette" title="Cream, ink, and seven companions.">
        <p style={{ ...sheetCopy, maxWidth: 540 }}>
          One paper colour. One ink. One brand teal. Seven muted zone colours — each lifted from
          worn cartography, never neon. Use the zone colour at small scale (a 4pt edge, a dot, a
          score) — let the paper carry the page.
        </p>

        <div style={{ marginTop: 28, display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)', gap: 14 }}>
          <Swatch name="Cream"      hex={LZ.cream} ink={LZ.ink}/>
          <Swatch name="Paper"      hex={LZ.paper} ink={LZ.ink}/>
          <Swatch name="Ink"        hex={LZ.ink}   ink={LZ.cream}/>
          <Swatch name="Ink Soft"   hex={LZ.inkSoft} ink={LZ.cream}/>
          <Swatch name="Teal · brand" hex={LZ.tealDeep} ink={LZ.cream} note="#1D9E75"/>
        </div>
        <div style={{ marginTop: 14, display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 10 }}>
          {ZONES.map((z) => (
            <Swatch key={z.key} name={z.name} hex={z.color} ink="#fff" small/>
          ))}
        </div>
      </Section>

      {/* WALLPAPERS */}
      <Section eyebrow="D — Hero wallpapers" title="Three weathered terrains.">
        <p style={{ ...sheetCopy, maxWidth: 540 }}>
          Topographic line drawings, hand-set in deterministic noise. Three moods for the onboarding
          and lock-screen surfaces: <em style={{ fontFamily: LZ.fontSerif }}>Sage Coast</em>,&nbsp;
          <em style={{ fontFamily: LZ.fontSerif }}>Clay Valley</em>, and&nbsp;
          <em style={{ fontFamily: LZ.fontSerif }}>Twilight Ridge</em>.
        </p>

        <div style={{ marginTop: 28, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
          {[
            { name: 'Sage Coast',     bg: '#E8E2CE', topo: ['#A9B59A', '#8DA383'], seed: 4 },
            { name: 'Clay Valley',    bg: '#EDDFC8', topo: ['#C19A6F', '#A8754F'], seed: 9 },
            { name: 'Twilight Ridge', bg: '#2C3741', topo: ['#7D8FA3', '#536376'], seed: 13, dark: true },
          ].map((w) => (
            <div key={w.name}>
              <div style={{
                position: 'relative', aspectRatio: '3 / 5', borderRadius: 22,
                overflow: 'hidden', background: w.bg,
                boxShadow: '0 14px 30px rgba(40,30,15,0.10), inset 0 0 0 1px rgba(40,30,15,0.06)',
              }}>
                <div style={{ position: 'absolute', inset: 0 }}>
                  <TopoTexture width={800} height={1340} lines={36} palette={w.topo} seed={w.seed} opacity={0.85} strokeWidth={1.0}/>
                </div>
                {/* vignette */}
                <div style={{ position: 'absolute', inset: 0,
                  background: w.dark
                    ? 'radial-gradient(120% 80% at 50% 30%, transparent 50%, rgba(0,0,0,0.32) 100%)'
                    : 'radial-gradient(120% 80% at 50% 30%, transparent 60%, rgba(120,90,40,0.18) 100%)' }}/>
                {/* small mark */}
                <div style={{ position: 'absolute', top: 24, left: 24,
                  color: w.dark ? LZ.cream : LZ.ink, opacity: 0.55 }}>
                  <IconMark size={28} color={w.dark ? LZ.cream : LZ.ink} bg="transparent" rounded={6}/>
                </div>
              </div>
              <Caption>{w.name}</Caption>
            </div>
          ))}
        </div>
      </Section>

      {/* Footer */}
      <footer style={{ marginTop: 56, borderTop: `1px solid ${LZ.rule}`, paddingTop: 18,
        display: 'flex', justifyContent: 'space-between', fontSize: 11,
        letterSpacing: '0.18em', textTransform: 'uppercase', color: LZ.inkMute }}>
        <span>Life Zones · Field Guide 001</span>
        <span>Made on paper, displayed on glass.</span>
      </footer>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────
const sheetCopy = {
  fontSize: 16, lineHeight: 1.65, color: LZ.inkSoft,
  marginTop: 4, marginBottom: 0,
};

function Section({ eyebrow, title, children }) {
  return (
    <section style={{ marginTop: 48 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 18, marginBottom: 8 }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase', color: LZ.inkMute }}>
          {eyebrow}
        </div>
        <div style={{ flex: 1, height: 1, background: LZ.rule }}/>
      </div>
      <h2 style={{ margin: 0, fontSize: 32, fontWeight: 500, letterSpacing: '-0.018em', color: LZ.ink }}>{title}</h2>
      {children}
    </section>
  );
}

function Caption({ children }) {
  return (
    <div style={{ marginTop: 10, fontSize: 11, letterSpacing: '0.18em',
      textTransform: 'uppercase', color: LZ.inkMute }}>{children}</div>
  );
}

function Tile({ bg, label, children }) {
  return (
    <div>
      <div style={{
        background: bg, borderRadius: 4, padding: 28,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        minHeight: 140, border: `1px solid ${LZ.rule}`,
      }}>{children}</div>
      <Caption>{label}</Caption>
    </div>
  );
}

function Swatch({ name, hex, ink, note, small }) {
  return (
    <div>
      <div style={{
        background: hex, height: small ? 72 : 110, borderRadius: 4,
        padding: 12, display: 'flex', flexDirection: 'column',
        justifyContent: 'space-between', color: ink,
        border: `1px solid ${LZ.rule}`,
      }}>
        <div style={{ fontSize: 12, fontWeight: 500 }}>{name}</div>
        <div style={{ fontSize: 10, opacity: 0.8, fontFamily: 'ui-monospace, "SF Mono", monospace',
          letterSpacing: '0.04em' }}>{note || hex}</div>
      </div>
    </div>
  );
}

// Construction diagram: shows the 7 vertices on a circle
function IconConstruction({ size = 300 }) {
  const offsets = [0.95, 0.78, 1.0, 0.86, 0.92, 0.74, 1.0];
  const cx = size / 2, cy = size / 2;
  const R = size * 0.34;
  const N = 7;
  const verts = [];
  for (let i = 0; i < N; i++) {
    const a = -Math.PI / 2 + (i / N) * Math.PI * 2;
    verts.push([cx + Math.cos(a) * R * offsets[i], cy + Math.sin(a) * R * offsets[i], a, offsets[i]]);
  }
  const d = verts.map(([x, y], i) => `${i ? 'L' : 'M'}${x.toFixed(2)},${y.toFixed(2)}`).join(' ') + ' Z';
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}
      style={{ background: LZ.cream, borderRadius: 4, border: `1px solid ${LZ.rule}` }}>
      <circle cx={cx} cy={cy} r={R} fill="none" stroke={LZ.tealDeep} strokeOpacity="0.18" strokeDasharray="3 4"/>
      {verts.map(([x, y, a], i) => (
        <line key={i} x1={cx} y1={cy} x2={cx + Math.cos(a) * R} y2={cy + Math.sin(a) * R}
          stroke={LZ.tealDeep} strokeOpacity="0.16" strokeWidth="0.6"/>
      ))}
      <path d={d} fill={LZ.tealDeep} fillOpacity="0.20" stroke={LZ.tealDeep} strokeWidth="1.2"/>
      {verts.map(([x, y, , o], i) => (
        <g key={'v' + i}>
          <circle cx={x} cy={y} r="3.5" fill={LZ.tealDeep}/>
          <text x={x + 10} y={y + 4} fontSize="9" fill={LZ.inkSoft} fontFamily={LZ.font}
            fontVariantNumeric="tabular-nums">{o.toFixed(2)}</text>
        </g>
      ))}
      <circle cx={cx} cy={cy} r="3" fill={LZ.tealDeep}/>
      <text x={cx + 8} y={cy + 4} fontSize="9" fill={LZ.inkSoft} fontFamily={LZ.font}>origin</text>
    </svg>
  );
}

Object.assign(window, { IdentitySheet });
