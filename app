import { useState, useCallback } from “react”;

// Data
import { SPECIMENS }          from “./data/specimens.js”;
import { DATA_REGISTRY }      from “./data/registry.js”;
import { BEHAVIORAL_CLASSES } from “./data/behavioralClasses.js”;
import { VALIDATION_RESULTS } from “./data/validation.js”;

// Engine
import { runCadenceModel }    from “./engine/classifier.js”;

// Components
import SandboxPanel           from “./components/SandboxPanel.jsx”;
import ConstraintFramework    from “./components/ConstraintFramework.jsx”;
import TheoryPanel            from “./components/TheoryPanel.jsx”;
import ValidationPanel        from “./components/ValidationPanel.jsx”;
import SpecimenLibrary        from “./components/SpecimenLibrary.jsx”;
import DataSources            from “./components/DataSources.jsx”;
import DiscoveryLog           from “./components/DiscoveryLog.jsx”;

// ─────────────────────────────────────────────────────────────────
// App — thin shell
//
// Owns:
//   activeTab       — which top-level tab is visible
//   sandboxSpecimen — specimen loaded into SandboxPanel
//   userSpecimens   — specimens added via SandboxPanel’s onAddToLibrary
//
// Wiring:
//   SpecimenLibrary.onAnalyse(s)  → loads s into sandbox, switches tab
//   SandboxPanel.onAddToLibrary(s) → appends s to userSpecimens array
//
// All business logic lives in the engine + components.
// This file is navigation and state plumbing only.
// ─────────────────────────────────────────────────────────────────

const TABS = [
{ id: “library”,     label: “SPECIMEN LIBRARY”      },
{ id: “sandbox”,     label: “ANALYSIS SANDBOX”      },
{ id: “framework”,   label: “CONSTRAINT FRAMEWORK”  },
{ id: “theory”,      label: “THEORY & FINDINGS”     },
{ id: “validation”,  label: “VALIDATION”            },
{ id: “sources”,     label: “DATA SOURCES”          },
{ id: “log”,         label: “DISCOVERY LOG”         },
];

const GLOBAL_STYLES = `
@import url(‘https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@300;400;500;600&family=IBM+Plex+Serif:ital,wght@0,300;0,400;1,300&family=Space+Mono:wght@400;700&display=swap’);

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

body { background: #07090F; color: #C8D8E8; }

::-webkit-scrollbar { width: 4px; height: 4px; }
::-webkit-scrollbar-track { background: #0D1117; }
::-webkit-scrollbar-thumb { background: #1E3A4A; border-radius: 2px; }

input, button, select, textarea { font-family: inherit; }

.fade-in {
animation: fadeIn 0.35s ease;
}
@keyframes fadeIn {
from { opacity: 0; transform: translateY(4px); }
to   { opacity: 1; transform: translateY(0); }
}

.pulse-dot {
width: 6px; height: 6px; border-radius: 50%;
background: #5DB8C8;
animation: pulse 1.6s ease-in-out infinite;
}
@keyframes pulse {
0%, 100% { opacity: 1; transform: scale(1); }
50%       { opacity: 0.4; transform: scale(0.7); }
}
`;

function SectionHeader({ label, sub, badge, meta }) {
return (
<div style={{ marginBottom: 8 }}>
<div style={{ display: “flex”, alignItems: “center”, gap: 12, marginBottom: 8 }}>
<div style={{
fontSize: 10, color: “#5DB8C8”,
letterSpacing: “0.2em”, fontWeight: 600,
}}>{label}</div>
{badge && (
<span style={{
fontSize: 8, padding: “2px 7px”,
background: “rgba(93,184,200,0.1)”,
border: “1px solid rgba(93,184,200,0.25)”,
color: “#5DB8C8”, borderRadius: 2,
letterSpacing: “0.1em”,
}}>{badge}</span>
)}
</div>
{sub && (
<p style={{
fontSize: 12, color: “#4A6A7A”,
lineHeight: 1.7, maxWidth: 680,
fontFamily: “‘IBM Plex Serif’, serif”,
}}>{sub}</p>
)}
{meta && (
<div style={{
marginTop: 6, fontSize: 9, color: “#2A4050”,
letterSpacing: “0.1em”,
}}>{meta}</div>
)}
</div>
);
}

export default function App() {
const [activeTab, setActiveTab]           = useState(“library”);
const [sandboxSpecimen, setSandboxSpecimen] = useState(null);
const [userSpecimens, setUserSpecimens]   = useState([]);

// Called by SpecimenLibrary when user clicks ANALYSE on a row
const handleAnalyse = useCallback((specimen) => {
setSandboxSpecimen(specimen);
setActiveTab(“sandbox”);
}, []);

// Called by SandboxPanel when user adds a validated specimen to library
const handleAddToLibrary = useCallback((specimen) => {
setUserSpecimens(prev => {
// Prevent duplicate IDs
if (prev.some(s => s.id === specimen.id)) return prev;
return […prev, specimen];
});
}, []);

const specimenCount = SPECIMENS.length + userSpecimens.length;

return (
<div style={{
fontFamily: “‘IBM Plex Mono’, monospace”,
background: “#07090F”,
color: “#C8D8E8”,
minHeight: “100vh”,
}}>
<style>{GLOBAL_STYLES}</style>

```
  {/* ── HEADER / NAV ── */}
  <header style={{
    borderBottom: "1px solid #0F1E2A",
    position: "sticky", top: 0,
    background: "#07090F", zIndex: 100,
  }}>
    <div style={{
      maxWidth: 1280, margin: "0 auto",
      padding: "0 24px",
      display: "flex", alignItems: "center",
      justifyContent: "space-between",
    }}>
      {/* Logo + nav */}
      <div style={{
        display: "flex", alignItems: "center",
        gap: 24, padding: "12px 0",
      }}>
        <div>
          <div style={{
            fontSize: 13, fontWeight: 700,
            letterSpacing: "0.18em", color: "#8AAABB",
          }}>CETASIGNAL</div>
          <div style={{
            fontSize: 8, color: "#3A5A6A",
            letterSpacing: "0.22em", marginTop: 2,
          }}>MARINE ACOUSTIC BEHAVIORAL RESEARCH · v3.3</div>
        </div>

        <div style={{ width: 1, height: 28, background: "#0F1E2A" }} />

        <nav style={{ display: "flex", gap: 2 }}>
          {TABS.map(({ id, label }) => (
            <button
              key={id}
              onClick={() => setActiveTab(id)}
              style={{
                padding: "8px 14px",
                fontSize: 10, letterSpacing: "0.1em",
                color: activeTab === id ? "#5DB8C8" : "#4A6A7A",
                background: "transparent",
                border: "none",
                borderBottom: `1px solid ${activeTab === id ? "#5DB8C8" : "transparent"}`,
                cursor: "pointer",
                transition: "all 0.15s",
                fontFamily: "'IBM Plex Mono', monospace",
              }}
              onMouseEnter={e => {
                if (activeTab !== id) e.currentTarget.style.color = "#8AAABB";
              }}
              onMouseLeave={e => {
                if (activeTab !== id) e.currentTarget.style.color = "#4A6A7A";
              }}
            >{label}</button>
          ))}
        </nav>
      </div>

      {/* Meta */}
      <div style={{
        fontSize: 9, color: "#2A4050",
        letterSpacing: "0.1em", textAlign: "right",
      }}>
        <div>{specimenCount} specimens · {DATA_REGISTRY.length} sources</div>
        {userSpecimens.length > 0 && (
          <div style={{ color: "#44C88A", marginTop: 2 }}>
            +{userSpecimens.length} user-validated
          </div>
        )}
      </div>
    </div>
  </header>

  {/* ── MAIN CONTENT ── */}
  <main style={{
    maxWidth: 1280, margin: "0 auto",
    padding: "0 24px",
  }}>

    {/* ── SPECIMEN LIBRARY ── */}
    {activeTab === "library" && (
      <div className="fade-in" style={{ paddingTop: 32 }}>
        <SectionHeader
          label="ACOUSTIC SPECIMEN LIBRARY"
          sub="Catalogued cetacean vocalizations with full provenance, behavioral ground-truth records, and acoustic parameter sets ready for cadence analysis."
          badge="OPEN RESEARCH"
          meta={`${specimenCount} specimens · ${DATA_REGISTRY.length} source datasets · 19 species · 11 ocean basins`}
        />
        <SpecimenLibrary
          onAnalyse={handleAnalyse}
          extraSpecimens={userSpecimens}
        />
      </div>
    )}

    {/* ── ANALYSIS SANDBOX ── */}
    {activeTab === "sandbox" && (
      <div className="fade-in" style={{ paddingTop: 32 }}>
        <SectionHeader
          label="ANALYSIS SANDBOX"
          sub="Select a specimen from the library or paste acoustic parameters. The cadence model walks through each physics constraint in real time, generating a behavioral prediction with a full evidence trail."
          badge="LIVE CLASSIFICATION THEATER"
        />
        <SandboxPanel
          initialSpecimen={sandboxSpecimen}
          onAddToLibrary={handleAddToLibrary}
        />
      </div>
    )}

    {/* ── CONSTRAINT FRAMEWORK ── */}
    {activeTab === "framework" && (
      <div className="fade-in" style={{ paddingTop: 32 }}>
        <SectionHeader
          label="CONSTRAINT NAVIGATION FRAMEWORK"
          sub="The theoretical foundation. Acoustic signals in marine mammals are solutions to coordination problems imposed by the physical and biological structure of the ocean. Language does not precede constraint — it emerges from it."
        />
        <ConstraintFramework />
      </div>
    )}

    {/* ── THEORY & FINDINGS ── */}
    {activeTab === "theory" && (
      <div className="fade-in" style={{ paddingTop: 32 }}>
        <SectionHeader
          label="THEORY & DOCUMENTED FINDINGS"
          sub="Core theoretical position, behavioral class deep dives, and the research findings that emerged from building and validating CadenceClassifier across 19 species."
        />
        <TheoryPanel />
      </div>
    )}

    {/* ── VALIDATION ── */}
    {activeTab === "validation" && (
      <div className="fade-in" style={{ paddingTop: 32 }}>
        <SectionHeader
          label="VALIDATION RESULTS"
          sub="Three independent blind tests across 19 species never used in rule design. 5000 specimens. 11 ocean basins. No ML weights, no training loop — physics-derived rules applied cold."
          badge="99.2% · κ=0.988"
          meta="CadenceClassifier v3.0 · p < 0.0001"
        />
        <ValidationPanel />
      </div>
    )}

    {/* ── DATA SOURCES ── */}
    {activeTab === "sources" && (
      <div className="fade-in" style={{ paddingTop: 32 }}>
        <SectionHeader
          label="DATA SOURCES & PROVENANCE"
          sub="Every specimen in this platform is traceable to a publicly archived dataset with full citation metadata, access URL, DOI where available, and annotation methodology."
          badge="FULL CITATION CHAIN"
        />
        <DataSources />
      </div>
    )}

    {/* ── DISCOVERY LOG ── */}
    {activeTab === "log" && (
      <div className="fade-in" style={{ paddingTop: 32 }}>
        <SectionHeader
          label="DISCOVERY LOG"
          sub="Research journal — every fix, finding, and frontier documented in order of discovery. Each entry records the trigger, resolution, scientific implication, and citations."
        />
        <DiscoveryLog />
      </div>
    )}

    <div style={{ height: 80 }} />
  </main>
</div>
```

);
}
