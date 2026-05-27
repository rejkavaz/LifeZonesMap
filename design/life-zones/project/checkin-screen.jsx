// Check-In screen — 7 zone cards, each with slider + tag pills + note
// "Spa menu meets mindfulness journal"

function CheckInScreen() {
  // Demo state — first 4 are filled, others not yet rated
  const rated = { vit: 6.5, work: 8.2, con: 7.0, inn: 5.8 };
  const tags = {
    vit:  ['Slept well', 'Moved', 'Foggy', 'Wired'],
    work: ['In flow', 'Shipped', 'Distracted', 'Stuck'],
    con:  ['Saw friends', 'Called family', 'Lonely', 'Drained'],
    inn:  ['Steady', 'Anxious', 'Curious', 'Tender'],
    cre:  ['Made things', 'Stalled', 'Inspired', 'Quiet'],
    fnd:  ['On top', 'Tidy', 'Behind', 'Worried'],
    gro:  ['Learning', 'Stretching', 'Coasting', 'Drifting'],
  };
  const selected = { vit: 0, work: 1, inn: 2 }; // index of selected tag, if any

  return (
    <Phone label="Check-In">
      {/* Header */}
      <div style={{ padding: '8px 24px 6px' }}>
        <div style={{ fontSize: 11, letterSpacing: '0.22em', textTransform: 'uppercase',
          color: LZ.inkMute, fontWeight: 600 }}>Sunday, May 31</div>
        <div style={{ marginTop: 6, fontSize: 26, fontWeight: 500, color: LZ.ink,
          letterSpacing: '-0.022em', lineHeight: 1.1 }}>
          A quiet half-hour with yourself.
        </div>
        <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ flex: 1, height: 3, background: '#E5DAC0', borderRadius: 2, overflow: 'hidden' }}>
            <div style={{ width: '57%', height: '100%', background: LZ.tealDeep, borderRadius: 2 }}/>
          </div>
          <div style={{ fontSize: 11, color: LZ.inkMute, fontWeight: 600,
            fontVariantNumeric: 'tabular-nums' }}>4 / 7</div>
        </div>
      </div>

      {/* Cards */}
      <div style={{ flex: 1, overflow: 'auto', padding: '14px 18px 130px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {ZONES.map((z, i) => {
            const score = rated[z.key];
            const sel = selected[z.key];
            const open = z.key === 'vit'; // first card has the expanded note as an example
            return (
              <CheckInCard key={z.key} zone={z} score={score} tags={tags[z.key]}
                selectedTag={sel} expandedNote={open}/>
            );
          })}
        </div>
      </div>

      {/* Floating bottom CTA — above tab bar */}
      <div style={{
        position: 'absolute', left: 18, right: 18, bottom: 88, zIndex: 25,
      }}>
        <div style={{
          background: '#C9C0AB', color: LZ.cream,
          padding: '15px 20px', borderRadius: 14,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          opacity: 0.85,
        }}>
          <span style={{ fontSize: 15, fontWeight: 500 }}>Save this week</span>
          <span style={{ fontSize: 11, letterSpacing: '0.06em',
            opacity: 0.85 }}>3 zones to go</span>
        </div>
      </div>

      <TabBar active="check"/>
    </Phone>
  );
}

function CheckInCard({ zone, score, tags, selectedTag, expandedNote }) {
  const filled = score !== undefined;
  const display = filled ? score.toFixed(1) : '—';
  return (
    <div style={{
      background: '#FFFFFF', borderRadius: 16,
      border: `0.5px solid ${LZ.ruleSoft}`,
      boxShadow: '0 1px 2px rgba(40,30,15,0.04)',
      padding: '14px 16px 14px 18px', position: 'relative', overflow: 'hidden',
    }}>
      {/* Left zone bar */}
      <div style={{ position: 'absolute', top: 0, bottom: 0, left: 0, width: 4, background: zone.color }}/>

      {/* Header row */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ color: zone.color }}><ZoneGlyph glyph={zone.glyph} size={18}/></span>
          <span style={{ fontSize: 15, fontWeight: 500, color: LZ.ink, letterSpacing: '-0.005em' }}>
            {zone.name}
          </span>
        </div>
        <div style={{
          fontSize: 30, fontWeight: 300, color: filled ? LZ.ink : LZ.inkMute,
          fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.025em',
          opacity: filled ? 1 : 0.4,
        }}>{display}</div>
      </div>

      {/* Slider */}
      <div style={{ marginTop: 12 }}>
        <Slider zone={zone} value={score ?? null}/>
      </div>

      {/* Tag pills */}
      <div style={{ marginTop: 12, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {tags.map((t, i) => (
          <span key={t} style={{
            fontSize: 11.5, padding: '5px 11px',
            borderRadius: 999,
            background: selectedTag === i ? zone.color + '20' : 'transparent',
            border: `0.5px solid ${selectedTag === i ? zone.color : LZ.rule}`,
            color: selectedTag === i ? zone.color : LZ.inkSoft,
            fontWeight: selectedTag === i ? 600 : 500,
            letterSpacing: '0.01em',
          }}>{t}</span>
        ))}
      </div>

      {/* Note field */}
      {expandedNote ? (
        <div style={{ marginTop: 12, padding: '10px 12px', borderRadius: 10,
          background: LZ.cream, border: `0.5px solid ${LZ.ruleSoft}` }}>
          <div style={{ fontSize: 9, letterSpacing: '0.2em', textTransform: 'uppercase',
            color: LZ.inkMute, fontWeight: 600, marginBottom: 4 }}>Note</div>
          <div style={{ fontSize: 13, color: LZ.inkSoft, lineHeight: 1.5,
            fontFamily: LZ.fontSerif, fontStyle: 'italic' }}>
            Walked twice this week. Sleep was uneven Tuesday—Thursday but came back together by the
            weekend. Need to leave the laptop downstairs.
          </div>
        </div>
      ) : (
        <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', gap: 6,
          fontSize: 12, color: LZ.inkMute, fontWeight: 500 }}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 20l3.5-1 11-11-2.5-2.5-11 11L4 20z"/></svg>
          Add a note
        </div>
      )}
    </div>
  );
}

function Slider({ zone, value }) {
  const v = value ?? 0;
  const pct = (v / 10) * 100;
  const filled = value !== null && value !== undefined;
  return (
    <div style={{ position: 'relative', height: 22, display: 'flex', alignItems: 'center' }}>
      {/* track */}
      <div style={{ position: 'absolute', left: 0, right: 0, height: 6,
        background: '#EFE7D2', borderRadius: 3 }}/>
      {/* fill */}
      {filled && (
        <div style={{ position: 'absolute', left: 0, height: 6,
          width: `calc(${pct}% )`, background: zone.color, borderRadius: 3 }}/>
      )}
      {/* tick marks at 0, 5, 10 */}
      {[0, 0.25, 0.5, 0.75, 1].map((t, i) => (
        <span key={i} style={{
          position: 'absolute', left: `calc(${t * 100}% - 1px)`,
          width: 2, height: 2, borderRadius: 1,
          background: t === 0 || t === 1 ? LZ.inkMute : '#C9BFA6',
          top: '50%', transform: 'translateY(-50%)', opacity: 0.6,
        }}/>
      ))}
      {/* thumb */}
      {filled && (
        <div style={{
          position: 'absolute', left: `calc(${pct}% - 11px)`, top: 0,
          width: 22, height: 22, borderRadius: 999,
          background: '#FFFFFF', border: `1.5px solid ${zone.color}`,
          boxShadow: '0 2px 6px rgba(40,30,15,0.12)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <span style={{ width: 6, height: 6, borderRadius: 3, background: zone.color }}/>
        </div>
      )}
    </div>
  );
}

Object.assign(window, { CheckInScreen });
